define (require) ->
  'use strict'
  _ = require 'underscore'
  $ = require 'jquery'
  View = require 'views/base/view'
  Currency = require 'lib/currency'
  I18n = require 'lib/i18n'
  TypeData = require 'lib/type_data'

  class DataView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    templateName: 'keyframe_configuration/data'

    tagName: 'section'
    className: 'data'

    events:
      'change input[type=radio]': 'unitChanged'
      'click .main-type-opener': 'openDerivedTypes'

    initialize: ->
      super
      @listenTo @model, 'change:currency', @modelUpdated
      @listenTo @model, 'change:data_type_with_unit', @modelUpdated

      $(document).on 'click', @clickedOutside

    render: ->
      super
      @modelUpdated()
      this

    openDerivedTypes: (event) ->
      $elem = $(event.target)

      return unless $elem.parents('.derived-types').length is 0

      unless $elem.hasClass('main-type-opener')
        $elem = $elem.parents('.main-type-opener')

      $elem.toggleClass('open')

    modelUpdated: ->
      return unless @model
      @$('input').prop 'checked', false
      [type, unit] = @model.get 'data_type_with_unit'
      $radio = @$("input[data-type=#{type}][data-unit=#{unit}]")
      $radio.prop 'checked', true
      @activateItem $radio
      @updateUnit unit

      # Hide units of wrong currency
      @$('input').each (index, element) =>
        $input = $(element)
        unit = $input.data 'unit'
        visible = Currency.isVisible unit, @model.get('currency')
        $input.parents('.main-type-container').css 'display', if visible then '' else 'none'

      return

    unitChanged: (event) =>
      $radio = $(event.target)
      type = $radio.data 'type'
      unit = $radio.data 'unit'

      if @model
        @model.set data_type_with_unit: [type, unit]
        @model.fetch()
      @activateItem $radio
      @updateUnit unit
      return

    activateItem: ($radio) ->
      $('.main-type, .derived-type').removeClass('active')
      $('.main-type-opener').removeClass('open')

      $radio.siblings('.main-type').addClass('active')

      if ($radio.data('text')?)
        $radio.siblings('.derived-type').addClass('active')
        $radio.parents('.main-type-opener').find('.main-type').addClass('active').text($radio.data('text'))

      return

    updateUnit: (unit) ->
      html = I18n.template(
        ['editor', 'shown_in']
        unit: I18n.t('units', unit, 'full')
      )
      @$('.unit').html html
      return

    getTemplateData: ->
      data = super
      data.dataTypes = _.groupBy TypeData.data_types, (dataType) -> dataType.parent or 'root'
      data

    clickedOutside: (event)->
      $elem = $('.main-types')
      $parents = $(event.target).parents()

      # Country context
      outsideView = $parents.index($elem) is -1

      if outsideView
        $('.main-type-opener').removeClass('open')

