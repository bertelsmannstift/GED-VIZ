define [
  'underscore'
  'lib/currency_rules'
], (_, currencyRules)->
  'use strict'

  getExchangeRate: (unit, year) ->
    for rule in currencyRules.conversions
      if unit in rule.to
        return rule.years[year]
    false

  currencies: ->
    [currencyRules.info.default].concat currencyRules.info.alternatives

  isVisible: (unit, currentUnit) ->
    unit in currencyRules.display[currentUnit] or
    unit in currencyRules.display.always

  transformUnit: (unit) ->
    for key, rule of currencyRules.conversions
      i = _.indexOf(rule.from, unit)
      return rule.to[i] if i > -1

      i = _.indexOf(rule.to, unit)
      return rule.from[i] if i > -1

    return false

  # For the given keyframe model, switch all units between dollars and euro
  adjustUnits: (model) ->

    # Adjust data unit
    [type, unit] = model.get 'data_type_with_unit'
    newUnit = @transformUnit unit

    if newUnit
      model.set data_type_with_unit: [type, newUnit]

    # Adjust indicator units
    twus = model.get 'indicator_types_with_unit'
    twus = _(twus).map (twu) =>
      newUnit = @transformUnit twu[1]
      if newUnit
        [twu[0], newUnit]
      else
        twu

    model.set indicator_types_with_unit: twus