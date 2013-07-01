define [
  'jquery'
  'views/base/view'
  'lib/i18n'
  'lib/currency'
  'lib/type_data'
], ($, View, I18n, Currency, TypeData) ->
  'use strict'

  class DataView extends View

    templateName: 'keyframe_configuration/data'

    tagName: 'section'
    className: 'data'

    events:
      'change input[type=radio]': 'unitChanged'

    initialize: ->
      super
      @listenTo @model, 'change:currency', @modelUpdated
      @listenTo @model, 'change:data_type_with_unit', @modelUpdated

    render: ->
      super
      @modelUpdated()
      this

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
        $input.parent().css 'display', if visible then '' else 'none'

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
      $radio
        .parent().addClass('active')
        .siblings().removeClass('active')
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
      data.TypeData = TypeData
      data