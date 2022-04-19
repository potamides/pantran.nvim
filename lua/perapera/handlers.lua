local handlers = {}

function handlers.yank(text)
  local reg = ({[""] = '"', unnamed = "*", unnamedplus = "+"})[vim.o.clipboard]
  vim.fn.setreg(reg, text, "u")
end

function handlers.replace(text, coords)
  local lines = vim.split(text, "\n", {plain = true})
  if coords then
    vim.api.nvim_buf_set_text(0, coords.srow, coords.scol, coords.erow, coords.ecol, lines)
  else
    vim.api.nvim_put(lines, "l", true, false)
  end
end

function handlers.append(text, coords)
  local lines = vim.split(text, "\n", {plain = true})
  if coords then
    -- TODO: think of a better way to do this
    vim.api.nvim_buf_set_lines(0, coords.erow + 1, coords.erow + 1, true, lines)
  else
    vim.api.nvim_put(lines, "l", true, false)
  end
end

function handlers.hover(text)
  error("Not yet implemented!") -- TODO
end

return handlers
