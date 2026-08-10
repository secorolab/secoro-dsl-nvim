local M = {}

local health = vim.health or require("health")
local languages = require("secoro-dsl-nvim.languages")

function M.check()
  health.start("secoro-dsl-nvim")

  local lsp = require("secoro-dsl-nvim.lsp")
  local treesitter = require("secoro-dsl-nvim.treesitter")

  local config = require("secoro-dsl-nvim").config
  local src = lsp.dsl_src(config.dsl_src)
  if src then
    health.ok("DSL sources: " .. src)
  else
    health.warn("no DSL checkout found", {
      "set `dsl_src` in setup() to the workspace src directory, then :SecoroDslInstallServer",
    })
  end

  local python, packages = lsp.find_python(config.python)
  if not python then
    health.error("no python with pygls found", {
      ":SecoroDslInstallServer",
      "or set `python` in setup() to an interpreter that has pygls",
    })
  else
    health.ok("language server: " .. python)
    for _, language in ipairs(languages) do
      if vim.tbl_contains(packages, language.package) then
        health.ok("  " .. language.name .. ": " .. language.package .. " (diagnostics on)")
      else
        health.warn("  " .. language.name .. ": no " .. language.package .. " (no diagnostics)", {
          "set `dsl_src` in setup() and run :SecoroDslInstallServer",
        })
      end
    end
  end

  for _, language in ipairs(languages) do
    local _, so = treesitter.paths(language)
    if vim.fn.filereadable(so) == 1 then
      health.ok("tree-sitter parser: " .. so)
    else
      health.warn("tree-sitter parser not compiled: " .. language.name, {
        ":lua require('secoro-dsl-nvim.treesitter').build()",
        "or run " .. lsp.plugin_root() .. "/build-parsers.sh",
      })
    end
  end

  if vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 then
    health.ok("C compiler available for parser builds")
  else
    health.warn("no cc/gcc found; the tree-sitter parsers cannot be compiled")
  end
end

return M
