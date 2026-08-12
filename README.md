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
- the [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter) and a C
  compiler, to build the parsers -- `:MasonInstall tree-sitter-cli`, or `cargo`
  or `npm` install it. Without them the regex syntax highlights instead, and
  `:SecoroDslBuildParsers` retries once they are there.
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

On first use the plugin generates each parser from its grammar and compiles it
-- about a second in total, once -- and builds `.venv` inside its own directory: `pygls`, plus
the DSL packages from GitHub (`motion-spec-dsl` from `dev`, the rest from
`main`). `:SecoroDslInstallServer` rebuilds it, which is also how to pick up
what has landed on those branches since. `:checkhealth secoro-dsl-nvim` shows
the interpreter, which packages import, and which parsers are compiled.

A language whose package fails to import loses its diagnostics but keeps hover,
completion and symbols.

## Tests

Run server and Neovim smoke tests:

```sh
.venv/bin/python3 test/test_server.py         # metamodels, diagnostics, outlines
nvim --headless -u NONE -l test/smoke.lua     # filetypes, parsers, queries, LSP attach
./check.sh                                    # the above, plus every grammar against every model
```

## License

MIT
