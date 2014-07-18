define [
  'display_objects/chart'
  'views/legend_view'
  'lib/i18n'
  'lib/utils'
], (Chart, LegendView, I18n, utils) ->

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
    # showTitles: Boolean
    # format: String
    # legendView: View
    # $title: jQuery

    constructor: (options) ->
      console.log 'RenderAgent#constructor', options

      @presentation = options.presentation
      @keyframeIndex = options.keyframeIndex
      @showLegend = options.showLegend
      @showTitles = options.showTitles
      @format = options.format

      @$el = $('.render')
      # Apply class before rendering the chart
      # so the chart gets the correct width
      @$el.addClass 'has-legend' if @showLegend

      @keyframes = @presentation.getKeyframes().toArray()
      if keyframeIndex?
        @keyframeQueue = [keyframeIndex]
      else
        @keyframeQueue = [0...@keyframes.length]

      console.log 'RenderAgent#constructor queue', @keyframeQueue
      @drawChart()

    $: (selector) ->
      @$el.find selector

    drawChart: ->
      console.log 'RenderAgent#drawChart'
      @chart = new Chart(
        container: $('.chart').get(0)
        animationDuration: 0
        format: @format
        customFont: false
      )
      return

    drawKeyframe: (keyframeIndex) ->
      keyframe = @keyframes[keyframeIndex]
      console.log 'RenderAgent#drawKeyframe', keyframeIndex, keyframe
      @drawTitle keyframe
      @drawLegend keyframe if @showLegend
      @chart.update {keyframe}
      timeout = 200
      console.log "RenderAgent#drawKeyframe: Called chart.update(). Wait #{timeout}ms."
      utils.after timeout, =>
        @notifyDrawComplete keyframeIndex
        return
      return

    drawTitle: (keyframe) ->
      header = @$('> .header')
      title = keyframe.get 'title'
      console.log 'drawTitle', @showTitles, title

      if @showTitles and title.length
        header.show()
        header.find('.title').text title

        type = keyframe.get('data_type_with_unit')[0]
        year = keyframe.get 'year'
        text = I18n.t('data_type', type) + ' ' + year
        header.find('.relation').text text
      else
        header.hide()
      return

    drawLegend: (keyframe) ->
      @legendView.dispose() if @legendView

      @legendView = new LegendView
        model: keyframe
        presentation: @presentation
        container: '#page-container'
        staticChart: true
        partsVisibility:
          sources: true
          explanations: true
          about: false

      @legendView.open()

      return

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
      return

    drawNext: =>
      keyframeIndex = @keyframeQueue.shift()
      console.log 'RenderAgent#drawNext', keyframeIndex, 'remaining:', @keyframeQueue
      @drawKeyframe keyframeIndex
      return
