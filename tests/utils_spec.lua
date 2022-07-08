local utils = require("pantran.utils")

describe("utils.table", function()
    local tbl, dict
    before_each(function()
      tbl = {"a", "b", "c"}
      dict = {a = 1, b = 2, c = 3}
    end)

    it('can pop values', function()
      local val = utils.table.pop(dict, "a")

      assert.are.equal(vim.tbl_count(dict), 2)
      assert.are.equal(dict["a"], nil)
      assert.are.equal(val, 1)
    end)

    it('supports default table values', function()
      local def = utils.table.defaulttable(0)

      for key, value in pairs(dict) do
        assert.are.equal(def[key], 0)
        assert.are.equal(def[value], 0)
      end
    end)

    it('supports zip iterator', function()
      local len = 0
      for key, value in utils.table.zip(tbl, vim.fn.sort(vim.tbl_values(dict))) do
        len = len + 1
        assert.are.equal(dict[key], value)
      end
      assert.are.equal(len, vim.tbl_count(dict))
    end)
end)
