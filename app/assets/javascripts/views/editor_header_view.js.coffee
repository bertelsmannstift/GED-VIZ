define (require) ->
  'use strict'
  I18n = require 'lib/i18n'
  View = require 'views/base/view'
  EditorIntroductionView = require 'views/editor_introduction_view'
  configuration = require 'configuration'
  Bubble = require 'models/bubble'
  BubbleView = require 'views/bubble_view'

  class EditorHeaderView extends View

    templateName: 'editor_header'

    tagName: 'header'
    className: 'editor-header'

    events:
      'click .open-introduction': 'openIntroduction'
      'mouseenter .open-introduction': 'showIntroductionRollover'
      'mouseleave .open-introduction': 'hideRollover'
      'mouseenter .language-switch a': 'showLocaleRollover'
      'mouseleave .language-switch a': 'hideRollover'

    openIntroduction: (event) ->
      event.preventDefault()
      @subview 'introduction', new EditorIntroductionView()
      return

    showIntroductionRollover: (event) ->
      target = event.target
      bubble = new Bubble
        type: 'rollover'
        text: 'show_introduction'
        targetElement: target
        position: 'below'
        positionLeftReference: target

      @subview 'rollover', new BubbleView(model: bubble)
      return

    showLocaleRollover: (event) ->
      target = event.target
      locale = $(event.target).data('locale')
      bubble = new Bubble
        type: 'rollover'
        text: "switch_to_locale_#{locale}"
        targetElement: target
        position: 'below'
        positionRightReference: target

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    getTemplateData: ->
      data = super
      data.items = I18n.translateObject ['navigation']
      data.locales = configuration.available_locales
      data.locale = configuration.locale
      data
