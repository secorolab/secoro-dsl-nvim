local M = {}

local languages = require("secoro-dsl-nvim.languages")

local function plugin_root()
  return vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
end

M.plugin_root = plugin_root

--- Interpreters worth trying, best guess first.
---@param hint string|nil explicit `python` from setup()
local function candidates(hint)
  local root = plugin_root()
  local list = {}
  local function add(cmd)
    if cmd and cmd ~= "" and vim.fn.executable(cmd) == 1 then
      table.insert(list, cmd)
    end
  end
  add(hint)
  add(vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV .. "/bin/python3")
  for _, dir in ipairs(vim.fs.find({ ".venv" }, { upward = true, type = "directory", limit = 3 })) do
    add(dir .. "/bin/python3")
  end
  add(root .. "/.venv/bin/python3")
  add("python3")
  add("python")
  return list
end

local function probe(python, module)
  vim.fn.system({ python, "-c", "import " .. module })
  return vim.v.shell_error == 0
end

--- The server needs pygls; each language's diagnostics additionally need its own
--- DSL package. Prefer the interpreter that has the most of them.
---@param hint string|nil explicit `python` from setup()
---@return string|nil python, string[] packages the DSL packages it can import
function M.find_python(hint)
  local best, best_packages = nil, {}
  for _, python in ipairs(candidates(hint)) do
    if probe(python, "pygls.lsp.server") then
      local packages = {}
      for _, language in ipairs(languages) do
        if probe(python, language.package) then
          table.insert(packages, language.package)
        end
      end
      if #packages == #languages then
        return python, packages
      end
      if best == nil or #packages > #best_packages then
        best, best_packages = python, packages
      end
    end
  end
  return best, best_packages
end

local CHECKOUTS = { "motion-spec-dsl", "scene-dsl", "coord-dsl", "robbdd" }

--- Whether a directory holds any of the DSL checkouts.
local function holds_checkouts(dir)
  for _, checkout in ipairs(CHECKOUTS) do
    if vim.fn.isdirectory(dir .. "/" .. checkout) == 1 then
      return true
    end
  end
  return false
end

--- The workspace `src` directory the DSL packages are installed from: a
--- checkout of this plugin usually sits in it, so its own parent is the
--- workspace; installed from GitHub instead, the nearest checkout above the
--- current directory decides.
function M.dsl_src()
  local sibling = vim.fs.dirname(plugin_root())
  if holds_checkouts(sibling) then
    return sibling
  end
  for _, checkout in ipairs(CHECKOUTS) do
    local found = vim.fs.find(checkout, { upward = true, type = "directory", limit = 1 })[1]
    if found then
      return vim.fs.dirname(found)
    end
  end
  return nil
end

--- Run build.sh: creates the venv with pygls and, when the DSL sources are
--- reachable, installs the DSL packages editable from there.
---@param opts table
---@param on_done fun(ok: boolean)|nil
function M.install(opts, on_done)
  local root = plugin_root()
  local build = root .. "/build.sh"
  if vim.fn.filereadable(build) == 0 then
    vim.notify("secoro-dsl-nvim: missing " .. build, vim.log.levels.ERROR)
    return on_done and on_done(false)
  end

  local src = M.dsl_src()
  vim.notify(
    "secoro-dsl-nvim: installing server dependencies"
      .. (src and (" (DSL from " .. src .. ")") or " (no DSL source found; no diagnostics)")
      .. "...",
    vim.log.levels.INFO
  )
  vim.fn.jobstart({ "bash", build }, {
    cwd = root,
    env = src and { SECORO_DSL_SRC = src } or nil,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("secoro-dsl-nvim: server ready.", vim.log.levels.INFO)
      else
        vim.notify("secoro-dsl-nvim: build.sh failed (exit " .. code .. ")", vim.log.levels.ERROR)
      end
      if on_done then
        on_done(code == 0)
      end
    end,
  })
end

local function ensure_venv(root, opts, on_done)
  if vim.fn.executable(root .. "/.venv/bin/python3") == 1 then
    return on_done(true)
  end
  M.install(opts, on_done)
end

local function filetypes()
  local list = {}
  for _, language in ipairs(languages) do
    table.insert(list, language.name)
  end
  return list
end

local function register(root, opts)
  local script = root .. "/server/secoro_dsl_lsp.py"
  if vim.fn.filereadable(script) == 0 then
    vim.notify("secoro-dsl-nvim: missing " .. script, vim.log.levels.ERROR)
    return
  end

  local python, packages = M.find_python(opts.python)
  if not python then
    vim.notify("secoro-dsl-nvim: no python with pygls found; LSP disabled.", vim.log.levels.WARN)
    return
  end
  if #packages < #languages then
    local missing = {}
    for _, language in ipairs(languages) do
      if not vim.tbl_contains(packages, language.package) then
        table.insert(missing, language.package)
      end
    end
    vim.notify(
      "secoro-dsl-nvim: "
        .. table.concat(missing, ", ")
        .. " not importable from "
        .. python
        .. "; those languages get hover/completion/symbols but no diagnostics. Run "
        .. ":SecoroDslInstallServer (see :checkhealth secoro-dsl-nvim).",
      vim.log.levels.WARN
    )
  end

  local config = vim.tbl_deep_extend("force", {
    cmd = { python, script },
    filetypes = filetypes(),
    root_markers = { ".git" },
  }, opts.lspconfig or {})

  if vim.lsp.config then
    vim.lsp.config("secoro_dsl_ls", config)
    vim.lsp.enable("secoro_dsl_ls")
    return
  end

  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    vim.notify(
      "secoro-dsl-nvim: Neovim >= 0.11 or nvim-lspconfig is required for LSP.",
      vim.log.levels.WARN
    )
    return
  end
  local configs = require("lspconfig.configs")
  if not configs.secoro_dsl_ls then
    configs.secoro_dsl_ls = {
      default_config = vim.tbl_extend("force", config, {
        name = "secoro_dsl_ls",
        docs = { description = "Language server for the secorolab DSLs" },
      }),
    }
  end
  lspconfig.secoro_dsl_ls.setup(opts.lspconfig or {})
end

function M.setup(opts)
  opts = opts or {}
  local root = plugin_root()

  vim.api.nvim_create_user_command("SecoroDslInstallServer", function()
    M.install(opts, function(ok)
      if ok then
        register(root, opts)
      end
    end)
  end, { desc = "(Re)install the secorolab DSL language server venv" })

  ensure_venv(root, opts, function(ok)
    if ok then
      register(root, opts)
    end
  end)
end

return M
