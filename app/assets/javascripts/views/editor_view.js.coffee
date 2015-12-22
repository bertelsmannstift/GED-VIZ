define (require) ->
  'use strict'
  _ = require 'underscore'
  Raphael = require 'raphael'
  support = require 'lib/support'
  View = require 'views/base/view'
  EditorHeaderView = require 'views/editor_header_view'
  KeyframeConfigurationView = require 'views/keyframe_configuration_view'
  KeyframesView = require 'views/keyframes_view'
  SharingView = require 'views/sharing_view'
  KeyframeCurrencyView = require 'views/keyframe_currency_view'
  KeyframeYearView = require 'views/keyframe_year_view'
  ContextboxView = require 'views/contextbox_view'
  LoadingIndicatorView = require 'views/loading_indicator_view'
  LegendView = require 'views/legend_view'
  OutdatedDataView = require 'views/outdated_data_view'
  OutdatedBrowserView = require 'views/outdated_browser_view'
  Chart = require 'display_objects/chart'

  class EditorView extends View

    # Property declarations
    # ---------------------
    #
    # model: Editor

    templateName: 'editor'
    className: 'editor'
    autoRender: true

    chart: null

    initialize: ->
      super
      @listenTo @model, 'change:keyframe', @keyframeReplaced
      $(window).resize @adjustKeyframeListHeight

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

      @renderOutdatedDataView()
      @renderOutdatedBrowserView()

      this

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

    keyframeChanged: (keyframe) ->
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
        container: @$('.sidebar')
        autoRender: true
      )
      return

    renderSharingView: ->
      @subview 'sharing', new SharingView(
        model: @model.getPresentation()
        container: @$('.sidebar')
        # Renders itself when some keyframes have been captured
      )
      return

    renderContextboxView: ->
      @subview 'contextbox', new ContextboxView(
        container: @$('.chart')
      )
      return

    renderLoadingIndicatorView: ->
      @subview 'loadingIndicator', new LoadingIndicatorView(
        container: @$('.chart')
      )
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

      presentation = @model.getPresentation()
      keyframe = @model.getKeyframe()
      return unless keyframe and keyframe.get('countries').length

      chartElement = @$('.chart')

      legendSources = new LegendView
        model: keyframe
        presentation: presentation
        container: chartElement
        only: 'sources'
      @subview 'legendSources', legendSources

      legendExplanations = new LegendView
        model: keyframe
        presentation: presentation
        container: chartElement
        only: 'explanations'
      @subview 'legendExplanations', legendExplanations

      return

    # Outdated data dialog
    # --------------------

    renderOutdatedDataView: ->
      if @model.getPresentation().get('data_changed')
        @subview 'outdatedData', new OutdatedDataView({@model})
      return

    # Outdated browser dialog
    # -----------------------

    renderOutdatedBrowserView: ->
      unless Raphael.type is 'SVG'
        @subview 'outdatedBrowser', new OutdatedBrowserView()
      return

    # Resize handler
    # --------------

    adjustKeyframeListHeight: =>
      keyframe =  @model.getKeyframe()
      headerHeight = @$('.header-and-keyframe-configuration').height()
      sharingHeight = @$('.sharing').height()
      viewportHeight = $(document).height()
      maxHeight = viewportHeight - headerHeight - sharingHeight - 70
      @$('.sidebar .keyframes ul').css 'max-height', maxHeight
      return

    # Limit calls to adjustKeyframeListHeight
    @prototype.adjustKeyframeListHeight = _.debounce(
      @prototype.adjustKeyframeListHeight, 100
    )

    dispose: ->
      return if @disposed
      $(window).off 'resize', @adjustKeyframeListHeight
      super
