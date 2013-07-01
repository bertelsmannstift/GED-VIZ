define [
  'views/base/view'
  'views/editor_introduction_view'
  'configuration'
], (View, EditorIntroductionView, configuration) ->
  'use strict'

  class EditorHeaderView extends View

    templateName: 'editor_header'

    tagName: 'header'

    events:
      'click .open-introduction': 'openIntroduction'

    openIntroduction: (event) ->
      event.preventDefault()
      @subview 'introduction', new EditorIntroductionView()
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
