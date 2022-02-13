local curl = require("perapera.curl")

local deepl = {
  name = "DeepL",
  default = {
    args = {
      url = "https://api-free.deepl.com/v2",
      auth = {auth_key = vim.env.DEEPL_AUTH_KEY}
    },
    source = nil, -- when omitted API will attempt to detect the language automatically
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
  return self._api:post("languages")
end

function deepl:translate(text, source, target)
  local translation = self._api:post("translate", {
    text = text,
    source_lang = source or self.default.source,
    target_lang = target or self.default.target,
    formality = deepl.default.formality,
    split_sentences = deepl.default.split_sentences,
    preserve_formatting = deepl.default.preserve_formatting,
  })

  return translation.translations[1].text
end

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
