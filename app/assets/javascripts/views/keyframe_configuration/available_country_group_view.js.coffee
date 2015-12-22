define (require) ->
  'use strict'
  View = require 'views/base/view'

  class AvailableCountryGroupView extends View

    templateName: 'keyframe_configuration/available_country_group'
    tagName: 'li'
    className: 'available-country-group'

    events:
      click: 'select'

    select: (event) ->
      event.preventDefault()
      @trigger 'select', @model, this
