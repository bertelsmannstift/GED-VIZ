define [
  'jquery'
  'underscore'
], ($, _) ->
  'use strict'

  # The static chart is just an image gallery that just shows the keyframes
  # as static PNGs. It’s a fallback for browser that don’t support VML/SVG.
  class StaticChart

    constructor: (options) ->
      @presentation = options.presentation
      @container = options.container
      @paperSize = @getPaperSize()
      @imageSize = @imageSizeFromPaperSize @paperSize
      @$img = $('<img>', class: "static-chart #{@imageSize}")
      $(@container).append @$img
      $(window).resize @resize

    getPaperSize: ->
      $container = $(@container)
      width  = $container.width()
      height = $container.height()
      Math.min width, height

    imageSizeFromPaperSize: (paperSize) ->
      if paperSize >= (800 * 3/4)
        'large'
      else if paperSize >= (520 * 3/4)
        'medium'
      else
        'small'

    update: (options) ->
      @keyframe = options.keyframe
      @showKeyframe @keyframe
      return

    showKeyframe: (keyframe) ->
      imageURL = @presentation.staticKeyframeImage keyframe, @imageSize
      return if imageURL is false
      @$img.attr src: imageURL
      return

    resize: =>
      oldPaperSize = @paperSize
      oldImageSize = @imageSize
      newPaperSize = @getPaperSize()
      newImageSize = @imageSizeFromPaperSize newPaperSize
      @paperSize = newPaperSize
      if newImageSize isnt oldImageSize
        @imageSize = newImageSize
        @$img
          .removeClass(oldImageSize)
          .addClass(newImageSize)
        @showKeyframe @keyframe
      return

    resize: _.debounce(@prototype.resize, 100)

    dispose: ->
      return if @disposed
      $(window).off 'resize', @resize
      delete @presentation
      delete @container
      @disposed = true
