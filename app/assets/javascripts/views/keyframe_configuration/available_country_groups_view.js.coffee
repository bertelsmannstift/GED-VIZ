define (require) ->
  'use strict'
  CollectionView = require 'views/base/collection_view'
  AvailableCountryGroupView = require 'views/keyframe_configuration/available_country_group_view'

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
      @trigger 'select', countryGroup, view
