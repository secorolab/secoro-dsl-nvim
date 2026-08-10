#!/usr/bin/env python3
"""Language server for the secorolab DSLs: .robmot, .scene/.scenex/.ktree, .fsm.

One server for the family, because one model spans it: a `.robmot` imports the
`.scenex` it runs in and the `.fsm` it is coordinated by. Everything specific to
a language lives in `languages/<name>.py` -- its metamodel factory, the blocks
its outline shows, and what hover and completion offer. This file is only the
plumbing they share.

Diagnostics come from the installed DSL packages: their textX metamodels are the
single source of truth, so nothing about any grammar is duplicated here. A
language whose package is missing still gets hover, completion, symbols and
definitions, and the log says which.
"""

from __future__ import annotations

import logging
import re
import sys
import threading
from urllib.parse import unquote, urlparse

from lsprotocol import types
from pygls.lsp.server import LanguageServer

import languages

logger = logging.getLogger(__name__)

DEBOUNCE_SECONDS = 0.4

server = LanguageServer("secoro-dsl-ls", "v0.1.0")

_metamodel_errors: dict[str, str] = {}
_debounce: dict[str, threading.Timer] = {}


def _uri_to_path(uri: str) -> str:
    parsed = urlparse(uri)
    return unquote(parsed.path) if parsed.scheme == "file" else uri


def _language(path: str):
    """The language module for this file, by extension."""
    return languages.for_path(path)


def _metamodel(path: str):
    """The metamodel checking this file, built once per language and kept.

    Keeping it is safe: textX gives each `model_from_str` its own model
    repository, so an imported file is re-read on every run rather than
    remembered as it was when first seen.
    """
    language = _language(path)
    if language is None or language.NAME in _metamodel_errors:
        return None
    try:
        return language.metamodel(path)
    except ImportError as exc:
        _metamodel_errors[language.NAME] = (
            f"{language.PACKAGE} is not importable ({exc}); diagnostics are disabled for "
            f"{language.NAME}. Point the plugin at a python that has it installed "
            "alongside pygls."
        )
        logger.warning(_metamodel_errors[language.NAME])
    except Exception as exc:  # grammar/metamodel build failure
        _metamodel_errors[language.NAME] = f"failed to build the {language.NAME} metamodel: {exc}"
        logger.error(_metamodel_errors[language.NAME])
    return None


def _diagnostics(uri: str, source: str) -> list[types.Diagnostic]:
    path = _uri_to_path(uri)
    metamodel = _metamodel(path)
    if metamodel is None:
        return []

    try:
        metamodel.model_from_str(source, file_name=path)
    except Exception as exc:
        return [_as_diagnostic(exc, path)]
    return []


def _as_diagnostic(exc: Exception, path: str) -> types.Diagnostic:
    line = getattr(exc, "line", None) or 1
    col = getattr(exc, "col", None) or 1
    origin = getattr(exc, "filename", None)
    # textX stringifies as "<file>:<line>:<col>: message"; the position is already
    # in the diagnostic range, so drop it from the text.
    message = re.sub(r"^\s*\S*?:?\d+:\d+:\s*", "", str(exc))
    message = re.sub(r"^\s*\(?line \d+, col \d+\)?:?\s*", "", message)

    # An error raised while loading an imported model has a position in that
    # file, not in this buffer: pin it to line 1 and say where.
    if origin and origin != path:
        message = f"{origin}:{line}:{col}: {message}"
        line, col = 1, 1

    return types.Diagnostic(
        range=types.Range(
            start=types.Position(line=line - 1, character=col - 1),
            end=types.Position(line=line - 1, character=col),
        ),
        message=message,
        severity=types.DiagnosticSeverity.Error,
        source="secoro-dsl-ls",
    )


def _publish(ls: LanguageServer, uri: str) -> None:
    doc = ls.workspace.get_text_document(uri)
    ls.text_document_publish_diagnostics(
        types.PublishDiagnosticsParams(uri=uri, diagnostics=_diagnostics(uri, doc.source))
    )


def _publish_debounced(ls: LanguageServer, uri: str) -> None:
    timer = _debounce.pop(uri, None)
    if timer is not None:
        timer.cancel()
    timer = threading.Timer(DEBOUNCE_SECONDS, _publish, args=(ls, uri))
    timer.daemon = True
    _debounce[uri] = timer
    timer.start()


@server.feature(types.TEXT_DOCUMENT_DID_OPEN)
def did_open(ls: LanguageServer, params: types.DidOpenTextDocumentParams) -> None:
    _publish(ls, params.text_document.uri)


@server.feature(types.TEXT_DOCUMENT_DID_CHANGE)
def did_change(ls: LanguageServer, params: types.DidChangeTextDocumentParams) -> None:
    _publish_debounced(ls, params.text_document.uri)


@server.feature(types.TEXT_DOCUMENT_DID_SAVE)
def did_save(ls: LanguageServer, params: types.DidSaveTextDocumentParams) -> None:
    _publish(ls, params.text_document.uri)


# --------------------------------------------------------------------- symbols


def blocks(source: str, patterns):
    """Yield (keyword, name, start_line, end_line, depth) for every named block,
    outermost first, in source order.

    The outline nests, since a `.ktree` runs to hundreds of lines and a motion
    holds its sections: every block that names something is a symbol under the
    block holding it.
    """
    depth = 0
    stack: list[tuple[str, str, int, int]] = []
    found = []
    for number, line in enumerate(source.splitlines()):
        code = line.split("//", 1)[0]
        match = next(filter(None, (pattern.match(code) for pattern in patterns)), None)
        opens, closes = code.count("{"), code.count("}")

        # A block is at the depth of the line introducing it: the introducer
        # comes before any brace on that line, since the patterns are anchored.
        # `frame: <f>` and `hold: <m>` are field keys spelled like block
        # openers, so a match only counts where a block actually opens -- or on
        # a declaration written without one, `ktree inst ... of <t>`.
        if match:
            groups = match.groupdict()
            keyword = groups.get("kw") or ""
            name = groups.get("name") or keyword
            if opens > closes:
                stack.append((keyword, name, number, depth))
            elif opens or groups.get("bare"):
                # A one-line block, or a declaration with no block at all.
                found.append((keyword, name, number, number, depth))

        depth += opens - closes
        while stack and depth <= stack[-1][3]:
            keyword, name, start, level = stack.pop()
            found.append((keyword, name, start, number, level))

    last = max(len(source.splitlines()) - 1, 0)
    while stack:
        keyword, name, start, level = stack.pop()
        found.append((keyword, name, start, last, level))

    return sorted(found, key=lambda block: (block[2], block[4]))


@server.feature(types.TEXT_DOCUMENT_DOCUMENT_SYMBOL)
def document_symbol(
    ls: LanguageServer, params: types.DocumentSymbolParams
) -> list[types.DocumentSymbol]:
    doc = ls.workspace.get_text_document(params.text_document.uri)
    language = _language(_uri_to_path(params.text_document.uri))
    if language is None:
        return []

    roots: list[types.DocumentSymbol] = []
    open_blocks: list[tuple[int, types.DocumentSymbol]] = []

    for keyword, name, start, end, depth in blocks(doc.source, language.BLOCK_PATTERNS):
        span = types.Range(
            start=types.Position(line=start, character=0),
            end=types.Position(line=end, character=0),
        )
        symbol = types.DocumentSymbol(
            name=name,
            detail=keyword,
            kind=language.BLOCK_KIND.get(keyword, types.SymbolKind.Struct),
            range=span,
            selection_range=types.Range(start=span.start, end=span.start),
            children=[],
        )
        while open_blocks and open_blocks[-1][0] >= depth:
            open_blocks.pop()
        if open_blocks:
            open_blocks[-1][1].children.append(symbol)
        else:
            roots.append(symbol)
        open_blocks.append((depth, symbol))

    return roots


# ------------------------------------------------------------------ definition

_WORD_RE = re.compile(r"[A-Za-z0-9_-]")


def word_at(source: str, line: int, character: int) -> str:
    lines = source.splitlines()
    if line >= len(lines):
        return ""
    text = lines[line]
    if character >= len(text):
        character = max(0, len(text) - 1)
    start = end = character
    while start > 0 and _WORD_RE.match(text[start - 1]):
        start -= 1
    while end < len(text) and _WORD_RE.match(text[end]):
        end += 1
    return text[start:end]


def find_declaration(source: str, word: str) -> tuple[int, int] | None:
    """Line and column of `word` where it is declared: after whatever states its
    kind (`body base_link {`, `guarded-motion (ns=app) home {`, `evt E_STEP,`),
    or before the colon that names a constraint (`hold-x: keeping ...`).
    """
    declaration = re.compile(
        rf"^\s*(?:[\w@./()=<>-]+\s+)*{re.escape(word)}\s*(?=[:={{,]|of\b|as\b|$)"
    )
    for number, line in enumerate(source.splitlines()):
        match = declaration.match(line.split("//", 1)[0])
        if match:
            return number, match.group(0).rindex(word)
    return None


@server.feature(types.TEXT_DOCUMENT_DEFINITION)
def definition(ls: LanguageServer, params: types.DefinitionParams) -> types.Location | None:
    doc = ls.workspace.get_text_document(params.text_document.uri)
    word = word_at(doc.source, params.position.line, params.position.character)
    if not word:
        return None
    found = find_declaration(doc.source, word)
    if found is None:
        return None
    line, column = found
    return types.Location(
        uri=params.text_document.uri,
        range=types.Range(
            start=types.Position(line=line, character=column),
            end=types.Position(line=line, character=column + len(word)),
        ),
    )


# ----------------------------------------------------------------------- hover


@server.feature(types.TEXT_DOCUMENT_HOVER, types.HoverOptions())
def hover(ls: LanguageServer, params: types.HoverParams) -> types.Hover | None:
    doc = ls.workspace.get_text_document(params.text_document.uri)
    language = _language(_uri_to_path(params.text_document.uri))
    if language is None:
        return None
    word = word_at(doc.source, params.position.line, params.position.character)
    info = language.HOVER_DOCS.get(word)
    if info is None:
        return None
    return types.Hover(contents=types.MarkupContent(kind=types.MarkupKind.Markdown, value=info))


# ------------------------------------------------------------------ completion


def completions(language) -> list[types.CompletionItem]:
    """The items a language offers, built once from the plain data it declares."""
    cached = getattr(language, "_completion_items", None)
    if cached is not None:
        return cached

    items = [
        types.CompletionItem(
            label=word,
            kind=types.CompletionItemKind.Keyword,
            detail=language.HOVER_DOCS.get(word, f"{language.NAME} keyword").split("\n")[0],
        )
        for word in language.KEYWORDS
    ]
    items += [
        types.CompletionItem(
            label=word,
            kind=types.CompletionItemKind.TypeParameter,
            detail="quantity type",
        )
        for word in getattr(language, "TYPES", ())
    ]
    items += [
        types.CompletionItem(label=unit, kind=types.CompletionItemKind.Unit, detail="unit")
        for unit in getattr(language, "UNITS", ())
    ]
    language._completion_items = items
    return items


@server.feature(
    types.TEXT_DOCUMENT_COMPLETION,
    types.CompletionOptions(trigger_characters=[" ", ":", "{", "[", "<", ".", "\n"]),
)
def completion(ls: LanguageServer, params: types.CompletionParams) -> types.CompletionList:
    del ls
    language = _language(_uri_to_path(params.text_document.uri))
    if language is None:
        return types.CompletionList(is_incomplete=False, items=[])
    return types.CompletionList(is_incomplete=False, items=completions(language))


def main() -> None:
    logging.basicConfig(
        level=logging.WARNING, stream=sys.stderr, format="%(levelname)s %(name)s: %(message)s"
    )
    server.start_io()


if __name__ == "__main__":
    main()
