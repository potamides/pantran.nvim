--[[
Lua wrappers for vim buffer-local autocmds and keymaps. Official Lua APIs for
that where only introduced with Neovim 0.7 and this plugin targets Neovim 0.6.
--]]
local buffer = {
  group = "pantran",
  callbacks = {}
}

local function get_next_id(buf)
  if not buffer.callbacks[buf] then
    buffer.callbacks[buf] = {}
    vim.cmd(([[
      augroup %s
        autocmd BufWipeout <buffer=%d> ++once :lua require("pantran.utils.buffer").callbacks[%d] = nil
      augroup END
    ]]):format(buffer.group, buf, buf))
  end

  return #buffer.callbacks[buf] + 1
end

function buffer.autocmd(buf, args)
   -- while 0 would theoretically work it could lead to complications during cleanup
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  local events = type(args.events) == "table" and table.concat(args.events, ",") or args.events
  local pattern = ("<buffer=%d>"):format(buf)
  local once = args.once and "++once" or ""
  local nested = args.nested and "++nested" or ""
  local id = get_next_id(buf)

  buffer.callbacks[buf][id] = function()
    args.callback()
    if args.once and buffer.callbacks[buf] then
      buffer.callbacks[buf][id] = nil
    end
  end

  vim.cmd(([[
    augroup %s
      autocmd %s %s %s %s :lua require("pantran.utils.buffer").callbacks[%d][%d]()
    augroup END
  ]]):format(buffer.group, events, pattern, once, nested, buf, id))
end

function buffer.keymap(buf, args)
  local id, rhs = get_next_id(buf), args.rhs

  if type(args.rhs) == "function" then -- else it's a string
    rhs = ([[<cmd>lua require("pantran.utils.buffer").callbacks[%d][%d]()<cr>]]):format(buf, id)
    -- If a description exists we want to get it when converting a function to
    -- a string. For that matter we use metatable events.
    buffer.callbacks[buf][id] = setmetatable({}, {
      __call = args.rhs,
      __tostring = function() return args.desc or tostring(args.rhs) end
    })
  end

  vim.api.nvim_buf_set_keymap(buf, args.mode, args.lhs, rhs, args.opts)
end

function buffer.get_mappings(buf, mode)
  local mappings = {}
  for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    local id = tonumber(mapping.rhs:match("^.+%[(%d+)%]"))
    mappings[mapping.lhs] = id and buffer.callbacks[buf][id] or mapping.rhs
  end
  return mappings
end

return buffer
