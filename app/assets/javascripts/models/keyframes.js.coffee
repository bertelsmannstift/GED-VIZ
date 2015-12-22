define (require) ->
  'use strict'
  Collection = require 'models/base/collection'
  Keyframe = require 'models/keyframe'

  class Keyframes extends Collection

    model: Keyframe

    moveKeyframe: (oldIndex, newIndex) ->
      keyframe = @at oldIndex
      @remove keyframe, silent: true
      @add keyframe, at: newIndex
      return

    # Returns whether there are no keyframes or all keyframes are empty
    isEmpty: ->
      @length is 0 or @every((keyframe) -> keyframe.isEmpty())

