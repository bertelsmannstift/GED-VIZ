define [
  'views/base/disabling_collection_view'
  'views/keyframe_configuration/available_country_view'
], (DisablingCollectionView, AvailableCountryView) ->
  'use strict'

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
        #console.log 'AvailableCountriesView: Pass add event'
        @trigger 'add', country
      view
