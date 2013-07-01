define [
  'views/base/collection_view'
], (CollectionView) ->
  'use strict'

  # A collection view that adds an enabled/disabled class
  # to item views depending on their filter status.
  # Does not hide filtered views.

  class DisablingCollectionView extends CollectionView

    filterCallback: (view, included) ->
      #console.log 'filterCallback', view.model.get('iso3'), included
      view.$el
        .toggleClass('enabled', included)
        .toggleClass('disabled', not included)
      return
