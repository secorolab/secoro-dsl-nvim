#!/usr/bin/env bash
# Create the plugin-local venv for the language server.
#
# pygls alone gets hover/completion/symbols. Diagnostics additionally need the
# DSL packages: set SECORO_DSL_SRC to the workspace `src` directory (the plugin
# passes it from `setup({ dsl_src = ... })`) and they are installed editable
# from there. A language whose package is missing simply has no diagnostics; the
# others are unaffected.
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$PLUGIN_DIR/.venv"
PYTHON="$VENV/bin/python3"
SRC="${SECORO_DSL_SRC:-}"

# The workspace siblings are not on PyPI and under-declare their dependencies,
# so they go in with --no-deps and the third-party ones are named here. They go
# in as a set: textX loads every registered language's entry point at once, so
# one package whose import fails (robbdd needs bdd_dsl) takes the whole registry
# down with it, and every language loses its diagnostics. This is
# only what importing their metamodels needs: the server parses and validates,
# it never builds a graph, so stock rdflib is enough and the workspace's patched
# fork is not required.
SIBLINGS=(motion-spec-dsl coord-dsl scene-dsl robbdd bdd-dsl rdf-utils)
IMPORT_DEPS=(textx pyshacl rdflib numpy scipy jinja2 platformdirs)

if command -v uv >/dev/null 2>&1; then
    install() { uv pip install --python "$PYTHON" --quiet "$@"; }
    [ -x "$PYTHON" ] || uv venv "$VENV" --quiet
elif command -v python3 >/dev/null 2>&1; then
    install() { "$VENV/bin/pip" install --quiet "$@"; }
    [ -x "$PYTHON" ] || python3 -m venv "$VENV"
else
    echo "secoro-dsl-nvim: python3 not found; the language server is unavailable" >&2
    exit 1
fi

install -r "$PLUGIN_DIR/server/requirements.txt"
echo "secoro-dsl-nvim: pygls installed into $VENV"

if [ -z "$SRC" ] || [ ! -d "$SRC" ]; then
    echo "secoro-dsl-nvim: no DSL source (set SECORO_DSL_SRC or setup({ dsl_src = ... }));" \
         "diagnostics will be disabled"
    exit 0
fi

editable=()
for sibling in "${SIBLINGS[@]}"; do
    [ -d "$SRC/$sibling" ] && editable+=(-e "$SRC/$sibling")
done
if [ ${#editable[@]} -eq 0 ]; then
    echo "secoro-dsl-nvim: no DSL checkouts under $SRC; diagnostics will be disabled"
    exit 0
fi
install --no-deps "${editable[@]}"
install "${IMPORT_DEPS[@]}"

for package in motion_spec_dsl scene_dsl coord_dsl robbdd; do
    if "$PYTHON" -c "import $package" 2>/dev/null; then
        echo "secoro-dsl-nvim: $package installed; diagnostics enabled"
    else
        echo "secoro-dsl-nvim: $package not importable; its diagnostics stay disabled" >&2
    fi
done
