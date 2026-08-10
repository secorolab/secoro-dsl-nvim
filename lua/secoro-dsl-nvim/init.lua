local M = {}

---@class SecoroDslNvimConfig
---@field enable_lsp boolean Enable the language server (default: true)
---@field enable_treesitter boolean Register the tree-sitter parsers (default: true)
---@field python string|nil Path to a python executable that has pygls installed
---@field dsl_src string|nil Workspace `src` directory to install the DSL packages from
---@field lspconfig table|nil Extra options forwarded to the server config

M.config = {
  enable_lsp = true,
  enable_treesitter = true,
  python = nil,
  dsl_src = nil,
  lspconfig = {},
}

M.languages = require("secoro-dsl-nvim.languages")

---@param opts SecoroDslNvimConfig|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if M.config.enable_treesitter then
    require("secoro-dsl-nvim.treesitter").setup()
  end

  if M.config.enable_lsp then
    require("secoro-dsl-nvim.lsp").setup(M.config)
  end
end

return M
