local utils = {
  group = "perapera",
  callbacks = {}
}

local function get_next_id(buffer)
  if not utils.callbacks[buffer] then
    utils.callbacks[buffer] = {}
    vim.cmd(([[
      augroup %s
        autocmd BufWipeout <buffer=%d> ++once :lua require("perapera.utils").callbacks[%d] = nil
      augroup END
    ]]):format(utils.group, buffer, buffer))
  end

  return #utils.callbacks[buffer] + 1
end

function utils.buf_autocmd(buffer, args)
  local events = type(args.events) == "table" and table.concat(args.events, ",") or args.events
  local pattern = ("<buffer=%d>"):format(buffer)
  local once = args.once and "++once" or ""
  local nested = args.nested and "++nested" or ""
  local id = get_next_id(buffer)

  utils.callbacks[buffer][id] = function()
    args.callback()
    if args.once and utils.callbacks[buffer] then
      utils.callbacks[buffer][id] = nil
    end
  end

  vim.cmd(([[
    augroup %s
      autocmd %s %s %s %s :lua require("perapera.utils").callbacks[%d][%d]()
    augroup END
  ]]):format(utils.group, events, pattern, once, nested, buffer, id))
end

function utils.buf_keymap(buffer, args)
  local id = get_next_id(buffer)
  local rhs = ([[<cmd>lua require("perapera.utils").callbacks[%d][%d]()<cr>]]):format(buffer, id)

  utils.callbacks[buffer][id] = args.rhs
  vim.api.nvim_buf_set_keymap(buffer, args.mode, args.lhs, rhs, args.opts)
end

function utils.pop(tbl, key)
  if type(key) == "number" then
    return table.remove(tbl, key)
  else
    local value = tbl[key]
    tbl[key] = nil
    return value
  end
end

function utils.make_properties(tbl, noself)
  local mt, proxy = {}, {
    prop = {
      set = {},
      get = {}
    }
  }

  for kind, funcs in pairs(tbl.prop) do
    for name, func in pairs(funcs) do
      if noself then
        proxy.prop[kind][name] = func
      else
        proxy.prop[kind][name] = function(...) return func(tbl, ...) end
      end
    end
  end

  mt.__index = function(_, key)
    if tbl.prop.get and tbl.prop.get[key] then
      return tbl.prop.get[key](noself and nil or tbl)
    else
      return tbl[key]
    end
  end

  mt.__newindex = function(_, key, value)
    if tbl.prop.set and tbl.prop.set[key] then
      tbl.prop.set[key](unpack(noself and {value} or {tbl, value}))
    else
      rawset(tbl, key, value)
    end
  end

  return setmetatable(proxy, mt)
end

return utils
