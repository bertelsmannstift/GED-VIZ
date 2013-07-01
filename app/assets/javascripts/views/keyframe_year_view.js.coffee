define [
  'underscore'
  'jquery'
  'views/base/view'
  'lib/utils'
  'lib/type_data'
  'lib/i18n'
  'models/bubble'
  'views/bubble_view'
], (_, $, View, utils, TypeData, I18n, Bubble, BubbleView) ->
  'use strict'

  MARKER_WIDTH = 40
  MARKER_HEIGHT = 10

  class KeyframeYearView extends View

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
      #console.log 'KeyframeYearView#initialize', @model
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
      currentYear = Number @model.get('year')
      years = @$('.year').map((index, elem) -> Number $(elem).text()).toArray()

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

      # Current year
      data.year = String data.year

      # Totals
      yearlyTotals = data.yearlyTotals = {}
      for year, value of data.yearly_totals when value > 0
        yearlyTotals[year] = value

      # Heights
      max = Math.max _(yearlyTotals).values()...
      data.heights = {}
      for year, value of yearlyTotals
        data.heights[year] = value / max * 100

      data

    render: ->
      super
      #console.log 'KeyframeYearView#render', @el, @el.parentNode
      content = @$('.nav, ul')
      if @model.get('countries').length < 1
        content.hide()
        return
      else
        content.show()
      @drawMarker()
      @drawArrows()
      @updateNavigation()
      return

    # Draw the marker arrow using Raphael
    drawMarker: ->
      #console.log 'KeyframeYearView#drawMarker', arrowContainer
      arrowContainer = @$('.current .arrow').get 0
      return unless arrowContainer
      Raphael(arrowContainer, MARKER_WIDTH, MARKER_HEIGHT)
        .path("M 0 #{MARKER_HEIGHT} 0 L #{MARKER_WIDTH / 2} 0 L #{MARKER_WIDTH} #{MARKER_HEIGHT} z")
        .attr(fill: '#2e2e2e', 'stroke-opacity': 0)
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
      number = utils.formatValue value, type, unit
      "#{number} #{I18n.t('units', unit, 'full')}"
