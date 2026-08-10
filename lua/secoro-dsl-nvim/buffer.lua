local M = {}

--- Buffer-local options shared by every DSL in the family: same comment syntax,
--- same indent, and hyphenated names (`force-torque`, `S-CONFIGURE`) that word
--- motions, `*` and hover should treat as one word.
function M.setup()
  vim.bo.commentstring = "// %s"
  vim.bo.tabstop = 4
  vim.bo.shiftwidth = 4
  vim.bo.expandtab = true
  vim.opt_local.iskeyword:append("-")
end

return M
