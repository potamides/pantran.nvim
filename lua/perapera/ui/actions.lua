local async = require("perapera.async")
local engines = require("perapera.engines")
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

function actions.close(window)
  window:close()
end

function actions.resize(window)
  window:resize()
end

local function on_lang(window, prop)
  return function(lang)
    if lang then
      window[prop] = lang
      actions.translate(window)
    end
  end
end

-- TODO: implement a more integrated picker for these kind of functions
actions.set_source = async.wrap(function(window)
  local langs = window.engine.languages().source
  vim.ui.select(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, on_lang(window, "source"))
end)

actions.set_target = async.wrap(function(window)
  local langs = window.engine.languages().target
  vim.ui.select(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, on_lang(window, "target"))
end)

actions.set_engine = async.wrap(function(window)
  local function on_choice(name)
    if name then
      local engine = engines[name]
      window.engine = engine
      window.source = engine.config.default_source
      window.target = engine.config.default_target
      window.detected = nil
      actions.translate(window)
    end
  end
  vim.ui.select(vim.tbl_keys(engines), nil, on_choice)
end)

actions.switch_languages = async.wrap(function(window, state)
  local source, target, detected = window.source, window.target, window.detected

  if not detected and state.previous and state.previous.source[source] and state.previous.target[target] then
    window.source, window.target = state.previous.source[source], state.previous.target[target]
  else
    window.source, window.target = window.engine.switch(detected or source, target)
  end

  if window.source ~= source or window.target ~= target then
    window.input = window.translation
    window.detected = nil
    actions.translate(window)
  end

  state.previous = {
    -- put source and target in different tables for the edge case that they are the same
    source = {[window.source] = source},
    target = {[window.target] = target}
  }
end)

actions.translate = async.wrap(function(window)
  local input, source, target = window.input, window.source, window.target

  if #input > 0 then
    local translated = window.engine.translate(input, source, target)
    window.translation = translated.text
    window.detected = translated.detected
  elseif #window.translation > 0 then
    window.translation = nil
    window.detected = nil
  end
end)

return actions
