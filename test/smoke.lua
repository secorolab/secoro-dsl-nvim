-- Neovim smoke test: what only a running editor can answer.
--
--     nvim --headless -u NONE -l test/smoke.lua
--
-- Every language opens its own coverage file: the extension must resolve to the
-- filetype, the parser must compile and read the file without an ERROR node,
-- the highlights query must match something, and the server must attach. What
-- the server then says about a model is test_server.py's business.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.runtimepath:append(root)
vim.cmd("filetype plugin on")
require("secoro-dsl-nvim").setup()

local languages = require("secoro-dsl-nvim.languages")
local failures = 0

-- Written straight out and flushed: `cq` aborts without draining what print()
-- has buffered, which would hide the very lines a failing run is for.
local function say(line)
  io.stdout:write(line, "\n")
  io.stdout:flush()
end

local function check(ok, what)
  say((ok and "ok   " or "FAIL ") .. what)
  if not ok then
    failures = failures + 1
  end
end

for _, language in ipairs(languages) do
  for _, extension in ipairs(language.extensions) do
    check(
      vim.filetype.match({ filename = "model." .. extension }) == language.name,
      extension .. " is filetype " .. language.name
    )
  end

  local file = root .. "/test/coverage." .. language.name
  vim.cmd("edit " .. vim.fn.fnameescape(file))
  check(vim.bo.filetype == language.name, language.name .. ": filetype of the coverage file")
  check(vim.bo.commentstring == "// %s", language.name .. ": commentstring")

  if vim.fn.executable("tree-sitter") == 0 then
    say("     (no tree-sitter CLI; " .. language.name .. " parser not checked)")
    goto continue
  end

  local ok, parser = pcall(vim.treesitter.get_parser, 0, language.name)
  check(ok, language.name .. ": parser loads")
  if ok then
    local tree = parser:parse()[1]:root()
    check(not tree:has_error(), language.name .. ": parses with no ERROR node")

    local query = vim.treesitter.query.get(language.name, "highlights")
    check(query ~= nil, language.name .. ": highlights query compiles")
    if query then
      local captures = 0
      for _ in query:iter_captures(tree, 0) do
        captures = captures + 1
      end
      check(captures > 0, language.name .. ": highlights " .. captures .. " nodes")
    end
  end

  ::continue::
end

-- One client serves the family, so the last buffer speaks for all of them.
if vim.fn.executable(root .. "/.venv/bin/python3") == 1 then
  vim.wait(30000, function()
    return #vim.lsp.get_clients({ bufnr = 0 }) > 0
  end, 200)
  local names = vim.tbl_map(function(client)
    return client.name
  end, vim.lsp.get_clients({ bufnr = 0 }))
  check(vim.tbl_contains(names, "secoro_dsl_ls"), "language server attaches")
else
  say("     (no .venv; run ./build.sh to smoke-test the server too)")
end

vim.cmd(failures > 0 and "cq" or "qa!")
