-- Every extension in the family, from the one language table.
local extensions = {}
for _, language in ipairs(require("secoro-dsl-nvim.languages")) do
  for _, extension in ipairs(language.extensions) do
    extensions[extension] = language.name
  end
end
vim.filetype.add({ extension = extensions })
