#!/usr/bin/env bash
# Regenerate every parser, parse every model we can find, compile the queries,
# and run the language-server self-check.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Where each language's models live. `collab_pickplace.fsm` is deliberately not
# here: it is the pre-rewrite uppercase syntax, which the current coord-dsl
# rejects too.
CORPUS_ROOTS=(
    ../motion-spec-dsl/models ../motion-spec-dsl/tests/fixtures
    ../bdd_collab_bhv_cpp/models ../scene-dsl/examples ../robbdd/examples
    ../coord-dsl/examples
)

declare -A PATTERNS=(
    [robmot]="-name *.robmot"
    [scenex]="-name *.scene -o -name *.scenex -o -name *.ktree"
    [fsm]="-path */models/*/*.fsm -o -path */examples/models/*/*.fsm"
)

status=0
for grammar in grammars/*/; do
    name="$(basename "$grammar")"
    echo "== $name: generate"
    (cd "$grammar" && tree-sitter generate)

    echo "== $name: parse"
    corpus=()
    [ -f "test/coverage.$name" ] && corpus+=("test/coverage.$name")
    while IFS= read -r file; do corpus+=("$file"); done < <(
        # shellcheck disable=SC2086
        find "${CORPUS_ROOTS[@]}" \( ${PATTERNS[$name]} \) 2>/dev/null || true
    )
    for file in "${corpus[@]}"; do
        if (cd "$grammar" && tree-sitter parse -q "$OLDPWD/$file") >/dev/null 2>&1; then
            echo "ok   $file"
        else
            echo "FAIL $file"
            (cd "$grammar" && tree-sitter parse "$OLDPWD/$file") | grep -n -E 'ERROR|MISSING' | head -5
            status=1
        fi
    done

    echo "== $name: queries"
    for query in "queries/$name"/*.scm; do
        (cd "$grammar" && tree-sitter query "$OLDPWD/$query" "$OLDPWD/test/coverage.$name") >/dev/null
        echo "ok   $query"
    done
done

echo "== server"
python=".venv/bin/python3"
[ -x "$python" ] || python="python3"
"$python" test/test_server.py

exit $status
