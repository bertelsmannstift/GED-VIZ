define [
  'underscore'
  'views/base/view'
  'lib/currency'
  'models/bubble'
  'views/bubble_view'
], (_, View, Currency, Bubble, BubbleView) ->
  'use strict'

  class KeyframeCurrencyView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    templateName: 'keyframe_currency'

    className: 'keyframe-currency'

    autoRender: true

    events:
      'change input[type=radio]': 'currencyChanged'
      'mouseenter li': 'showRollover'
      'mouseleave li': 'hideRollover'

    showRollover: (event) ->
      $li = $(event.currentTarget)
      currency = $li.data 'currency'
      bubble = new Bubble
        type: 'rollover'
        text: ['currencies', currency]
        targetElement: $li
        position: 'above'
        positionLeftReference: $li

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    getTemplateData: ->
      data = super
      data.currencies = Currency.currencies()
      data

    currencyChanged: (event) ->
      $radio = $(event.target)
      currency = $radio.val()
      if @model
        @model.set {currency}
        Currency.adjustUnits @model
        @model.fetch()
      @activateItem $radio
      return

    activateItem: ($radio) ->
      $radio
        .closest('li').addClass('active')
        .siblings().removeClass('active')
      return
