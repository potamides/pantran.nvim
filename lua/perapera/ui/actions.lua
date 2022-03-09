local async = require("perapera.async")
local actions = {}

function actions.help()
  error("Not implemented!") -- TODO
end

local function yank_close(window, text)
  local reg = ({[""] = '"', unnamed = "*", unnamedplus = "+"})[vim.o.clipboard]
  vim.fn.setreg(reg, text, "u")
  window:close()
end

local function replace_close(window, text)
  window:close()
  if window.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

local function append_close(window, text)
  window:close()
  if window.coords then
    error("Not implemented!") -- TODO
  else
    vim.api.nvim_paste(text, false, -1)
  end
end

function actions.yank_close_translation(window)
  yank_close(window, window.prop.translation)
end

function actions.yank_close_input(window)
  yank_close(window, window.prop.input)
end

function actions.replace_close_translation(window)
  replace_close(window, window.prop.translation)
end

function actions.replace_close_input(window)
  replace_close(window, window.prop.input)
end

function actions.append_close_translation(window)
  append_close(window, window.prop.translation)
end

function actions.append_close_input(window)
  append_close(window, window.prop.input)
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
  local source, target = window.prop.source, window.prop.target
  if state.previous and state.previous[source] and state.previous[target] then
    window.prop.source, window.prop.target = state.previous[source], state.previous[target]
  else
    window.prop.source, window.prop.target = window.prop.engine:switch(source, target)
  end

  if window.prop.source ~= source and window.prop.target ~= target then
    window.prop.input = window.prop.translation
    actions.translate(window)
  end

  state.previous = {
    [window.prop.source] = source,
    [window.prop.target] = target
  }
end)

actions.translate = async.wrap(function(window)
  local input, source, target = window.prop.input, window.prop.source, window.prop.target
  window.prop.translation = #input > 0 and window.prop.engine:translate(input, source, target) or ""
end)

return actions
