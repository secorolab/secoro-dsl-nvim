#!/usr/bin/env bash
# Generate every parser from its grammar and compile it into Neovim's parser
# directory. The plugin does this itself on first use; this is for doing it
# without starting an editor.
set -e
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
mkdir -p "$PARSER_DIR"
for grammar in "$PLUGIN_DIR"/grammars/*/; do
    name="$(basename "$grammar")"
    (cd "$grammar" && tree-sitter generate)
    gcc -O2 -shared -fPIC \
        -o "$PARSER_DIR/$name.so" \
        "$grammar/src/parser.c" \
        -I "$grammar/src/"
    echo "secoro-dsl-nvim: $name parser installed to $PARSER_DIR/$name.so"
done
