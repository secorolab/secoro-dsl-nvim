#!/usr/bin/env bash
# Create the plugin-local venv for the language server.
#
# pygls alone gets hover, completion and symbols. Diagnostics need the DSL
# packages, which are installed from GitHub: the server imports their textX
# metamodels, so what it reports is what the toolchain reports.
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$PLUGIN_DIR/.venv"
PYTHON="$VENV/bin/python3"

# owner/repo@ref. motion-spec-dsl is developed on `dev`; the others on `main`.
SOURCES=(
    secorolab/motion-spec-dsl@dev
    secorolab/coord-dsl@main
    secorolab/scene-dsl@main
    minhnh/robbdd@main
    minhnh/bdd-dsl@main
    minhnh/rdf-utils@main
)

# They go in with --no-deps, since they depend on each other and none of them is
# on PyPI, and the third-party ones are named here. This is only what importing
# their metamodels needs: the server parses and validates, it never builds a
# graph, so stock rdflib is enough.
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

# Reinstalled every run: the sources are branches, so this is also the way to
# pick up what has landed on them since.
install --no-deps --reinstall "${SOURCES[@]/#/git+https://github.com/}"
install "${IMPORT_DEPS[@]}"

# textX loads every registered language's entry point at once, so one package
# that fails to import takes the whole registry with it -- and then no language
# resolves a cross-file reference. Say which one, rather than let a `.scenex`
# report its imported `.scene` as a syntax error.
status=0
for package in motion_spec_dsl scene_dsl coord_dsl robbdd; do
    if "$PYTHON" -c "import $package" 2>/dev/null; then
        echo "secoro-dsl-nvim: $package installed; diagnostics enabled"
    else
        echo "secoro-dsl-nvim: $package is not importable; diagnostics are disabled" >&2
        status=1
    fi
done
exit $status
