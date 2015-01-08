define [
  'underscore'
  'lib/utils'
  'lib/i18n'
  'lib/type_data'
], (_, utils, I18n, TypeData) ->
  'use strict'

  t = I18n.t
  dataTypes = TypeData.data_types

  {
    # Returns the translated type with it’s sub-type, if applicable
    # e.g. “Trade (Cars)”
    shortType: (key) ->
      parentKey = dataTypes[key].parent
      if parentKey?
        # Has parent
        "#{t('data_type', parentKey)} (#{t('data_type_short', key)})"
      else if _.some(dataTypes, (e) -> e.parent is key)
        # Is parent
        "#{t('data_type', key)} (#{t('data_type_short', key)})"
      else
        "#{t('data_type_short', key)}"

    shortOptionalType: (key) ->
      if dataTypes[key].parent?
        " (#{t('data_type_short', key)})"
      else
        ''

    # Returns the translated type with it’s detailed sub-type, if applicable
    # e.g. “Trade (Cars, SITC 7812)”
    additionalType: (key) ->
      parentKey = dataTypes[key].parent
      if parentKey?
        # Has parent
        "#{t('data_type', parentKey)} (#{t('data_type_additional', key)})"
      else if _.some(dataTypes, (e) -> e.parent is key)
        # Is parent
        "#{t('data_type', key)} (#{t('data_type_additional', key)})"
      else
        "#{t('data_type_short', key)}"

    additionalOptionalType: (key) ->
      if dataTypes[key].parent?
        " (#{t('data_type_additional', key)})"
      else
        ''
  }
