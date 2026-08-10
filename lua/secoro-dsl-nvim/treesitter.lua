local M = {}

local languages = require("secoro-dsl-nvim.languages")

local function plugin_root()
  return vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
end

M.plugin_root = plugin_root

--- Where a language's generated parser source and compiled library live.
---@param language table entry from languages.lua
function M.paths(language)
  local root = plugin_root()
  return root .. "/grammars/" .. language.name .. "/src/parser.c",
    vim.fn.stdpath("data") .. "/site/parser/" .. language.name .. ".so"
end

local function compile(language)
  local src, so = M.paths(language)
  if vim.fn.filereadable(src) == 0 then
    vim.notify("secoro-dsl-nvim: parser.c not found at " .. src, vim.log.levels.WARN)
    return false
  end
  local cc = vim.fn.executable("cc") == 1 and "cc" or "gcc"
  if vim.fn.executable(cc) == 0 then
    vim.notify("secoro-dsl-nvim: no C compiler found; parsers not built", vim.log.levels.WARN)
    return false
  end
  vim.fn.mkdir(vim.fn.fnamemodify(so, ":h"), "p")
  local out = vim.fn.system(string.format(
    cc .. " -O2 -shared -fPIC -o %s %s -I %s",
    vim.fn.shellescape(so),
    vim.fn.shellescape(src),
    vim.fn.shellescape(vim.fn.fnamemodify(src, ":h"))
  ))
  if vim.v.shell_error ~= 0 then
    vim.notify(
      "secoro-dsl-nvim: " .. language.name .. " parser compilation failed:\n" .. out,
      vim.log.levels.WARN
    )
    return false
  end
  return true
end

--- Rebuild every parser, whether or not it is up to date.
function M.build()
  for _, language in ipairs(languages) do
    compile(language)
  end
end

local function ensure(language)
  local src, so = M.paths(language)
  if vim.fn.filereadable(src) == 0 or vim.fn.getftime(so) >= vim.fn.getftime(src) then
    return
  end
  compile(language)
end

function M.setup()
  local root = plugin_root()

  -- Ensure Neovim can find the queries/ directory regardless of plugin manager.
  local rtp = vim.opt.runtimepath:get()
  if not vim.tbl_contains(rtp, root) then
    vim.opt.runtimepath:append(root)
  end

  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  local configs = ok
      and (type(parsers.get_parser_configs) == "function" and parsers.get_parser_configs() or parsers)
    or nil

  for _, language in ipairs(languages) do
    ensure(language)
    if configs then
      configs[language.name] = {
        install_info = {
          url = root,
          location = "grammars/" .. language.name,
          files = { "src/parser.c" },
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
        filetype = language.name,
        maintainers = {},
      }
    end
  end
end

return M
