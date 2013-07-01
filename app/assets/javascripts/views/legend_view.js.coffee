define [
  'underscore'
  'lib/utils'
  'lib/i18n'
  'lib/type_data'
  'lib/colors'
  'lib/currency'
  'views/base/view'
], (_, utils, I18n, TypeData, Colors, Currency, View) ->
  'use strict'

  # Unit representations
  REPRESENTATIONS = [
    'absolute'
    'percent'
    'ranking'
  ]

  class LegendView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    templateName: 'legend'

    className: 'legend'

    autoRender: true

    events:
      'click .toggle-button': 'toggleButtonClicked'
      'click .info-button': 'infoButtonClicked'
      'click .close-button': 'closeButtonClicked'

    toggleButtonClicked: (event) ->
      event.preventDefault()
      if @$el.hasClass('open')
        @close()
      else
        @open()

    infoButtonClicked: (event) ->
      event.preventDefault()
      @open()

    closeButtonClicked: (event) ->
      event.preventDefault()
      @close()

    close: ->
      @$('.toggle-button').text I18n.t('legend', 'toggle_open')
      @$el.addClass('closed').removeClass('open')

    open: ->
      @$('.toggle-button').text I18n.t('legend', 'toggle_close')
      @$el.addClass('open').removeClass('closed')

    render: ->
      super if @model
      @close()

    getTemplateData: ->
      data = super
      [typeKey, unitKey] = data.data_type_with_unit
      data.staticChart = @options.staticChart
      data.magnetOutgoingColor = Colors.magnets[typeKey].outgoing
      data.magnetIncomingColor = Colors.magnets[typeKey].incoming
      # Sources
      data.allSources = @getAllSources()
      data.dataSource = @getDataSource()
      data.indicatorSources = @getIndicatorSources()
      # Indicators
      data.indicators = @getIndicators()
      # Currency
      if data.currency is 'eur'
        data.exchangeRateSource = @getExchangeRateSource()
        data.usd_in_eur_current = @getEuroRate unitKey, data.year
        # Fixed rate for real values (base 2005)
        data.usd_in_eur_constant = @getEuroRate unitKey, 2005
      data

    # All sourcs (data, indicators, currency) as an array or strings
    getAllSources: ->
      sources = []
      # Data
      typeKey = @model.get('data_type_with_unit')[0]
      sources.push I18n.t('sources', 'data', typeKey).split(';')[0]
      # Indicators
      for twu in @model.get('indicator_types_with_unit')
        typeKey = twu[0]
        sources.push I18n.t('sources', 'indicator', typeKey).split(';')[0]
      # Currency
      if @model.get('currency') is 'eur'
        sources.push I18n.t('sources', 'exchange_rate', 'usd_eur').split(';')[0]
      _.uniq sources

    getDataSource: ->
      typeKey = @model.get('data_type_with_unit')[0]
      [name, url] = I18n.t('sources', 'data', typeKey).split(';')
      {name, url}

    getIndicatorSources: ->
      sources = []
      for twu in @model.get('indicator_types_with_unit')
        typeKey = twu[0]
        indicatorName =  I18n.t 'indicators', typeKey, 'short'
        [name, url] = I18n.t('sources', 'indicator', typeKey).split(';')
        source = _(sources).find (source) -> source.name is name
        unless source
          source = name: name, url: url, indicators: []
          sources.push source
        source.indicators.push indicatorName
      sources

    # Indicators grouped by representation
    getIndicators: ->
      indicators = _(@model.get('indicator_types_with_unit')).map (twu) =>
        unit = TypeData.units[twu[1]]
        maxValue = @model.getIndicatorMaxValue twu
        {
          representation: REPRESENTATIONS[unit.representation]
          twu: twu
          type: I18n.t('indicators', twu[0], 'short')
          maxValue: I18n.template(
            ['units', twu[1], 'with_value']
            number: utils.formatNumber(maxValue)
          )
        }

      # Group by representation (absolute, relative…)
      _(indicators).groupBy (i) -> i.representation

    getExchangeRateSource: ->
      [name, url] = I18n.t('sources', 'exchange_rate', 'usd_eur').split(';')
      {name, url}

    getEuroRate: (unitKey, year) ->
      utils.formatNumber Currency.getExchangeRate(unitKey, year), 4
