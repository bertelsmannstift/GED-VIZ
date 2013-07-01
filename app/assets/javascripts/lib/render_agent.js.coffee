define [
  'display_objects/chart'
  'views/legend_view'
  'lib/utils'
], (Chart, LegendView, utils) ->

  # Manages communication between Phantom.js and the chart
  class RenderAgent

    # Property declarations
    # ---------------------
    #
    # chart: Chart
    # presentation: Presentation
    # keyframes: Array
    # keyframeQueue: Array
    # showLegend: Boolean
    # showTitle: Boolean
    # format: String
    # legendView: View
    # $title: jQuery

    constructor: (options) ->
      console.log 'RenderAgent#constructor', options

      @presentation = options.presentation
      @keyframeIndex = options.keyframeIndex
      @showLegend = options.showLegend
      @showTitle = options.showTitle
      @format = options.format

      @keyframes = @presentation.get('keyframes').toArray()
      if keyframeIndex?
        @keyframeQueue = [keyframeIndex]
      else
        @keyframeQueue = [0...@keyframes.length]

      console.log 'RenderAgent#constructor queue', @keyframeQueue
      @drawChart()

    drawChart: ->
      console.log 'RenderAgent#drawChart'
      $('.render').addClass 'has-legend' if @showLegend
      @chart = new Chart(
        container: $('.chart').get(0)
        animationDuration: 0
        format: @format
        customFont: false
      )

    drawKeyframe: (keyframeIndex) ->
      keyframe = @keyframes[keyframeIndex]
      console.log 'RenderAgent#drawKeyframe', keyframeIndex, keyframe
      @drawTitle keyframe.get('title') if @showTitle
      @drawLegend keyframe if @showLegend
      @chart.update {keyframe}
      timeout = 200
      console.log "RenderAgent#drawKeyframe: Called chart.update(). Wait #{timeout}ms."
      utils.after timeout, =>
        @notifyDrawComplete keyframeIndex

    drawTitle: (title) ->
      @$title ?= $('<div>').addClass('title').appendTo('.render')
      if title
        $title.text(title).show()
      else
        $title.hide()

    drawLegend: (keyframe) ->
      @legendView?.dispose()
      @legendView = new LegendView
        model: keyframe
        container: '#page-container'
        staticChart: true
      @legendView.$el.addClass('open').removeClass('closed')

    notifyDrawComplete: (keyframeIndex) ->
      finished = @keyframeQueue.length is 0
      console.log 'RenderAgent#notifyDrawComplete', keyframeIndex, 'finished?', finished
      if window.callPhantom?
        console.log 'RenderAgent#notifyDrawComplete: callPhantom'
        window.callPhantom
          keyframeDrawn: keyframeIndex
          finished: finished
      else
        console.log 'RenderAgent#notifyDrawComplete: Fake Phantom behavior', keyframeIndex, finished
        unless finished
          utils.after 1500, @drawNext
        else
          console.log 'RenderAgent#notifyDrawComplete: Phantom exiting'

    drawNext: =>
      keyframeIndex = @keyframeQueue.shift()
      console.log 'RenderAgent#drawNext', keyframeIndex, 'remaining:', @keyframeQueue
      @drawKeyframe keyframeIndex
