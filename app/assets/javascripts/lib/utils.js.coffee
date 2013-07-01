define [
  'underscore'
  'chaplin/lib/utils'
  'lib/i18n'
], (_, chaplinUtils, I18n) ->
  'use strict'

  # Application-specific utilities
  # ------------------------------

  # Delegate to Chaplin’s utils module
  utils = chaplinUtils.beget chaplinUtils

  # Add additional application-specific properties and methods
  _(utils).extend {

    # Constants
    # ---------

    # Unit representation types
    UNIT_ABSOLUTE: 0
    UNIT_PROPORTIONAL: 1
    UNIT_RANKING: 2

    # Chart format
    FORMAT_DEFAULT: 'default'
    FORMAT_THUMBNAIL: 'thumbnail'

    # Number formatting options for specific relation/indicator types
    FORMAT_OPTIONS:
      population:
        mln_persons:
          decimals: 1
      inflation:
        percent:
          decimals: 2
      hdi:
        hdi:
          customFormatter: (value) ->
            value = value - Math.floor(value)
            utils.formatNumber(value, 2, true)

    # Custom font-family for text labels in the chart
    CUSTOM_FONT: '"CamingoDos SCd", "Arial Narrow", "Helvetica Neue", Helvetica, Arial, sans-serif'
    FALLBACK_FONT: '"Arial Narrow", "Helvetica Neue", Helvetica, Arial, sans-serif'

    # Methods
    # -------

    # setTimeout with a sane signature
    after: (wait, fn) ->
      setTimeout fn, wait

    # requestAnimationFrame: do ->
    #   w = window
    #   raf = w.requestAnimationFrame or w.mozRequestAnimationFrame or
    #     w.webkitRequestAnimationFrame or w.msRequestAnimationFrame or
    #     (fn) -> setTimeout fn, 1000 / 60
    #   (fn) -> raf fn

    formatValue: (value, type, unit) ->
      options = utils.FORMAT_OPTIONS[type]?[unit]
      if options?.customFormatter?
        options.customFormatter(value)
      else
        decimals      = options?.decimals      ? 2
        forceDecimals = options?.forceDecimals ? false
        utils.formatNumber(value, decimals, forceDecimals)

    # Formats 123456.789 as 123,456.789
    # Cuts of decimals if the number gets high
    # Cuts of zeros in decimals
    formatNumber: (number, decimals = 2, forceDecimals = false) ->
      decimalMark = I18n.t 'decimal_mark'
      thousandsSeparator = I18n.t 'thousands_separator'

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
      str = ''
      i = int.length
      consumed = 0
      while i-- > 0
        if consumed is 3
          str = int[i] + thousandsSeparator + str
          consumed = 0
        else
          str = int[i] + str
        consumed++

      # Only add the decimals if the integer is less then 4 digits
      if (forceDecimals or str.length < 4) and fraction.length > 0
        str += decimalMark + fraction

      # Add sign again
      str = sign + str

      str

    # Sorts elements by their volume (descending)
    elementsSorter: (a, b) ->
      b.sum - a.sum

    # Sorts relations by their amount (descending)
    relationSorter: (a, b) ->
      b.amount - a.amount

    getFont: (customFont) ->
      if customFont then @CUSTOM_FONT else @FALLBACK_FONT

  } # End utils

  Object.freeze? utils

  # Create a dummy console
  unless window.console
    window.console = {}
  noop = new Function
  for name in ['log', 'debug', 'dir']
    if name not of console
      console[name] = noop

  utils