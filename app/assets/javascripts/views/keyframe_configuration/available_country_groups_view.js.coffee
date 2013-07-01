define [
  'views/base/collection_view'
  'views/keyframe_configuration/available_country_group_view'
], (CollectionView, AvailableCountryGroupView) ->
  'use strict'

  class AvailableCountryGroupsView extends CollectionView

    tagName: 'ul'
    className: 'available-country-groups'

    itemView: AvailableCountryGroupView
    fallbackSelector: '.fallback'
    animationDuration: 0

    initItemView: (model) ->
      view = super
      # Pass `select` events from the item views
      @listenTo view, 'select', @selectHandler
      view

    selectHandler: (countryGroup, view) ->
      #console.log 'AvailableCountryGroups: Pass select event'
      @trigger 'select', countryGroup, view
