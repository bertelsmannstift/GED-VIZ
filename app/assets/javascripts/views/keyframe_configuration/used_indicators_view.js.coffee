define (require) ->
  'use strict'
  _ = require 'underscore'
  TypeData = require 'lib/type_data'
  Collection = require 'models/base/collection'
  View = require 'views/base/view'
  CollectionView = require 'views/base/collection_view'
  UsedIndicatorView = require 'views/keyframe_configuration/used_indicator_view'
  require 'jquery.sortable'

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