define [
  'views/base/view'
], (View) ->
  'use strict'

  class AvailableCountryGroupView extends View

    templateName: 'keyframe_configuration/available_country_group'
    tagName: 'li'
    className: 'available-country-group'

    events:
      click: 'select'

    select: (event) ->
      event.preventDefault()
      #console.log 'AvailableCountryGroup: select'
      @trigger 'select', @model, this
