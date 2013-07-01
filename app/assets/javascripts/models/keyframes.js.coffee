define [
  'models/base/collection'
  'models/keyframe'
], (Collection, Keyframe) ->
  'use strict'

  class Keyframes extends Collection

    model: Keyframe

    moveKeyframe: (oldIndex, newIndex) ->
      keyframe = @at oldIndex
      @remove keyframe, silent: true
      @add keyframe, at: newIndex
      return
