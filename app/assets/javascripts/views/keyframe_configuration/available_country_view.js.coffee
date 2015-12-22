define (require) ->
  'use strict'
  View = require 'views/base/view'

  class AvailableCountryView extends View

    templateName: 'keyframe_configuration/available_country'
    tagName: 'li'
    className: 'available-country'

    events:
      click: 'add'

    add: (event) ->
      event.preventDefault()
      return if $(event.currentTarget).hasClass('disabled')
      @trigger 'add', @model
