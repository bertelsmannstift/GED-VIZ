define [
  'views/base/view'
], (View) ->
  'use strict'

  class NewKeyframeView extends View

    # Property declarations
    # ---------------------
    #
    # model: Editor

    tagName: 'li'
    className: 'new'

    templateName: 'new_keyframe'

    autoRender: true

    getTemplateData: ->
      data = super
      data.index = @model.getKeyframes().length + 1
      data
