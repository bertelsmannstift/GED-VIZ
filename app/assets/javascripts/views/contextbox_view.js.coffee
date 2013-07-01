define [
  'underscore'
  'views/base/view'
  'lib/utils'
  'lib/i18n'
], (_, View, utils, I18n) ->
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
        amount: utils.formatValue(info.amount, info.dataType, info.unit)
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

          targets = if toCountries.length > 1
            _.initial(toCountries).join(
              I18n.t('contextbox', 'relation', 'missing', 'enumSeparator')
            ) +
            I18n.t('contextbox', 'relation', 'missing', 'enumSeparatorLast') +
            _.last(toCountries)
          else
            toCountries[0]

          text += I18n.template(
            ['contextbox', 'relation', 'missing', 'entry']
            source: I18n.t('country_names', fromCountry)
            targets: targets
          )

        text += '</ul>'

      @showBox text

    handleShowEventForMagnet: (info) ->
      text = '<p>'
      text += I18n.template(
        ['contextbox', 'magnet', info.dataType]
        amountIn: utils.formatValue(info.amountIn, info.dataType, info.unit)
        amountOut: utils.formatValue(info.amountOut, info.dataType, info.unit)
        unit: I18n.t('units', info.unit, 'full')
        name: info.name
        year: info.year
      )
      text += '</p>'

      if info.noIncoming.length > 0
        noIncoming = info.noIncoming.map (iso3) ->
          I18n.t('country_names', iso3)

        elements = if noIncoming.length > 1
          _.initial(noIncoming).join(
            I18n.t('contextbox', 'magnet', 'missing', 'enumSeparator')
          ) +
          I18n.t('contextbox', 'magnet', 'missing', 'enumSeparatorLast') +
          _.last(noIncoming)
        else
          noIncoming[0]

        text += '<p>'
        text += I18n.template(
          ['contextbox', 'magnet', 'missing', 'incoming', info.dataType]
          list: elements
        )
        text += '</p>'

      if info.noOutgoing.length > 0
        noOutgoing = _(info.noOutgoing).map (iso3) ->
          I18n.t('country_names', iso3)

        elements = if noOutgoing.length > 1
          _.initial(noOutgoing).join(
            I18n.t('contextbox', 'magnet', 'missing', 'enumSeparator')
          ) +
          I18n.t('contextbox', 'magnet', 'missing', 'enumSeparatorLast') +
          _.last(noOutgoing)
        else
          noOutgoing[0]

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
      @$el.css 'top', headerHeight + 5 if headerHeight?

      @$el.html(html).addClass('visible')

    handleHideEvent: ->
      @$el.removeClass 'visible'
