define [
  'underscore'
  'views/base/view'
  'lib/i18n'
  'lib/utils'
  'lib/number_formatter'
], (_, View, I18n, utils, numberFormatter) ->
  'use strict'

  class ContextboxView extends View
    className: 'contextbox'
    autoRender: true

    initialize: ->
      super

      @subscribeEvent 'contextbox:explainRelation', @handleShowEventForRelation
      @subscribeEvent 'contextbox:explainMagnet', @handleShowEventForMagnet

      @subscribeEvent 'contextbox:hide', @handleHideEvent

    handleShowEventForRelation: (info) ->
      text = '<p>'
      text += I18n.template(
        ['contextbox', 'relation', info.dataType]
        from: info.fromName
        to: info.toName
        percentFrom: info.percentFrom
        percentTo: info.percentTo
        amount: numberFormatter.formatValue(
          info.amount, info.dataType, info.unit, true
        )
        unit: I18n.t('units', info.unit, 'full')
        year: info.year
      )
      text += '</p>'

      if info.missingRelations?
        text += '<p>' + I18n.t('contextbox', 'relation', 'missing', 'intro') + '</p>'
        text += '<ul>'

        for fromCountry, toCountries of info.missingRelations
          toCountries = _(toCountries).map (iso3) ->
            I18n.t('country_names', iso3)

          targets = @joinList toCountries

          text += '<li>'
          text += I18n.template(
            ['contextbox', 'relation', 'missing', 'entry']
            source: I18n.t('country_names', fromCountry)
            targets: targets
          )
          text += '</li>'

        text += '</ul>'

      @showBox text

    handleShowEventForMagnet: (info) ->
      text = '<p>'
      text += I18n.template(
        ['contextbox', 'magnet', info.dataType]
        amountIn: numberFormatter.formatValue(
          info.amountIn, info.dataType, info.unit, true
        )
        amountOut: numberFormatter.formatValue(
          info.amountOut, info.dataType, info.unit, true
        )
        unit: I18n.t('units', info.unit, 'full')
        name: info.name
        year: info.year
      )
      text += '</p>'

      if info.noIncoming.length > 0
        noIncoming = info.noIncoming.map (iso3) ->
          I18n.t('country_names', iso3)

        elements = @joinList noIncoming

        text += '<p>'
        text += I18n.template(
          ['contextbox', 'magnet', 'missing', 'incoming', info.dataType]
          list: elements
        )
        text += '</p>'

      if info.noOutgoing.length > 0
        noOutgoing = _(info.noOutgoing).map (iso3) ->
          I18n.t('country_names', iso3)

        elements = @joinList noOutgoing

        text += '<p>'
        text += I18n.template(
          ['contextbox', 'magnet', 'missing', 'outgoing', info.dataType]
          list: elements
        )
        text += '</p>'

      @showBox text

    showBox: (html) ->
      # When in editor, position below the header
      headerHeight = $('.header-and-keyframe-configuration').height()
      if headerHeight?
        chartYPosition = @$el.parent().offset().top
        diff = Math.abs chartYPosition - headerHeight
        @$el.css 'top', diff + 5

      @$el.html(html).addClass('visible')

    handleHideEvent: ->
      @$el.removeClass 'visible'

    # For a list of strings ['a', 'b', 'c'],
    # return a localized string 'a, b and c'.
    joinList: (elements) ->
      if elements.length > 1
        _.initial(elements).join(
          I18n.t('enum_separator')
        ) +
        I18n.t('enum_separator_last') +
        _.last(elements)
      else
        elements[0]

