define (require) ->
  'use strict'
  _ = require 'underscore'
  utils = require 'lib/utils'
  I18n = require 'lib/i18n'
  TypeData = require 'lib/type_data'

  t = I18n.t
  dataTypes = TypeData.data_types
  tType = _.partial t, 'data_type'
  tShort = _.partial t, 'data_type_short'
  tAdditional = _.partial t, 'data_type_additional'

  {
    # Returns the translated type with it’s sub-type, if applicable
    # e.g. “Trade (Cars)”
    shortType: (key) ->
      parentKey = dataTypes[key].parent
      if parentKey?
        # Has parent
        "#{tType(parentKey)} (#{tShort(key)})"
      else if _.some(dataTypes, (e) -> e.parent is key)
        # Is parent
        "#{tType(key)} (#{tShort(key)})"
      else
        "#{tShort(key)}"

    shortOptionalType: (key) ->
      if dataTypes[key].parent?
        " (#{tShort(key)})"
      else
        ''

    # Returns the translated type with it’s detailed sub-type, if applicable
    # e.g. “Trade (Cars, SITC 7812)”
    additionalType: (key) ->
      parentKey = dataTypes[key].parent
      if parentKey?
        # Has parent
        "#{tType(parentKey)} (#{tAdditional(key)})"
      else if _.some(dataTypes, (e) -> e.parent is key)
        # Is parent
        "#{tType(key)} (#{tAdditional(key)})"
      else
        "#{tShort(key)}"

    additionalOptionalType: (key) ->
      if dataTypes[key].parent?
        " (#{tAdditional(key)})"
      else
        ''
  }
