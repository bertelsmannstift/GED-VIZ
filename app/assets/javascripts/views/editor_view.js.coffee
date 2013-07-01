define [
  'underscore'
  'views/base/view'
  'views/editor_header_view'
  'views/keyframe_configuration_view'
  'views/keyframes_view'
  'views/sharing_view'
  'views/keyframe_currency_view'
  'views/keyframe_year_view'
  'views/contextbox_view'
  'views/loading_indicator_view'
  'display_objects/chart'
  'views/legend_view'
], (_, View, EditorHeaderView, KeyframeConfigurationView, KeyframesView,
    SharingView, KeyframeCurrencyView, KeyframeYearView, ContextboxView,
    LoadingIndicatorView, Chart, LegendView) ->
  'use strict'

  class EditorView extends View

    # Property declarations
    # ---------------------
    #
    # model: Presentation

    templateName: 'editor'
    className: 'editor'
    autoRender: true

    chart: null

    initialize: ->
      super
      @listenTo @model, 'change:keyframe', @keyframeReplaced
      $(window).on 'resize', @adjustKeyframeListHeight

    # Rendering
    # ---------

    render: ->
      super

      # Render subviews which do not bind to the keyframe
      @renderEditorHeaderView()
      @renderKeyframesView()
      @renderSharingView()

      @renderContextboxView()
      @renderLoadingIndicatorView()

      # Append to DOM before creating the chart
      $('#page-container').append @el
      @createChart()

    # Keyframe change handler
    # -----------------------

    keyframeReplaced: (editor, newKeyframe) ->
      oldKeyframe = @model.previous 'keyframe'

      # Setup keyframe to chart binding
      if oldKeyframe
        @stopListening oldKeyframe, 'change', @keyframeChanged
      @listenTo newKeyframe, 'change', @keyframeChanged

      # Render subviews which bind to the keyframe
      @renderKeyframeConfigurationView()
      @renderKeyframeYearView()
      @renderKeyframeCurrencyView()

      if newKeyframe.get('elements')
        @updateChart()
        @renderLegend()

      @adjustKeyframeListHeight()

    keyframeChanged: (keyframe, options) ->
      # Only update the chart when specific attributes were changed
      changes = keyframe.changedAttributes()

      if changes
        if changes.elements
          @updateChart()
          @renderLegend()
        if changes.indicator_types_with_unit or changes.countries
          @adjustKeyframeListHeight()

      return

    # Subviews which do not bind to the keyframe
    # ------------------------------------------

    renderEditorHeaderView: ->
      @subview 'editor_header', new EditorHeaderView(
        model: @model
        container: @$('.header-and-keyframe-configuration')
        autoRender: true
      )
      return

    renderKeyframesView: ->
      @subview 'keyframes', new KeyframesView(
        model: @model
        container: @$('.bottom-right')
        autoRender: true
      )
      return

    renderSharingView: ->
      @subview 'sharing', new SharingView(
        model: @model.getPresentation()
        container: @$('.bottom-right')
        # Renders itself when some keyframes have been captured
      )
      return

    renderContextboxView: ->
      @subview 'contextbox', new ContextboxView(container: @el)
      return

    renderLoadingIndicatorView: ->
      @subview 'loadingIndicator', new LoadingIndicatorView(container: @el)
      return

    # Subviews which bind to the keyframe
    # -----------------------------------

    renderKeyframeConfigurationView: ->
      view = new KeyframeConfigurationView
        model: @model.getKeyframe()
        container: @$('.header-and-keyframe-configuration')
        autoRender: true
      @listenTo view, 'add_indicator'
      @subview 'keyframe_configuration', view
      return

    renderKeyframeYearView: ->
      @subview 'year', new KeyframeYearView(
        model: @model.getKeyframe()
        container: @el
      )
      return

    renderKeyframeCurrencyView: ->
      @subview 'currency', new KeyframeCurrencyView(
        model: @model.getKeyframe()
        container: @el
      )
      return

    # Chart
    # -----

    createChart: ->
      @chart = new Chart(
        container: @$('.chart').get(0)
      )
      return

    updateChart: ->
      keyframe = @model.getKeyframe()
      yOffset = @getYOffset()
      @chart.update {keyframe, yOffset}
      return

    getYOffset: ->
      headerHeight = @$('.header-and-keyframe-configuration').height()
      chartTop = parseInt @$('.chart').css('top'), 10
      yOffset = headerHeight - chartTop
      yOffset = 0 if yOffset < 0
      yOffset

    # Legend
    # ------

    renderLegend: ->
      @removeSubview 'legendSources'
      @removeSubview 'legendExplanations'

      keyframe = @model.getKeyframe()
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

    # Resize handler
    # --------------

    adjustKeyframeListHeight: =>
      keyframe =  @model.getKeyframe()
      headerHeight = @$('.header-and-keyframe-configuration').height()
      sharingHeight = @$('.sharing').height()
      viewportHeight = $(document).height()
      maxHeight = viewportHeight - headerHeight - sharingHeight - 70
      @$('.bottom-right .keyframes ul').css 'max-height', maxHeight
      return

    # Limit calls to adjustKeyframeListHeight
    adjustKeyframeListHeight: _.debounce(
      @prototype.adjustKeyframeListHeight, 100
    )

    dispose: ->
      return if @disposed
      $(window).off 'resize', @adjustKeyframeListHeight
      super
