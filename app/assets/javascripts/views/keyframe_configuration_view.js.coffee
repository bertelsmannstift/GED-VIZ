define [
  'views/base/view'
  'views/keyframe_configuration/data_view'
  'views/keyframe_configuration/indicators_view'
  'views/keyframe_configuration/countries_view'
], (View, DataView, IndicatorsView, CountriesView) ->
  'use strict'

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
