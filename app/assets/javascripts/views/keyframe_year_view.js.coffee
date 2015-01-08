define [
  'underscore'
  'jquery'
  'models/bubble'
  'views/base/view'
  'views/bubble_view'
  'lib/i18n'
  'lib/number_formatter'
], (_, $, Bubble, View, BubbleView, I18n, numberFormatter) ->
  'use strict'

  class KeyframeYearView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    templateName: 'keyframe_year'

    className: 'keyframe-year'

    autoRender: true

    events:
      'click li': 'yearClicked'
      'click .next': 'nextClicked'
      'click .prev': 'prevClicked'
      'mouseenter li': 'showYearRollover'
      'mouseleave li': 'hideYearRollover'
      'mouseenter .prev': 'showNavigationRollover'
      'mouseleave .prev': 'hideNavigationRollover'
      'mouseenter .next': 'showNavigationRollover'
      'mouseleave .next': 'hideNavigationRollover'

    initialize: ->
      super
      @listenTo @model, 'change:yearly_totals change:year change:data_type_with_unit',
        @render

    # Navigation
    # ----------

    yearClicked: (event) =>
      year = Number $(event.currentTarget).find('.year').text()
      @model.set {year}
      @model.fetch()

    nextClicked: (event) ->
      event.preventDefault()
      return if $(event.currentTarget).hasClass('disabled')
      year = @model.get 'year'
      @model.set year: year + 1
      @model.fetch()

    prevClicked: (event) ->
      event.preventDefault()
      return if $(event.currentTarget).hasClass('disabled')
      year = @model.get 'year'
      @model.set year: year - 1
      @model.fetch()

    updateNavigation: ->
      currentYear = String @model.get('year')
      years = _(@model.get('yearly_totals')).keys()
      @$('.prev').toggleClass 'disabled', currentYear is years[0]
      @$('.next').toggleClass 'disabled', currentYear is years[years.length - 1]
      return

    # Rollovers
    # ---------

    showYearRollover: (event) ->
      $li = $(event.currentTarget)

      type = @model.get('data_type_with_unit')[0]
      year = Number $li.data('year')
      number = @formatValue @model.get('yearly_totals')[year]

      bubble = new Bubble
        type: 'rollover'
        text: ['year_list', type]
        templateData: {year, number}
        targetElement: $li
        position: 'above'
        positionLeftReference: $li
        customClass: 'year-list'

      @subview 'yearRollover', new BubbleView(model: bubble)
      return

    hideYearRollover: ->
      @removeSubview 'yearRollover'
      return

    showNavigationRollover: (event) ->
      year = @model.get 'year'
      button = $(event.currentTarget)
      key = if button.hasClass('prev')
        'previous_year'
      else
        'next_year'

      bubble = new Bubble
        type: 'rollover'
        text: ['year_list', key]
        targetElement: button
        position: 'above'
        positionLeftReference: @$('.nav')

      @subview 'navigationRollover', new BubbleView(model: bubble)

    hideNavigationRollover: (event) ->
      @removeSubview 'navigationRollover'
      return

    # Rendering
    # ---------

    getTemplateData: ->
      data = super

      # Current year as string
      data.year = String data.year

      # Totals
      data.yearlyTotals = data.yearly_totals
      yearlyTotals = data.yearlyTotals

      # Heights
      max = Math.max _(yearlyTotals).values()...
      data.heights = {}
      for year, value of yearlyTotals
        data.heights[year] = if max > 0
          value / max * 100
        else
          100

      data

    render: ->
      super
      @drawArrows()
      @updateNavigation()
      return

    # Draw the navigation arrows using Raphael
    drawArrows: ->
      container = @$('.next').get 0
      Raphael(container, 10, 20)
        .path('M 0 0 L 10 10 L 0 20 z')
        .attr(fill: '#2e2e2e', 'stroke-opacity': 0)

      container = @$('.prev').get 0
      Raphael(container, 10, 20)
        .path('M 10 0 L 0 10 L 10 20 z')
        .attr(fill: '#2e2e2e', 'stroke-opacity': 0)
      return

    formatValue: (value) ->
      [type, unit] = @model.get 'data_type_with_unit'
      number = numberFormatter.formatValue value, type, unit, true
      "#{number} #{I18n.t('units', unit, 'full')}"
