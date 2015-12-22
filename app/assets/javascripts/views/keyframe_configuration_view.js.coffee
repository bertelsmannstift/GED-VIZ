define (require) ->
  'use strict'
  View = require 'views/base/view'
  DataView = require 'views/keyframe_configuration/data_view'
  IndicatorsView = require 'views/keyframe_configuration/indicators_view'
  CountriesView = require 'views/keyframe_configuration/countries_view'

  class KeyframeConfigurationView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    className: 'keyframe-configuration'

    render: ->
      super

      viewOptions =
        model: @model,
        container: @el,
        autoRender: true

      @subview 'data', new DataView(viewOptions)
      @subview 'indicators', new IndicatorsView(viewOptions)
      @subview 'countries', new CountriesView(viewOptions)
