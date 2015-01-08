define [
  'underscore'
  'jquery'
  'views/base/view'
  'views/sharing_view'
  'views/keyframe_configuration_view'
  'views/keyframes_view'
  'views/keyframe_year_view'
  'views/contextbox_view'
  'display_objects/chart'
  'display_objects/static_chart'
  'views/legend_view'
  'lib/fullscreen'
  'lib/i18n'
  'lib/scale'
  'lib/support'
], (
  _, $, View, SharingView, KeyframeConfigurationView, KeyframesView,
  KeyframeYearView, ContextboxView, Chart, StaticChart, LegendView,
  fullscreen, I18n, scale, support
) ->
  'use strict'

  class PlayerView extends View

    # Property declarations
    # ---------------------
    #
    # model: Presentation

    templateName: 'player'

    className: 'player'

    autoRender: true

    chart: null
    dots: null
    currentKeyframeIndex: 0

    events:
      'click .nav-left':  'moveToPreviousKeyframe'
      'click .nav-right': 'moveToNextKeyframe'
      'click .nav-play': 'togglePlay'
      'click .toggle-fullscreen': 'toggleFullscreen'
      'click .toggle-legend': 'toggleLegend'
      'mouseenter .nav-left.enabled, .nav-right.enabled, .toggle-legend, .toggle-fullscreen, .logo': 'showTooltip'
      'mouseleave .nav-left, .nav-right, .toggle-legend, .toggle-fullscreen, .logo': 'hideTooltip'

    initialize: ->
      super
      keyframes = @getKeyframes()
      if keyframes
        @listenTo keyframes, 'reset', @keyframesReplaced

      $(window).resize @resize
      return

    # Shortcuts
    # ---------

    getKeyframes: ->
      @model.get 'keyframes'

    getCurrentKeyframe: ->
      @getKeyframes()?.at @currentKeyframeIndex

    getNextKeyframe: ->
      @getKeyframes()?.at @currentKeyframeIndex + 1

    getPreviousKeyframe: ->
      @getKeyframes()?.at @currentKeyframeIndex - 1

    getKeyframe: (index) ->
      @getKeyframes().at index

    getNumKeyframes: ->
      @getKeyframes().length

    atFirstKeyframe: ->
      @currentKeyframeIndex < 1

    atLastKeyframe: ->
      @currentKeyframeIndex >= @getNumKeyframes() - 1

    shouldShowTitles: ->
      not /show_titles=0/.test(location.href)

    shouldAnimate: ->
      /animate=1/.test(location.href)

    # Event Handlers
    # --------------

    keyframesReplaced: ->
      @initChart() if @getKeyframes().length > 0

    resize: =>
      @renderLegend()
      return

    # Limit calls to resize
    @prototype.resize = _.debounce @prototype.resize, 300

    # Navigation

    documentKeydown: (event) =>
      switch event.keyCode
        when 37, 38
          @moveToPreviousKeyframe()
        when 39, 40, 32
          @moveToNextKeyframe()
        when 33, 36
          @moveToFirstKeyframe()
        when 34, 35
          @moveToLastKeyframe()
      return

    moveToFirstKeyframe: (event) ->
      event?.preventDefault()
      @currentKeyframeIndex = 0
      @update()
      return

    moveToLastKeyframe: (event) ->
      event?.preventDefault()
      @currentKeyframeIndex = @getNumKeyframes() - 1
      @update()
      return

    moveToNextKeyframe: (event) ->
      if event
        event.preventDefault()
      unless @atLastKeyframe()
        @currentKeyframeIndex++
        @update()
      return

    moveToPreviousKeyframe: (event) ->
      if event
        event.preventDefault()
      unless @atFirstKeyframe()
        @currentKeyframeIndex--
        @update()
      return

    # Auto-play

    togglePlay: (event) ->
      if event
        event.preventDefault()
      if @isPlaying()
        @stopPlay()
      else
        @startPlay()
      return

    startPlay: ->
      @moveToFirstKeyframe() if @atLastKeyframe()

      @playTimer = setInterval @playNext, 5000
      @$('> .footer .nav-play').addClass 'stop'
      return

    playNext: =>
      atLastKeyframe = @atLastKeyframe()
      if atLastKeyframe
        @stopPlay()
      else
        @moveToNextKeyframe()
      return

    stopPlay: ->
      clearInterval @playTimer
      delete @playTimer
      @$('> .footer .nav-play').removeClass 'stop'
      return

    isPlaying: ->
      @playTimer?

    # Legend

    toggleLegend: (event) ->
      event.preventDefault()
      legendView = @subview('legendAbout') or @subview('legend')
      legendView.toggle()
      return

    # Fullscreen

    toggleFullscreen: (event) ->
      event.preventDefault()
      if fullscreen.isFullScreen()
        fullscreen.exitFullscreen @el
      else
        fullscreen.requestFullscreen @el
      return

    # Rendering
    # ---------

    render: ->
      super

      @$chart = @$('.chart')

      unless @shouldShowTitles()
        @$('> .header .title').hide()

      @initAnimationControls()
      @renderContextboxView()

      # Observe document-wide key shortcuts
      $(document).keydown @documentKeydown

      # Append to the DOM before creating the chart
      $('#page-container').append @el

      @createChart()

      if @getKeyframes().length > 0
        @initChart()

      return

    initAnimationControls: ->
      footer = @$('> .footer')
      playButton = footer.find '.nav-play'
      prevNextNavigation = footer.find '.nav-left, .nav-right'
      if @shouldAnimate()
        playButton.show()
        prevNextNavigation.hide()
      else
        playButton.hide()
        prevNextNavigation.show()
      return

    createChart: ->
      container = @$chart.get 0
      if Chart.canUse
        @chart = new Chart {container}
      else
        @chart = new StaticChart {container, presentation: @model}
      @subview 'chart', @chart
      # Development shortcut: register the chart instance as a module
      #define 'chart', @chart
      return

    renderLegend: =>
      keyframe = @getCurrentKeyframe()
      return unless keyframe and keyframe.get('countries').length

      @removeSubview 'legendSources'
      @removeSubview 'legendExplanations'
      @removeSubview 'legendAbout'
      @removeSubview 'legend'

      if $(window).width() > 650
        # Three separate legends
        @createLegend name: 'legendSources', only: 'sources'
        @createLegend name: 'legendExplanations', only: 'explanations'
        @createLegend name: 'legendAbout', only: 'about', overlay: true
      else
        @createLegend name: 'legend', overlay: true

      return

    createLegend: (options) ->
      view = new LegendView
        model: @getCurrentKeyframe()
        presentation: @model
        container: @el
        only: options.only
        overlay: options.overlay
      @subview options.name, view
      return

    renderContextboxView: ->
      @subview 'contextbox', new ContextboxView(
        container: @el
      )
      return

    # Chart intialization and updating
    # --------------------------------

    initChart: ->
      # Check if the chart was created (weird IE6 timing bug)
      return unless @chart
      @initNumKeyframes()
      @initDots()
      @update()
      @startPlay() if @shouldAnimate()
      return

    update: ->
      keyframe = @getCurrentKeyframe()
      @chart.update {keyframe}
      @renderLegend()
      @updateControls()
      return

    initNumKeyframes: ->
      @$('.num-keyframes').text @getNumKeyframes()
      return

    getTemplateData: ->
      data = super
      data.editorUrl = @model.getEditorURL()
      data

    updateControls: ->
      keyframe = @getCurrentKeyframe()
      year = keyframe.get 'year'

      @updateHeader()

      # Year inside the chart
      @$('.current-year').text year

      @updateFooter()
      return

    updateHeader: ->
      header = @$('> .header')

      keyframe = @getCurrentKeyframe()
      title = keyframe.get 'title'
      subtitle = keyframe.getSubtitle()
      type = keyframe.get('data_type_with_unit')[0]
      year = keyframe.get 'year'

      header.find('.title').text title
      header.find('.relation').text subtitle
      return

    updateFooter: ->
      footer = @$('> .footer')

      keyframe = @getCurrentKeyframe()

      footer.find('.current-index').text @currentKeyframeIndex + 1
      footer.find('.title').text keyframe.getDisplayTitle()

      @updateNavButtons()
      @highlightSelectedDot()
      return

    updateNavButtons: ->
      footer = @$('> .footer')
      navLeft = footer.find '.nav-left'
      navRight = footer.find '.nav-right'

      if @atFirstKeyframe()
        navLeft.addClass('disabled').removeClass('enabled')
      else
        navLeft.addClass('enabled').removeClass('disabled')
        @updateTooltip navLeft.find('.tooltip'), @getPreviousKeyframe()

      if @atLastKeyframe()
        navRight.addClass('disabled').removeClass('enabled')
      else
        navRight.addClass('enabled').removeClass('disabled')
        @updateTooltip navRight.find('.tooltip'), @getNextKeyframe()
      return

    updateTooltip: ($tooltip, keyframe) ->
      nbsp = '\u00A0'
      unbreakText = (text) -> text.replace(/\s+/g, nbsp)
      title = keyframe.get('title') + ' '
      subtitle = keyframe.getSubtitle() + ' '

      $tooltip.find('.maintitle').text unbreakText(title)
      $tooltip.find('.subtitle').text  unbreakText(subtitle)
      $tooltip.find('img').attr src: @model.staticKeyframeImage(keyframe, 'thumb')
      return

    # We can’t use CSS :hover for this because we need to exclude Mobile Safari
    showTooltip: (event) ->
      # Don’t show the tooltip if it would prevent the click event
      return unless support.mouseover
      $(event.currentTarget).find('.tooltip').show()
      return

    hideTooltip: (event) ->
      # Don’t show the tooltip if it would prevent the click event
      return unless support.mouseover
      $(event.currentTarget).find('.tooltip').hide()
      return

    # Dot navigation
    # --------------

    dotSettings =
      activeRadius: 5.5
      inactiveRadius: 4
      activeColor: '#86dcff'
      inactiveColor: '#fff'
      spacing: 13

    initDots: ->
      @dots = []
      return unless Raphael.type

      dots = @$('.dots').get(0)
      numKeyframes = @getNumKeyframes()

      @dotPaper = Raphael dots, dotSettings.spacing * numKeyframes, 20
      for index in [0...numKeyframes]
        do (index) =>
          dot = @dotPaper
            .circle(
              dotSettings.spacing / 2 + (index * dotSettings.spacing),
              10,
              dotSettings.inactiveRadius
            )
            .attr(fill: dotSettings.inactiveColor, 'stroke-opacity': 0)
            .data('index', index)
            .hover(
              => @dotMouseIn dot
              ,
              => @dotMouseOut dot
            )
            .click(
              => @dotClick dot
            )
          @dots.push dot
          return
      return

    highlightSelectedDot: ->
      for dot, index in @dots
        if index is @currentKeyframeIndex
          dot.attr
            r: dotSettings.activeRadius
            fill: dotSettings.activeColor
        else
          dot.attr
            r: dotSettings.inactiveRadius
            fill: dotSettings.inactiveColor
      return

    dotMouseIn: (dot) ->
      # Don’t change the DOM if it would prevent the click event
      return unless support.mouseover
      dot.attr r: dotSettings.activeRadius
      dotIndex = dot.data 'index'
      @showDotTooltip dot
      return

    dotMouseOut: (dot) ->
      # Don’t change the DOM if it would prevent the click event
      return unless support.mouseover
      dotIndex = dot.data 'index'
      active = dotIndex is @currentKeyframeIndex
      if active
        dot.attr r: dotSettings.activeRadius
      else
        dot.attr r: dotSettings.inactiveRadius
      @hideDotTooltip()
      return

    dotClick: (dot) ->
      dotIndex = dot.data 'index'
      @currentKeyframeIndex = dotIndex
      @update()
      return

    showDotTooltip: (dot) ->
      dotIndex = dot.data 'index'
      keyframe = @getKeyframe(dotIndex)
      title = keyframe.getDisplayTitle()

      $tooltip = @$('.dots .tooltip')
      @updateTooltip $tooltip, keyframe
      dotOffset = dotSettings.spacing / 2 + (dotIndex * dotSettings.spacing)
      tooltipWidth = $tooltip.outerWidth()
      left = dotOffset - tooltipWidth / 2
      $tooltip.css
        display: 'block'
        left: "#{left}px"
      return

    hideDotTooltip: ->
      @$('.dots .tooltip').hide()
      return

    # Disposal
    # --------

    dispose: ->
      return if @disposed
      @stopPlay()
      $(document).off 'keypress', @documentKeydown
      $(window).off 'resize', @resize
      super
