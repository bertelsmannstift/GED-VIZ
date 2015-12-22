define (require) ->
  'use strict'
  _ = require 'underscore'
  chaplinUtils = require 'chaplin/lib/utils'
  I18n = require 'lib/i18n'

  # Application-specific utilities
  # ------------------------------

  # Delegate to Chaplin’s utils module
  utils = chaplinUtils.beget chaplinUtils

  # Add additional application-specific properties and methods
  _(utils).extend {

    # Constants
    # ---------

    # Chart format
    FORMAT_DEFAULT: 'default'
    FORMAT_THUMBNAIL: 'thumbnail'

    # Custom font-family for text labels in the chart
    CUSTOM_FONT: 'CamingoDos SCd, "Arial Narrow", "Helvetica Neue", Helvetica, Arial, sans-serif'
    FALLBACK_FONT: '"Arial Narrow", "Helvetica Neue", Helvetica, Arial, sans-serif'

    # Methods
    # -------

    # setTimeout with a sane signature
    after: (wait, fn) ->
      setTimeout fn, wait

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

  utils
