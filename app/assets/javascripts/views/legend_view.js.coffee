define (require) ->
  'use strict'
  _ = require 'underscore'
  configuration = require 'configuration'
  View = require 'views/base/view'
  Colors = require 'lib/colors'
  magnetColors = require 'lib/magnet_colors'
  Currency = require 'lib/currency'
  I18n = require 'lib/i18n'
  numberFormatter = require 'lib/number_formatter'
  TypeData = require 'lib/type_data'

  t = I18n.t

  # Unit representations
  REPRESENTATIONS = [
    'absolute'
    'percent'
  ]

  # Constants
  OPENED_CLASS = 'opened'
  CLOSED_CLASS = 'closed'

  class LegendView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe
    # presentation: Presentation
    # staticChart: Boolean
    # partsVisibility: Object

    tagName: 'section'
    templateName: 'legend'

    className: 'legend'

    autoRender: true

    events:
      'click .toggle-button': 'toggleButtonClicked'
      'click .info-button': 'infoButtonClicked'
      'click .close-button': 'closeButtonClicked'

    initialize: (options) ->
      super

      @presentation = options.presentation
      @staticChart = options.staticChart or false

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
      if @$el.hasClass(OPENED_CLASS)
        @close()
      else
        @open()

    infoButtonClicked: (event) ->
      event.preventDefault()
      @open()
      return

    closeButtonClicked: (event) ->
      event.preventDefault()
      @close()
      return

    close: ->
      @$('.toggle-button').text t('legend', 'toggle_open')
      @$el.addClass(CLOSED_CLASS).removeClass(OPENED_CLASS)
      return

    open: ->
      @$('.toggle-button').text t('legend', 'toggle_close')
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
      isEuro = data.currency is 'eur'

      data.staticChart = @staticChart
      data.partsVisibility = @partsVisibility

      # Sources
      if @partsVisibility.sources
        data.allSources = @getAllSources()
        data.dataSource = @getDataSource()
        data.indicatorSources = @getIndicatorSources()
        if isEuro
          data.exchangeRateSource = @getExchangeRateSource()

      # Explanations
      if @partsVisibility.explanations
        colors = magnetColors typeKey
        data.magnetOutgoingColor = colors.outgoing
        data.magnetIncomingColor = colors.incoming
        data.indicators = @getIndicators()
        if isEuro
          data.usd_in_eur_current = @getEuroRate unitKey, data.year
          # Fixed rate for real values (base 2005)
          data.usd_in_eur_constant = @getEuroRate unitKey, 2005

      # About
      if @partsVisibility.about
        data.id = @presentation.id
        data.data_changed = @presentation.get 'data_changed'
        data.data_version = @presentation.get 'data_version'
        data.latest_data_version = configuration.latest_data_version

      data

    # All sources (data, indicators, currency) as an array or strings
    getAllSources: ->
      sources = []
      # Data
      typeKey = @getTypeKey()
      sources.push t('sources', 'data', typeKey).split(';')[0]
      # Indicators
      for twu in @model.get('indicator_types_with_unit')
        typeKey = twu[0]
        sources.push t('sources', 'indicator', typeKey).split(';')[0]
      # Currency
      if @model.get('currency') is 'eur'
        sources.push t('sources', 'exchange_rate', 'usd_eur').split(';')[0]
      _.uniq sources

    getDataSource: ->
      typeKey = @getTypeKey()
      [name, url] = t('sources', 'data', typeKey).split(';')
      {name, url}

    getIndicatorSources: ->
      sources = []
      for twu in @model.get('indicator_types_with_unit')
        typeKey = twu[0]
        indicatorName =  t 'indicators', typeKey, 'short'
        [name, url] = t('sources', 'indicator', typeKey).split(';')
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
          type: t('indicators', twu[0], 'short')
          maxValue: I18n.template(
            ['units', twu[1], 'with_value']
            number: numberFormatter.formatNumber(maxValue, 2, false, true)
          )
        }

      # Group by representation (absolute, relative…)
      _(indicators).groupBy (i) -> i.representation

    getExchangeRateSource: ->
      [name, url] = t('sources', 'exchange_rate', 'usd_eur').split(';')
      {name, url}

    getEuroRate: (unitKey, year) ->
      numberFormatter.formatNumber Currency.getExchangeRate(unitKey, year), 4

    getTypeKey: ->
      @model.get('data_type_with_unit')[0]

    dispose: ->
      return if @disposed
      delete @presentation
      super
