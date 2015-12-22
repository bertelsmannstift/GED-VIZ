define (require) ->
  'use strict'
  _ = require 'underscore'
  View = require 'views/base/view'
  I18n = require 'lib/i18n'
  utils = require 'lib/utils'
  numberFormatter = require 'lib/number_formatter'

  {t, template, joinList} = I18n

  countryWithArticle = _.partial(
    t, 'country_names_with_articles'
  )
  countryWithPrepositionAndArticle = _.partial(
    t, 'country_names_with_preposition_and_article'
  )

  class ContextboxView extends View
    className: 'contextbox'
    autoRender: true

    initialize: ->
      super
      @subscribeEvent 'contextbox:explainRelation', @explainRelation
      @subscribeEvent 'contextbox:explainMagnet', @explainMagnet
      @subscribeEvent 'contextbox:hide', @handleHideEvent

    explainRelation: (options) ->
      {from, to, amount} = options
      {dataType, unit} = from
      formattedUnit = t 'units', unit, 'full'

      percentFrom = numberFormatter.formatValue(
        (100 / from.sumOut * amount).toFixed(1),
        'percentage', 'percent', true
      ) + '%'
      percentTo = numberFormatter.formatValue(
        (100 / to.sumIn * amount).toFixed(1),
        'percentage', 'percent', true
      ) + '%'

      formattedAmount = numberFormatter.formatValue(
        amount, dataType, unit, true
      )

      templateData =
        from: from.name
        from_with_article: from.nameWithArticle
        from_with_preposition_and_article: from.nameWithPrepositionAndArticle
        from_adjective_plural: from.nameAdjectivePlural
        to: to.name
        to_with_article: to.nameWithArticle
        to_with_preposition_and_article: to.nameWithPrepositionAndArticle
        to_adjective_plural: to.nameAdjectivePlural
        percentFrom: percentFrom
        percentTo: percentTo
        amount: formattedAmount
        unit: formattedUnit
        year: from.year
        data_type: t('data_type', dataType)

      text = '<p>'
      text += template ['contextbox', 'relation', dataType], templateData
      text += '</p>'

      # Missing relations
      if options.missingRelations
        text += '<p>' + t('contextbox', 'relation', 'missing', 'intro') + '</p>'
        text += '<ul>'
        for fromCountry, toCountries of options.missingRelations
          templateData =
            source: countryWithArticle(fromCountry)
            source_with_preposition_and_article:
              countryWithPrepositionAndArticle(fromCountry)
            targets: joinList(_(toCountries).map(countryWithArticle))

          text += '<li>'
          text += template(
            ['contextbox', 'relation', 'missing', 'entry']
            templateData
          )
          text += '</li>'
        text += '</ul>'

      @showBox text
      return

    explainMagnet: (element) ->
      {dataType} = element
      templateData =
        name: element.name
        name_with_article: element.nameWithArticle
        name_with_preposition_and_article:
          element.nameWithPrepositionAndArticle
        name_adjective_plural: element.nameAdjectivePlural
        amountIn: numberFormatter.formatValue(
          element.sumIn, dataType, element.unit, true
        )
        amountOut: numberFormatter.formatValue(
          element.sumOut, dataType, element.unit, true
        )
        unit: t('units', element.unit, 'full')
        year: element.year
        data_type: t('data_type', dataType)

      text = '<p>'
      text += template ['contextbox', 'magnet', dataType], templateData
      text += '</p>'

      # Missing incoming relations
      if element.noIncoming.length > 0
        noIncoming = _(element.noIncoming).map countryWithArticle
        text += '<p>'
        text += template(
          ['contextbox', 'magnet', 'missing', 'incoming', dataType]
          list: joinList(noIncoming)
        )
        text += '</p>'

      # Missing outgoing relations
      if element.noOutgoing.length > 0
        noOutgoing = _(element.noOutgoing).map countryWithArticle
        text += '<p>'
        text += template(
          ['contextbox', 'magnet', 'missing', 'outgoing', dataType]
          list: joinList(noOutgoing)
        )
        text += '</p>'

      @showBox text
      return

    showBox: (html) ->
      # When in editor, position below the header
      headerHeight = $('.header-and-keyframe-configuration').height()
      if headerHeight?
        chartYPosition = @$el.parent().offset().top
        diff = Math.abs chartYPosition - headerHeight
        @$el.css 'top', diff + 5

      @$el.html(html).addClass('visible')
      return

    handleHideEvent: ->
      @$el.removeClass 'visible'
      return
