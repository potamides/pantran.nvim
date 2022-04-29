local curl = require("perapera.curl")
local config = require("perapera.config")

local deepl = {
  name = "DeepL",
  url_template = "https://api%s.deepl.com/v2",
  config = {
    free_api = true,
    auth = {auth_key = vim.env.DEEPL_AUTH_KEY},
    default_source = vim.NIL, -- API will attempt to detect the language automatically
    default_target = "EN-US",
    split_sentences = 1,
    preserve_formatting = 0,
    formality = "default"
  }
}

function deepl.usage()
  return deepl._api:post("usage")
end

function deepl.languages()
  local languages = {
    source = {
      [vim.NIL] = "Auto"
    },
    target = {}
  }

  for type_, tbl in pairs(languages) do
    for _, lang in pairs(deepl._api:post("languages", {["type"] = type_})) do
      tbl[lang.language] = lang.name
    end
  end

  return languages
end

function deepl.switch(source, target)
  local langs = deepl.languages()
  local new_source = vim.split(target, "-", {plain = true})[1]

  local matches = vim.tbl_filter(function(lang) return vim.startswith(lang, tostring(source)) end, vim.tbl_keys(langs.target))
  local new_target = table.remove(vim.fn.sort(matches))

  if not new_target or not langs.source[new_source] then
    return source, target
  end

  return new_source, new_target
end

function deepl.translate(text, source, target)
  source, target = source or deepl.config.default_source, target or deepl.config.default_target

  local translation = deepl._api:post("translate", {
    text = text,
    source_lang = source ~= vim.NIL and source or nil,
    target_lang = target,
    formality = deepl.config.formality,
    split_sentences = deepl.config.split_sentences,
    preserve_formatting = deepl.config.preserve_formatting,
  })

  return {
    text = translation.translations[1].text,
    detected = source == vim.NIL and translation.translations[1].detected_source_language or nil
  }
end

function deepl.setup()
  deepl._api = curl.new{
    url = deepl.url_template:format(deepl.config.free_api and "-free" or ""),
    auth = deepl.config.auth,
    static_paths = {"languages"}
  }
  if not deepl.config.auth.auth_key then
    error("This engine requires an API key to work!")
  end
end

return config.apply(config.user.engines.deepl, deepl)
