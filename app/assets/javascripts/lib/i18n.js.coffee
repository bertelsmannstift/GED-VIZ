define [
  'underscore'
  'configuration'
  'translations'
], (_, configuration, translations)->
  'use strict'

  # Internal helpers
  # ----------------

  translateSingle = (keys) ->
    # Support 'foo.bar.qux' and ['foo', 'bar', 'quux']
    keys = keys.split('.') if typeof keys is 'string'
    tree = translations[configuration.locale]
    for key in keys
      tree = tree[key]
      if typeof tree in ['string', 'number', 'boolean']
        return tree
      else if tree?
        continue
      else
        return null

  translateMultiple = (arraysOfKeys) ->
    for keys in arraysOfKeys
      translation = translateSingle keys
      return translation if translation?
    null

  templateOptions = interpolate: /%\{(.+?)\}/g
  compiledTemplates = {}

  # Public interface of I18n

  {
    t: (keys...) ->
      translation = if keys[0] instanceof Array
        throw new Error 'translateMultiple'
        translateMultiple keys
      else
        translateSingle keys

      unless translation?
        console.error 'I18n: Undefined translation:', keys
        return "I18n: Undefined translation: #{keys.join(' ')}"

      translation

    template: (keys, data) ->
      cacheKey = keys.join '.'
      templateFunction = compiledTemplates[cacheKey]
      unless templateFunction
        template = translateSingle keys
        unless template?
          console.error 'I18n: Undefined template:', keys
          return ->
        templateFunction = _.template template, null, templateOptions
        compiledTemplates[cacheKey] = templateFunction
      templateFunction data
  }