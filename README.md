# secoro-dsl-nvim

Neovim support for the secorolab DSLs.

| filetype | extensions | language |
| --- | --- | --- |
| `robmot` | `.robmot` | motion-spec guarded motions |
| `scenex` | `.scene`, `.scenex`, `.ktree` | scene-dsl scenes, instances and device trees |
| `fsm` | `.fsm` | coord-dsl finite state machines |
| `bdd` | `.bdd`, `.bddx` | robbdd scenarios and their executions |

Each gets a tree-sitter grammar with highlight, indent, fold and locals queries,
a Vim regex syntax as fallback, and a language server: diagnostics, hover,
completion, nested document symbols and goto-definition.

Diagnostics are whatever the DSL toolchain reports. No grammar is vendored here:
the server imports the packages' textX metamodels and hands them the buffer.

## Requirements

- Neovim >= 0.10 (0.11+ uses the native `vim.lsp.config`)
- a C compiler, for the tree-sitter parsers
- Python 3.11+, and `uv` or `venv`

## Installation

```lua
{
  "secorolab/secoro-dsl-nvim",
  ft = { "robmot", "scenex", "fsm", "bdd" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  init = function()
    vim.filetype.add({
      extension = {
        robmot = "robmot",
        scene = "scenex", scenex = "scenex", ktree = "scenex",
        fsm = "fsm",
        bdd = "bdd", bddx = "bdd",
      },
    })
  end,
  config = function()
    require("secoro-dsl-nvim").setup()
  end,
}
```

Nothing needs configuring. The options exist for when something is off:

```lua
require("secoro-dsl-nvim").setup({
  python = nil,            -- interpreter with pygls; auto-detected
  enable_treesitter = true,
  enable_lsp = true,
  lspconfig = {},          -- merged into the server config
})
```

## The language server

On first use the plugin builds `.venv` inside its own directory: `pygls`, plus
the DSL packages from GitHub (`motion-spec-dsl` from `dev`, the rest from
`main`). `:SecoroDslInstallServer` rebuilds it, which is also how to pick up
what has landed on those branches since. `:checkhealth secoro-dsl-nvim` shows
the interpreter, which packages import, and which parsers are compiled.

A language whose package fails to import loses its diagnostics but keeps hover,
completion and symbols.

## Development

```sh
./check.sh          # regenerate every parser, parse every model, compile the queries, test the server
./build-parsers.sh  # install every <language>.so into ~/.local/share/nvim/site/parser
./build.sh          # (re)build the server venv
```

`check.sh` parses `test/coverage.<language>` -- constructs the workspace models
do not use -- plus every model in the sibling checkouts, and fails on an ERROR
node. Pre-rewrite files are deliberately outside the corpus:
`bdd_collab_bhv_cpp/models/collab_pickplace.fsm` and the `motion-spec`
generations tree, both of which the current toolchain rejects too.

Where a package registers several languages whose top-level constructs are
disjoint -- `.scene`/`.scenex`/`.ktree`, `.bdd`/`.bddx` -- they share one grammar
and one filetype. Which metamodel checks a buffer still follows its extension.

Adding a language is an entry in `lua/secoro-dsl-nvim/languages.lua`, a grammar
under `grammars/`, its queries, and a module under `server/languages/`.

## License

MIT
