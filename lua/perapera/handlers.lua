local common = {}

function common.yank_close(ui, text)
  local reg = ({[""] = '"', unnamed = "*", unnamedplus = "+"})[vim.o.clipboard]
  vim.fn.setreg(reg, text, "u")
  ui:close()
end

function common.replace_close(ui, text)
  ui:close()
  if ui.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

function common.append_close(ui, text)
  ui:close()
  if ui.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

return common
