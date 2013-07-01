define [
  'views/base/view'
], (View) ->
  'use strict'

  class AvailableCountryView extends View

    templateName: 'keyframe_configuration/available_country'
    tagName: 'li'
    className: 'available-country'

    events:
      click: 'add'

    add: (event) ->
      event.preventDefault()
      #console.log 'AvailableCountry#add'
      return if $(event.currentTarget).hasClass('disabled')
      @trigger 'add', @model
