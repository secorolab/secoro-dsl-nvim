local M = {}

local languages = require("secoro-dsl-nvim.languages")

local function plugin_root()
  return vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
end

M.plugin_root = plugin_root

--- A language's grammar, the parser generated from it, and the compiled library.
---@param language table entry from languages.lua
function M.paths(language)
  local dir = plugin_root() .. "/grammars/" .. language.name
  return dir .. "/grammar.js",
    dir .. "/src/parser.c",
    vim.fn.stdpath("data") .. "/site/parser/" .. language.name .. ".so"
end

local notified = false

--- Say once why there are no tree-sitter parsers. The regex syntax in `syntax/`
--- still highlights, and the language server is unaffected, so this is a
--- degraded editor rather than a broken one.
local function missing(what, remedies)
  if notified then
    return
  end
  notified = true
  vim.notify(
    "secoro-dsl-nvim: " .. what .. "; falling back to regex highlighting. " .. remedies,
    vim.log.levels.WARN
  )
end

local function run(cmd, cwd)
  local out = vim.fn.system(cwd and { "sh", "-c", "cd " .. vim.fn.shellescape(cwd) .. " && " .. cmd }
    or { "sh", "-c", cmd })
  return vim.v.shell_error == 0, out
end

--- Write `src/parser.c` from `grammar.js`. Costs about half a second for the
--- largest grammar here, which is why it is not committed: a generated parse
--- table rewrites wholesale on any grammar edit and drowns the diff it came
--- from.
local function generate(language)
  local grammar, src = M.paths(language)
  if vim.fn.filereadable(grammar) == 0 then
    return false
  end
  if vim.fn.executable("tree-sitter") == 0 then
    missing(
      "tree-sitter CLI not found, so no parser can be generated",
      "Install it with :MasonInstall tree-sitter-cli, cargo install tree-sitter-cli, "
        .. "or npm install -g tree-sitter-cli, then :SecoroDslBuildParsers."
    )
    return false
  end
  local ok, out = run("tree-sitter generate", vim.fn.fnamemodify(src, ":h:h"))
  if not ok then
    vim.notify(
      "secoro-dsl-nvim: generating the " .. language.name .. " parser failed:\n" .. out,
      vim.log.levels.WARN
    )
  end
  return ok
end

local function compile(language)
  local _, src, so = M.paths(language)
  if vim.fn.filereadable(src) == 0 then
    return false
  end
  local cc = vim.fn.executable("cc") == 1 and "cc" or "gcc"
  if vim.fn.executable(cc) == 0 then
    missing("no C compiler found, so no parser can be built", "Install cc or gcc.")
    return false
  end
  vim.fn.mkdir(vim.fn.fnamemodify(so, ":h"), "p")
  local ok, out = run(string.format(
    cc .. " -O2 -shared -fPIC -o %s %s -I %s",
    vim.fn.shellescape(so),
    vim.fn.shellescape(src),
    vim.fn.shellescape(vim.fn.fnamemodify(src, ":h"))
  ))
  if not ok then
    vim.notify(
      "secoro-dsl-nvim: compiling the " .. language.name .. " parser failed:\n" .. out,
      vim.log.levels.WARN
    )
  end
  return ok
end

--- Regenerate and rebuild every parser, whether or not it is up to date.
function M.build()
  notified = false
  for _, language in ipairs(languages) do
    if generate(language) then
      compile(language)
    end
  end
end

--- Bring one parser up to date with its grammar, doing nothing when it already
--- is -- which is every start after the first.
local function ensure(language)
  local grammar, src, so = M.paths(language)
  local built, written = vim.fn.getftime(so), vim.fn.getftime(grammar)
  if built >= written then
    return
  end
  if vim.fn.getftime(src) < written and not generate(language) then
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

  vim.api.nvim_create_user_command("SecoroDslBuildParsers", function()
    M.build()
  end, { desc = "Regenerate and rebuild the secorolab DSL tree-sitter parsers" })

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
          requires_generate_from_grammar = true,
        },
        filetype = language.name,
        maintainers = {},
      }
    end
  end
end

return M
