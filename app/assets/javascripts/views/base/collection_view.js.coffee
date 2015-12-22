define (require) ->
  'use strict'
  Chaplin = require 'chaplin'
  View = require 'views/base/view'

  class CollectionView extends Chaplin.CollectionView

    # This class doesn’t inherit from the application-specific View class,
    # so we need to borrow the method from the View prototype:
    getTemplateFunction: View::getTemplateFunction

    hide: (item) ->
      @hideShow item, false

    show: (item) ->
      @hideShow item, true

    hideShow: (item, included) ->
      # Show/hide the view accordingly
      view = @subview "itemView:#{item.cid}"
      # A view has not been created for this item yet
      unless view
        throw new Error 'CollectionView#filter: ' +
          "no view found for #{item.cid}"
      view.$el
        .stop(true, true)
        .css('display', if included then '' else 'none')

      # Update visibleItems list
      @updateVisibleItems item, included
