local api = {}

-- Implement nvim_buf_get_text, which is not available in neovim <= 0.6.*
--
--  Gets a range from the buffer.
--  This differs from |nvim_buf_get_lines()| in that it allows
--  retrieving only portions of a line.
--  Indexing is zero-based. Column indices are end-exclusive.
--  Prefer |nvim_buf_get_lines()| when retrieving entire lines.
function api.nvim_buf_get_text(buffer, start_row, start_col, end_row, end_col)
  local input = vim.api.nvim_buf_get_lines(buffer, start_row, end_row, true)
  if #input > 0 then
    input[1] = input[1]:sub(start_col + 1)
    input[#input] = input[#input]:sub(1, #input > 1 and end_col or end_col - start_col)
  end
  return input
end

return api
