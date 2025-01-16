local handlers = {}

function handlers.yank(text)
  local reg = ({[""] = '"', unnamed = "*", unnamedplus = "+"})[vim.o.clipboard]
  vim.fn.setreg(reg, text, "u")
end

function handlers.replace(text, coords)
  local lines = vim.split(text, "\n", {plain = true})
  if coords then
    if coords.ecol ~= 0 then
      coords.ecol = coords.ecol + 1
    end
    vim.api.nvim_buf_set_text(0, coords.srow, coords.scol, coords.erow, coords.ecol, lines)
  else
    vim.api.nvim_put(lines, "l", true, false)
  end
end

function handlers.append(text, coords)
  local lines = vim.split(text, "\n", {plain = true})
  if coords then
    -- When appending text always append on a new line since it's not trivial
    -- how whitespace should be added.
    vim.api.nvim_buf_set_lines(0, coords.erow + 1, coords.erow + 1, true, lines)
  else
    vim.api.nvim_put(lines, "l", true, false)
  end
end

function handlers.hover(text)
  if #text ~= 0  then
    -- FIXME: prevent translating two times when focusing floating window (i.e. using hover action twice in a row)
    vim.lsp.util.open_floating_preview(vim.split(text, "\n", {plain = true}), "text", {focus_id = "pantran"})
  end
end

return handlers
