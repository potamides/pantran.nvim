local curl = require("perapera.curl")
local config = require("perapera.config")

-- API reference: https://wiki.apertium.org/wiki/Apertium-apy
local apertium = {
  name = "Apertium",
  url = "https://beta.apertium.org/apy",
  config = {
    default_source = "auto",
    fallback_source = "deu",
    default_target = "eng",
    markUnknown = "no",
    format = "txt"
  }
}

local function detect(text, target)
  local detected = apertium._api:get("identifyLang", {
    q = text,
  })

  local langs = target and apertium._api:get("listPairs").responseData or apertium.languages()
  local max, best_lang = -math.huge, apertium.config.fallback_source
  for lang, probability in pairs(detected) do
    -- Not all returned languages are supported, so check if we can translate
    -- it. When optional param target is present, we test if a language pair
    -- exists.
    if probability > max then
      if target then
        for _, langpair in pairs(langs) do
          if langpair.sourceLanguage == lang and langpair.targetLanguage == target then
            max, best_lang = probability, lang
          end
        end
      else
        if langs.source[lang] or langs.target[lang] then
          max, best_lang = probability, lang
        end
      end
    end
  end

  return best_lang
end

function apertium.detect(text)
  return detect(text)
end

function apertium.languages()
  local languages = {
    source = {
      auto = "Auto"
    },
    target = {}
  }

  -- this gives us the language ids
  local source, target = {}, {}
  for _, pair in pairs(apertium._api:get("listPairs").responseData) do
    table.insert(source, pair.sourceLanguage)
    table.insert(target, pair.targetLanguage)
  end

  local langlist = apertium._api:get("listLanguageNames", {
    locale = "en", -- without this the next parameter doesn't work (maybe a bug?)
    languages = table.concat(vim.fn.uniq(vim.fn.sort(vim.list_extend(source, target))), " ")
  })

  -- this gives us the language names
  for id, lang in pairs(langlist) do
    if vim.tbl_contains(source, id) then
      languages.source[id] = lang
    end
    if vim.tbl_contains(target, id) then
      languages.target[id] = lang
    end
  end

  return languages
end

function apertium.switch(source, target)
  local langs = apertium.languages()
  if source == "auto" or not langs.target[source] or not langs.source[target] then
    return source, target
  else
    return target, source
  end
end

function apertium.translate(text, source, target)
  source, target = source or apertium.config.default_source, target or apertium.config.default_target
  local resolved_source = source == "auto" and detect(text, target) or source

  local translation = apertium._api:post("translate", {
    q = text,
    markUnknown = apertium.config.markUnknown,
    format = apertium.config.format,
    langpair = ("%s|%s"):format(resolved_source, target),
  })

  return {
    text = translation.responseData.translatedText,
    detected = source == "auto" and resolved_source or nil
  }
end

local function fmt_error(response)
  if response.status == "error" then
    return ("%s: %s."):format(response.message, response.explanation)
  elseif response.responseStatus then
    -- responseDetails seems to always be null
    return response.responseDetails or ("%s failed with response status %d!"):format(apertium.name, response.responseStatus)
  else
    return tostring(response)
  end
end

function apertium.setup()
  apertium._api = curl.new{
    url = apertium.url,
    fmt_error = fmt_error,
    static_paths = {"listPairs", "listLanguageNames"},
  }
end

return config.apply(config.user.engines.apertium, apertium)
