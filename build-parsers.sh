#!/usr/bin/env bash
# Compile every grammar into Neovim's parser directory.
set -e
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
mkdir -p "$PARSER_DIR"
for grammar in "$PLUGIN_DIR"/grammars/*/; do
    name="$(basename "$grammar")"
    gcc -O2 -shared -fPIC \
        -o "$PARSER_DIR/$name.so" \
        "$grammar/src/parser.c" \
        -I "$grammar/src/"
    echo "secoro-dsl-nvim: $name parser installed to $PARSER_DIR/$name.so"
done
