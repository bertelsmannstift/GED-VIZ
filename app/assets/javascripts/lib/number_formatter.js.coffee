define [
  'lib/i18n'
], (I18n) ->
  'use strict'

  # Constants
  # ---------

  # Number formatting options for specific relation/indicator types
  FORMAT_OPTIONS:
    population:
      mln_persons:
        decimals: 1
     migration:
      persons:
        decimals: 0

  # Methods
  # -------

  # Formats a data or indicator value using the formatting options above
  formatValue: (value, type, unit, html = false) ->
    options = @FORMAT_OPTIONS[type]?[unit]
    if options
      if options.customFormatter
        options.customFormatter.call(this, value)
      else
        decimals = options.decimals
        forceDecimals = options.forceDecimals
    decimals ?= 2
    forceDecimals ?= false
    @formatNumber value, decimals, forceDecimals, html

  # Formats 123456.789 as 123,456.789
  # Cuts off decimals if the number gets high
  # Cuts off zeros in decimals
  formatNumber: (number, decimals = 2, forceDecimals = false, html = false) ->

    str = Number(number).toFixed(decimals)

    pointPos = str.indexOf '.'
    pointPos = str.length if pointPos is -1

    int = str.substring 0, pointPos
    if str.charAt(0) is '-'
      sign = '-'
      int = int.substring 1
    else
      sign = ''

    fraction = str.substring pointPos + 1

    # Add thousands separators
    thousandsSeparator = I18n.t "thousands_separator#{if html then '_html' else ''}"
    str = ''
    i = int.length
    consumed = 0
    while i-- > 0
      if consumed is 3
        str = int.charAt(i) + thousandsSeparator + str
        consumed = 0
      else
        str = int.charAt(i) + str
      consumed++

    # Only add the decimals if the integer is less then 4 digits
    decimalMark = I18n.t 'decimal_mark'
    if (forceDecimals or str.length < 4) and fraction.length > 0
      str += decimalMark + fraction

    # Add sign again
    str = sign + str

    str
