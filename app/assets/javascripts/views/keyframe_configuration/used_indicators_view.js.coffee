define [
  'underscore'
  'lib/type_data'
  'models/base/collection'
  'views/base/view'
  'views/base/collection_view'
  'views/keyframe_configuration/used_indicator_view'
  'jquery.sortable'
], (_, TypeData, Collection, View, CollectionView, UsedIndicatorView) ->
  'use strict'

  class UsedIndicatorsView extends CollectionView

    itemView: UsedIndicatorView
    tagName: 'ol'
    className: 'used-indicators'
    animationDuration: 0

    events:
      sortupdate: 'sortupdate'

    initialize: (options) ->
      super
      @keyframe = options.keyframe

    initItemView: (model) ->
      new @itemView {model, keyframe: @keyframe}

    sortupdate: (event, params) ->
      @trigger 'move', params.oldIndex, params.newIndex

    insertView: ->
      @$el.sortable 'destroy'
      super
      @$el.sortable()