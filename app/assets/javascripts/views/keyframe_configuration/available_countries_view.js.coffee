define (require) ->
  'use strict'
  DisablingCollectionView = require 'views/base/disabling_collection_view'
  AvailableCountryView = require 'views/keyframe_configuration/available_country_view'

  class AvailableCountriesView extends DisablingCollectionView

    templateName: 'keyframe_configuration/available_countries'
    className: 'available-countries'

    itemView: AvailableCountryView
    listSelector: 'ul'
    fallbackSelector: '.fallback'
    animationDuration: 0

    initItemView: (model) ->
      view = super
      # Pass `add` events from the item views
      @listenTo view, 'add', (country) ->
        @trigger 'add', country
      view
