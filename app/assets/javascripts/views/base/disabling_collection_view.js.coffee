define (require) ->
  'use strict'
  CollectionView = require 'views/base/collection_view'

  # A collection view that adds an enabled/disabled class
  # to item views depending on their filter status.
  # Does not hide filtered views.

  class DisablingCollectionView extends CollectionView

    filterCallback: (view, included) ->
      view.$el
        .toggleClass('enabled', included)
        .toggleClass('disabled', not included)
      return
