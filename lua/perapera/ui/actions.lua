local async = require("perapera.async")
local actions = {}

function actions.help()
  error("Not implemented!") -- TODO
end

local function yank_close(window, buffer)
  local text = window.get_text(buffer.bufnr)
  local reg = ({[""] = '"', unnamed = "*", unnamedplus = "+"})[vim.o.clipboard]
  vim.fn.setreg(reg, text, "u")
  window:close()
end

local function replace_close(window, buffer)
  local text = window.get_text(buffer.bufnr)
  window:close()
  if window.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

local function append_close(window, buffer)
  local text = window.get_text(buffer.bufnr)
  window:close()
  if window.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

function actions.yank_close_translation(window)
  yank_close(window, window.translation)
end

function actions.yank_close_input(window)
  yank_close(window, window.input)
end

function actions.replace_close_translation(window)
  replace_close(window, window.translation)
end

function actions.replace_close_input(window)
  replace_close(window, window.input)
end

function actions.append_close_translation(window)
  append_close(window, window.translation)
end

function actions.append_close_input(window)
  append_close(window, window.input)
end

function actions.set_engine()
  error("Not implemented!") -- TODO
end

function actions.set_source()
  error("Not implemented!") -- TODO
end

function actions.set_target()
  error("Not implemented!") -- TODO
end

function actions.close(window)
  window:close()
end

function actions.resize(window)
  window:resize()
end

actions.switch_languages = async.wrap(function(window, state)
  local source, target = window.source, window.target
  if state.previous and state.previous[source] and state.previous[target] then
    window.source, window.target = state.previous[source], state.previous[target]
  else
    window.source, window.target = window.engine:switch(source, target)
  end

  if window.source ~= source and window.target ~= target then
    window:set_input(window:get_translation())
    actions.translate(window)
  end

  state.previous = {
    [window.source] = source,
    [window.target] = target
  }
end)

actions.translate = async.wrap(function(window)
  local input, source, target = window:get_input(), window.source, window.target
  window:set_translation(#input > 0 and window.engine:translate(input, source, target) or "")
end)

return actions
