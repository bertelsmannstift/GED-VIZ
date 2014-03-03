define [
  'underscore'
  'views/base/view'
  'lib/colors'
  'lib/currency'
  'lib/i18n'
  'lib/number_formatter'
  'lib/type_data'
], (_, View, Colors, Currency, I18n, numberFormatter, TypeData) ->
  'use strict'

  # Unit representations
  REPRESENTATIONS = [
    'absolute'
    'percent'
    'ranking'
  ]

  # Constants
  OPENED_CLASS = 'opened'
  CLOSED_CLASS = 'closed'

  class LegendView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    tagName: 'section'
    templateName: 'legend'

    className: 'legend'

    autoRender: true

    events:
      'click .toggle-button': 'toggleButtonClicked'
      'click .close-button': 'closeButtonClicked'

    initialize: (options) ->
      # Visibility of the parts
      if options.partsVisibility
        partsVisibility = options.partsVisibility
      else if options.only
        partsVisibility = sources: false, explanations: false, about: false
        partsVisibility[options.only] = true
        @$el.addClass options.only + '-only'
      else
        partsVisibility = sources: true, explanations: true, about: true
      @partsVisibility = partsVisibility

      # Overlay mode
      @$el.addClass 'overlay' if options.overlay

      return

    toggleButtonClicked: (event) ->
      event.preventDefault()
      @toggle()
      return

    closeButtonClicked: (event) ->
      event.preventDefault()
      @close()
      return

    close: ->
      @$('.toggle-button').text I18n.t('legend', 'toggle_open')
      @$el.addClass(CLOSED_CLASS).removeClass(OPENED_CLASS)
      return

    open: ->
      @$('.toggle-button').text I18n.t('legend', 'toggle_close')
      @$el.addClass(OPENED_CLASS).removeClass(CLOSED_CLASS)
      return

    toggle: ->
      if @$el.hasClass(OPENED_CLASS)
        @close()
      else
        @open()
      return

    render: ->
      super if @model
      @close()
      this

    getTemplateData: ->
      data = super
      [typeKey, unitKey] = data.data_type_with_unit
      data.staticChart = @options.staticChart
      data.partsVisibility = @partsVisibility

      if @partsVisibility.sources
        data.allSources = @getAllSources()
        data.dataSource = @getDataSource()
        data.indicatorSources = @getIndicatorSources()

      if @partsVisibility.explanations
        data.magnetOutgoingColor = Colors.magnets[typeKey].outgoing
        data.magnetIncomingColor = Colors.magnets[typeKey].incoming
        data.indicators = @getIndicators()

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
            number: numberFormatter.formatNumber(maxValue, 2, false, true)
          )
        }

      # Group by representation (absolute, relative…)
      _(indicators).groupBy (i) -> i.representation

    getExchangeRateSource: ->
      [name, url] = I18n.t('sources', 'exchange_rate', 'usd_eur').split(';')
      {name, url}

    getEuroRate: (unitKey, year) ->
      numberFormatter.formatNumber Currency.getExchangeRate(unitKey, year), 4
