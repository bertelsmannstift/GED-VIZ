define [
  'views/base/view'
  'views/sharing_view'
  'views/keyframe_configuration_view'
  'views/keyframes_view'
  'views/keyframe_year_view'
  'views/contextbox_view'
  'display_objects/chart'
  'display_objects/static_chart'
  'views/legend_view'
  'lib/i18n'
  'lib/support'
], (View, SharingView, KeyframeConfigurationView, KeyframesView,
    KeyframeYearView, ContextboxView, Chart, StaticChart, LegendView,
    I18n, support) ->
  'use strict'

  class PlayerView extends View

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
      'click .fullscreen': 'toggleFullscreen'
      'mouseenter .nav-left.enabled, .nav-right.enabled, .fullscreen, .logo': 'showTooltip'
      'mouseleave .nav-left, .nav-right, .fullscreen, .logo': 'hideTooltip'

    initialize: ->
      super
      keyframes = @getKeyframes()
      if keyframes
        @listenTo keyframes, 'reset', @keyframesReplaced
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

    # Navigation

    moveToFirstKeyframe: (event) ->
      event?.preventDefault()
      @currentKeyframeIndex = 0
      @update()
      return

    moveToNextKeyframe: (event) ->
      event?.preventDefault()
      unless @atLastKeyframe()
        @currentKeyframeIndex++
        @update()
      return

    moveToPreviousKeyframe: (event) ->
      event?.preventDefault()
      unless @atFirstKeyframe()
        @currentKeyframeIndex--
        @update()
      return

    # Auto-play

    togglePlay: (event) ->
      event?.preventDefault()
      if @isPlaying()
        @stopPlay()
      else
        @startPlay()
      return

    startPlay: ->
      @moveToFirstKeyframe() if @atLastKeyframe()

      @playTimer = setInterval =>
        unless @atLastKeyframe()
          @moveToNextKeyframe()
        if @atLastKeyframe()
          @stopPlay()
      , 5000
      @$('> .footer .nav-play').addClass 'stop'
      return

    stopPlay: ->
      clearInterval @playTimer
      delete @playTimer
      @$('> .footer .nav-play').removeClass 'stop'
      return

    isPlaying: ->
      @playTimer?

    # Fullscreen

    isFullScreen: ->
      document.fullScreen or document.mozFullScreen or
      document.webkitIsFullScreen or document.msIsFullScreen

    enableFullScreen: ->
      if @el.requestFullscreen
        @el.requestFullscreen()
      else if @el.mozRequestFullScreen
        @el.mozRequestFullScreen()
      else if @el.webkitRequestFullScreen
        @el.webkitRequestFullScreen()
      else if @el.msRequestFullScreen
        @el.msRequestFullScreen()
      else
        options = 'fullscreen=yes,menubar=no,location=no,toolbar=no,status=no'
        window.open location.href, '_blank', options
      return

    disableFullScreen: ->
      if document.exitFullscreen
        document.exitFullscreen()
      else if document.mozCancelFullScreen
        document.mozCancelFullScreen()
      else if document.webkitCancelFullScreen
        document.webkitCancelFullScreen()
      else if document.msCancelFullScreen
        document.msCancelFullScreen()
      return

    toggleFullscreen: (event) ->
      event.preventDefault()
      if @isFullScreen()
        @disableFullScreen()
      else
        @enableFullScreen()
      return

    # Rendering
    # ---------

    render: ->
      super

      unless @shouldShowTitles()
        @$('> .header .title').hide()

      footer = @$('> .footer')
      playButton = footer.find '.nav-play'
      prevNextNavigation = footer.find '.nav-left, .nav-right'
      if @shouldAnimate()
        playButton.show()
        prevNextNavigation.hide()
      else
        playButton.hide()
        prevNextNavigation.show()

      @renderContextboxView()

      # Append to the DOM before creating the chart
      $('#page-container').append @el

      @createChart()

      if @getKeyframes().length > 0
        @initChart()

      return

    createChart: ->
      $container = @$('.chart')
      container = $container.get(0)
      if Chart.canUse
        @chart = new Chart {container}
      else
        @chart = new StaticChart {container, presentation: @model}
      # Development shortcut: register the chart instance as a module
      #define 'chart', @chart
      return

    renderLegend: ->
      keyframe = @getCurrentKeyframe()
      return unless keyframe and keyframe.get('countries').length

      container = @$('.chart')

      legendSources = new LegendView
        model: keyframe
        container: container
      legendSources.$el.addClass 'sources-only'
      @subview 'legendSources', legendSources

      legendExplanations = new LegendView
        model: keyframe
        container: container
      legendExplanations.$el.addClass 'explanations-only'
      @subview 'legendExplanations', legendExplanations

      return

    renderContextboxView: ->
      @subview 'contextbox', new ContextboxView(
        container: @el
      )
      return

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
      @updateNavigation()
      return

    initNumKeyframes: ->
      @$('.num-keyframes').text @getNumKeyframes()
      return

    getTemplateData: ->
      data = super
      data.editorUrl = @model.getEditorURL()
      data

    # General navigation
    # ------------------

    updateNavigation: ->
      header = @$('> .header')
      footer = @$('> .footer')

      keyframe = @getCurrentKeyframe()
      title = keyframe.get('title')
      [type, unit] = keyframe.get 'data_type_with_unit'
      year = keyframe.get 'year'

      # Update header
      header.find('.title').text title

      text = I18n.template ['player', 'title', type, 'year'], {year}
      header.find('.relation').text text

      unit = I18n.t 'units', unit, 'full'
      text = I18n.template ['player', 'title', type, 'unit'], {unit}
      header.find('.unit').text text

      footer.find('.current-index').text @currentKeyframeIndex + 1
      footer.find('.title').text title

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
      keyframe = @getKeyframe dotIndex
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
      title = keyframe.get 'title'

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
      @chart.dispose()
      super
