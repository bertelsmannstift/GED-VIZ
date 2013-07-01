define [
  'underscore'
  'models/bubble'
  'views/base/view'
  'views/bubble_view'
  'lib/i18n'
], (_, Bubble, View, BubbleView, I18n) ->
  'use strict'

  class UsedCountryView extends View

    templateName: 'keyframe_configuration/used_country'

    tagName: 'li'
    className: 'used-country'

    events:
      click: 'selectHandler'
      'click .remove': 'removeHandler'

      'mouseenter .country': 'showCountryRollover'
      'mouseleave .country': 'hideRollover'
      'mousedown .country': 'hideRollover'

      'mouseenter .remove': 'showRemoveRollover'
      'mouseleave .remove': 'hideRollover'
      'mousedown .remove': 'hideRollover'

    selected: false

    initialize: ->
      super
      @listenTo @model, 'change', @render

    showCountryRollover: ->
      bubble = new Bubble
        type: 'rollover'
        text: if @isSelected() then 'country_unselect' else 'country_select'
        targetElement: @$el
        position: 'below'
        positionRightReference: @$el
        customClass: 'country-select'
        templateData:
          name: @nameForRollover()

      @subview 'rollover', new BubbleView(model: bubble)
      return

    showRemoveRollover: ->
      bubble = new Bubble
        type: 'rollover'
        text: 'country_remove'
        targetElement: @$('.remove')
        position: 'below'
        positionRightReference: @$el
        customClass: 'country-select'
        templateData:
          name: @nameForRollover()

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    nameForRollover: ->
      countryName = ''

      if @model.isGroup
        countryName = _(@model.get('countries')).map((c) -> c.name()).join(', ')
        countryName = @model.get('title') + " (#{countryName})"
      else
        countryName = I18n.t('country_names', @model.get('iso3'))

      countryName

    selectHandler: (event) ->
      event.preventDefault()
      @hideRollover event
      @toggleSelectCountry()

    removeHandler: (event) ->
      event.preventDefault()
      event.stopPropagation() # Prevent selecting
      @removeCountry()

    toggleSelectCountry: ->
      if @selected
        @unselectCountry()
      else
        @selectCountry()

    selectCountry: ->
      @selected = true
      @$el.addClass 'selected'
      @publishEvent 'country:selected', this

    unselectCountry: ->
      @selected = false
      @$el.removeClass 'selected'

    removeCountry: (event) ->
      @trigger 'remove', @model

    isSelected: ->
      @selected

    render: ->
      super
      if @model.isGroup
        @$el.addClass('country-group') if @model.get('countries').length > 1
