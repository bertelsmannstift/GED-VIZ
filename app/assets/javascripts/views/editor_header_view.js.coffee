define [
  'views/base/view'
  'views/editor_introduction_view'
  'configuration'
  'models/bubble'
  'views/bubble_view'
], (View, EditorIntroductionView, configuration, Bubble, BubbleView) ->
  'use strict'

  class EditorHeaderView extends View

    templateName: 'editor_header'

    tagName: 'header'

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
      data.items = [
        { key: 'home', prefix: true }
        { key: 'shorts', prefix: true }
        { key: 'studies', prefix: true }
        { key: 'viz', prefix: true, selected: true }
        { key: 'about' }
      ]
      data.locales = ['de', 'en']
      data.locale = configuration.locale
      data
