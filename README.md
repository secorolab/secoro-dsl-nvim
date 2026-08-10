# secoro-dsl-nvim

Neovim support for the secorolab DSL family:

| filetype | extensions | language |
| --- | --- | --- |
| `robmot` | `.robmot` | motion-spec guarded motions |
| `scenex` | `.scene`, `.scenex`, `.ktree` | scene-dsl scenes, instances and device trees |
| `fsm` | `.fsm` | coord-dsl finite state machines |

One plugin, because one model spans all three: a `.robmot` imports the `.scenex`
it runs in and the `.fsm` it is coordinated by. They share a venv, a language
server process, and the build and health machinery; what differs is one grammar,
one query set and one server module each.

- tree-sitter grammars with highlight, indent, fold and locals queries
- Vim regex syntax as a fallback when a parser is not compiled
- language server: diagnostics, hover, completion, nested document symbols,
  goto-definition

The `.scene`, `.scenex` and `.ktree` extensions share one grammar: their
top-level constructs are disjoint, so a single parser reads each without ever
accepting the other's. Which language a buffer is *checked* against still
follows its extension, the way the toolchain reads it.

The tree-sitter grammars track the textX grammars in `motion_spec_dsl/grammars`,
`scene_dsl/grammars` and `coord_dsl/metamodels`. The language server does not
vendor a grammar copy at all: it builds each metamodel from the installed
package, so diagnostics are exactly what the DSL toolchain reports.

## Requirements

- Neovim >= 0.10 (0.11+ uses the native `vim.lsp.config`)
- a C compiler, for the tree-sitter parsers
- Python 3.11+ and `uv` (or plain `venv`); the server venv is built on first use
- for diagnostics: the DSL checkouts, see below

## Installation

```lua
{
  "vamsikalagaturu/secoro-dsl-nvim",
  ft = { "robmot", "scenex", "fsm" },
  init = function()
    vim.filetype.add({
      extension = {
        robmot = "robmot",
        scene = "scenex", scenex = "scenex", ktree = "scenex",
        fsm = "fsm",
      },
    })
  end,
  config = function()
    require("secoro-dsl-nvim").setup({
      -- workspace `src` directory; the DSL packages are installed editable from here
      dsl_src = "~/work/ms/src",
    })
  end,
}
```

Defaults:

```lua
require("secoro-dsl-nvim").setup({
  dsl_src = nil,           -- auto-detected, see below
  python = nil,            -- auto-detected, see below
  enable_treesitter = true,
  enable_lsp = true,
  lspconfig = {},          -- merged into the server config
})
```

## The server venv

On first use the plugin runs `build.sh`, which creates `.venv` inside the plugin
directory with `pygls`. If `dsl_src` resolves to a directory holding the DSL
checkouts, it also installs `motion-spec-dsl`, `coord-dsl`, `scene-dsl` and
`rdf-utils` editable from there (with `--no-deps`, since the workspace siblings
are not on PyPI and under-declare their dependencies) plus the handful of
third-party packages their imports need. `dsl_src` defaults to the parent of the
nearest DSL checkout above the current directory.

A language whose package is missing simply has no diagnostics; the others are
unaffected, and `:checkhealth secoro-dsl-nvim` says which is which.

Only imports are involved: the server parses and validates, it never builds an
RDF graph, so stock `rdflib` is enough and the workspace's patched fork is not
required.

Re-run it any time with `:SecoroDslInstallServer`.

Interpreter search order: `python` from setup, `$VIRTUAL_ENV`, the nearest
`.venv` above the current directory, the plugin venv, then `python3`. The one
that imports `pygls` plus the most DSL packages wins.

## Diagnostics

Errors are the real ones the metamodels report -- syntax errors, unresolved
references, unit-kind mismatches, duplicate IRIs, tree topology, model mappings:

```
90:68  Unknown object "shared.spec.nope" of class "ContextQuantity"
56:9   'force-threshold' is a Force quantity: 'm' is not one of its units (N).
14:5   kinematic tree 'kinova_tree' has 2 bodies attached to nothing (base_link, tool),
       but a tree has one root -- join them, or hold them in a kgraph
```

An error raised while loading an imported model is reported on line 1 with its
source file named. Each metamodel is built once and kept: textX gives every
parse its own model repository, so an edited import is re-read on the next run
rather than remembered as first seen.

## Colours

One role per capture, so a token's colour says what it does rather than where it
sits. The scheme is the same in all three languages:

| capture | role |
| --- | --- |
| `@keyword` | top-level introducers, `import`, `ns` |
| `@label` | slot names: sub-block openers and field keys (`while`, `wrt`, `from`, `Kp`) |
| `@keyword.operator` | words relating two things (`equal to`, `snapshot`, `map`, `of`) |
| `@type` | the kind of thing being declared (`pose`, `body`, `pid`, `evt`) |
| `@constant` | literal values: numbers, units, closed-vocabulary words (`achd`, `rgbd`) |
| `@variable` | every name this file declares |
| `@variable.member` | every reference to one, inside `<>` or `[]` |
| `@variable.parameter` | the selector slicing a reference (`.linvel.z`, `.z`) |
| `@module` | namespace prefixes |

The regex fallbacks link to the same captures, so both paths render identically.

## Symbols

The outline nests: every block that names something is a symbol under the block
holding it. A `.ktree` lists its bodies, each body its frames, each frame its
poses; a `.robmot` lists its motions, each motion its `when`/`while`/`until`
sections and each handler its monitors, controllers and solvers; a `.fsm` lists
its states, transitions and reactions.

## Development

```sh
./check.sh          # regenerate every parser, parse every model, compile the queries, test the server
./build-parsers.sh  # install robmot.so, scenex.so and fsm.so into ~/.local/share/nvim/site/parser
SECORO_DSL_SRC=~/work/ms/src ./build.sh   # (re)build the server venv
```

`check.sh` parses `test/coverage.<language>` (constructs the workspace models do
not use) plus every model under the sibling checkouts, and fails if any produces
an ERROR node. Two files are deliberately outside the corpus --
`bdd_collab_bhv_cpp/models/collab_pickplace.fsm` and the `motion-spec`
generations tree -- because they are pre-rewrite syntax the current toolchain
rejects too.

Adding a language is an entry in `lua/secoro-dsl-nvim/languages.lua`, a grammar
under `grammars/`, its queries, and a module under `server/languages/`.

### Grammar size

The robmot parse table sits near tree-sitter's 65535-action ABI limit. If
`tree-sitter generate` reports `Parse table action count ... exceeds maximum`,
look for a chain of `optional(...)` sections: turning one into
`repeat(choice(...))` costs one state per section instead of one per combination
of the sections before it. That is what the `ros` block does, and it is why
`subscribers` fits.

## License

MIT
