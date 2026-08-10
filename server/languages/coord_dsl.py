"""The coord-dsl coordination language: finite state machines (`.fsm`)."""

from __future__ import annotations

import re
from functools import lru_cache

from lsprotocol import types

NAME = "fsm"
PACKAGE = "coord_dsl"
EXTENSIONS = ("fsm",)


@lru_cache(maxsize=1)
def metamodel(path: str = ""):
    del path
    from coord_dsl.registration import fsm_metamodel

    return fsm_metamodel()


# --------------------------------------------------------------------- symbols

BLOCK_PATTERNS = (
    re.compile(
        r"^\s*(?P<kw>evt loop|fsm|states|transitions|reactions|fires)\b"
        r"(?:\s*\(\s*ns\s*=\s*[\w.-]+\s*\))?"
        r"(?:\s+(?P<name>[A-Za-z_][\w-]*))?"
    ),
    # Transitions and reactions are written name-first, `T_A_B { from: ... }`.
    re.compile(r"^\s*(?P<name>[A-Za-z_][\w-]*)\s*(?=\{)(?P<kw>)"),
)

BLOCK_KIND = {
    "evt loop": types.SymbolKind.Enum,
    "fsm": types.SymbolKind.Class,
    "states": types.SymbolKind.Package,
    "transitions": types.SymbolKind.Package,
    "reactions": types.SymbolKind.Package,
    "fires": types.SymbolKind.Package,
    "": types.SymbolKind.Method,
}


# ----------------------------------------------------------------------- hover

HOVER_DOCS: dict[str, str] = {
    "import": '**import** `"<file>"`\n\nLoads another `.fsm` file so its names resolve here.',
    "ns": '**ns** `<prefix> = "<uri>"`\n\nBinds a namespace prefix to a URI.',
    "evt": "**evt loop** `(ns=<prefix>) <name> { evt <E_A>, evt <E_B> }`\n\nThe events the FSM listens to. Inside the FSM, `evt loop: <loop>` names the one it runs on; `evt <name>` declares a single event.",
    "loop": "**evt loop** `(ns=<prefix>) <name> { evt ... }`\n\nA named set of events.",
    "fsm": "**fsm** `(ns=<prefix>) <name> { [description], states, evt loop, start, end, transitions, reactions }`",
    "description": '**description** `: "<text>"`\n\nWhat this machine coordinates.',
    "states": "**states** `{ S_A, S_B, ... }`\n\nThe states, named once here and referenced as `<S_A>` everywhere else.",
    "start": "**start** `: <state>`\n\nThe state the machine begins in.",
    "end": "**end** `: <state>`\n\nThe state that ends the run.",
    "transitions": "**transitions** `{ T_A_B { from: <S_A>, to: <S_B> }, ... }`\n\nWhich state moves where. A transition names a possible move, not when it happens -- that is a reaction's business.",
    "from": "**from** `: <state>`\n\nThe state this transition leaves.",
    "to": "**to** `: <state>`\n\nThe state this transition enters.",
    "reactions": "**reactions** `{ R_X { when: <event>, do: <transition>, [fires { <event>, ... }] }, ... }`\n\nWhat the machine does when an event arrives.",
    "when": "**when** `: <event>`\n\nThe event this reaction answers, written `<loop.EVENT>` when the loop is named.",
    "do": "**do** `: <transition>`\n\nThe transition this reaction takes.",
    "fires": "**fires** `{ <event>, ... }`\n\nEvents raised as the reaction runs, so one reaction can drive the next.",
}


# ------------------------------------------------------------------ completion

# fmt: off
KEYWORDS = [
    "import", "ns", "evt", "loop", "fsm", "description", "states", "start", "end",
    "transitions", "reactions", "from", "to", "when", "do", "fires"
]
# fmt: on
