define (require) ->
  'use strict'
  _ = require 'underscore'
  Bubble = require 'models/bubble'
  View = require 'views/base/view'
  BubbleView = require 'views/bubble_view'
  Currency = require 'lib/currency'
  I18n = require 'lib/i18n'
  TypeData = require 'lib/type_data'
  require 'jquery.sortable'

  class UsedIndicatorView extends View
    templateName: 'keyframe_configuration/used_indicator'
    tagName: 'li'
    className: 'used-indicator'

    events:
      'click a.unit-selector': 'unitSelectorClicked'
      'click a.unit': 'unitClicked'

      mouseenter: 'showRollover'
      mouseleave: 'hideRollover'

    initialize: (options) ->
      super
      @keyframe = options.keyframe
      $(document).on 'click', @clickedOutside

    showRollover: ->
      type = @model.get 'type'
      unit = @model.get 'unit'

      bubble = new Bubble
        type: 'rollover'
        text: 'indicator_exp'
        targetElement: @$el
        position: 'left'
        positionTopReference: @$el
        customClass: 'indicator'
        templateData:
          acronym: I18n.t('indicators', type, 'short')
          description: I18n.t('indicators', type, 'full')
          unit: I18n.t('units', unit, 'full')

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    render: ->
      super
      @updateSelected()

    getTemplateData: ->
      data = super

      # Get other units and filter by currency
      type = @model.get 'type'
      units = TypeData.indicator_types[type].units
      currency = @keyframe.get 'currency'
      units = _.reject units, (unit) ->
        not Currency.isVisible(unit.key, currency)
      data.units = units

      data

    toggleMenu: (show) ->
      @$('.unit-selector-menu').toggle show
      @$('a.unit-selector').toggleClass('open', show)

    hideMenu: ->
      @toggleMenu false

    unitSelectorClicked: (event) ->
      event.preventDefault()
      @toggleMenu()

    unitClicked: (event) ->
      event.preventDefault()

      newUnit = $(event.target).parent().data('unit-key')

      twus = @keyframe.get 'indicator_types_with_unit'
      twus = _(twus).map (twu) =>
        if twu[0] is @model.get('type')
          [twu[0], newUnit]
        else
          twu

      @toggleMenu false

      @keyframe.set(indicator_types_with_unit: twus).fetch()

    clickedOutside: (event) =>
      $parents = $(event.target).parents()
      menu = @$('.unit-selector-menu')
      outsideMenu = $parents.index(menu) is -1
      outsideButton = @$('a.unit-selector').get(0) isnt event.target
      if outsideMenu and outsideButton
        @hideMenu()

    updateSelected: ->
      @$("li[data-unit-key=#{@model.get('unit')}]").addClass('active')

    dispose: ->
      return if @disposed
      $(document).off 'click', @clickedOutside
      super
