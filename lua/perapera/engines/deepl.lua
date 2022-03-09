local curl = require("perapera.curl")

local deepl = {
  name = "DeepL",
  default = {
    args = {
      url = "https://api-free.deepl.com/v2",
      auth = {auth_key = vim.env.DEEPL_AUTH_KEY}
    },
    source = vim.NIL, -- API will attempt to detect the language automatically
    target = "EN",
    split_sentences = 1,
    preserve_formatting = 0,
    formality = "default"
  }
}

function deepl:usage()
  return self._api:post("usage")
end

function deepl:languages()
  if not self._languages then
    local languages = {
      source = {
        [vim.NIL] = "Auto"
      },
      target = {}
    }

    for type_, tbl in pairs(languages) do
      for _, lang in pairs(self._api:post("languages", {["type"] = type_})) do
        tbl[lang.language] = lang.name
      end
    end
    self._languages = languages
  end

  return self._languages
end

function deepl:switch(source, target)
  local langs = self:languages()
  local new_source = vim.split(target, "-", {plain = true})[1]

  local matches = vim.tbl_filter(function(lang) return vim.startswith(lang, tostring(source)) end, vim.tbl_keys(langs.target))
  local new_target = table.remove(vim.fn.sort(matches))

  if not new_target or not langs.source[new_source] then
    return source, target
  end

  return new_source, new_target
end

function deepl:translate(text, source, target)
  source, target = source or self.default.source, target or self.default.target

  local translation = self._api:post("translate", {
    text = text,
    source_lang = source ~= vim.NIL and source or nil,
    target_lang = target,
    formality = deepl.default.formality,
    split_sentences = deepl.default.split_sentences,
    preserve_formatting = deepl.default.preserve_formatting,
  })

  -- TODO: return table with detected language
  return ({
    text = translation.translations[1].text,
    detected = translation.translations[1].detected_source_language
  }).text
end

-- TODO: change to setup
function deepl.new(args)
  args = vim.tbl_deep_extend("force", deepl.default.args, args or {})
  local self = {
    _api = curl.new{
      url = args.url,
      auth = args.auth
    }
  }

  return setmetatable(self, {__index = deepl})
end

return deepl
