define [
  'jquery'
  'views/base/view'
  'lib/i18n'
], ($, View, I18n) ->
  'use strict'

  class SortCountriesView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    templateName: 'keyframe_configuration/sort_countries'
    className: 'sort-countries'
    autoRender: true

    defaultSorting: 'custom'

    events:
      'click .alphabetical': 'alphabeticalClicked'
      'click .custom':       'customClicked'
      'click .data-both':    'dataBothClicked'
      'click .data-in':      'dataInClicked'
      'click .data-out':     'dataOutClicked'
      'click .indicator':    'indicatorClicked'

    render: ->
      super
      element = @$(".#{@defaultSorting}")
      @updateCurrentSorting element, type: @defaultSorting

    getDataTwu: ->
      @model.get 'data_type_with_unit'

    customClicked: (event) ->
      event.preventDefault()
      # No-op

    # Alphabetical

    alphabeticalClicked: (event) ->
      event.preventDefault()
      @sort event.target, type: 'alphabetical'

    # Sort by unilateral data type

    dataBothClicked: (event) ->
      event.preventDefault()
      @sortByData event.target, direction: 'both'

    dataInClicked: (event) ->
      event.preventDefault()
      @sortByData event.target, direction: 'in'

    dataOutClicked: (event) ->
      event.preventDefault()
      @sortByData event.target, direction: 'out'

    # Helper for all data
    sortByData: (element, options) ->
      _.extend options,
        type: 'data'
        type_with_unit: @getDataTwu()
      @sort element, options

    # Sort by bilateral indicator type

    indicatorClicked: (event) ->
      event.preventDefault()
      $link = $(event.target)
      @sort event.target,
        type: 'indicator'
        type_with_unit: [
          $link.data('type'),
          $link.data('unit')
        ]

    sort: (element, options) ->
      @updateCurrentSorting element, options
      @trigger 'sort', options
      return

    updateCurrentSorting: (element, options) ->
      @$('li').removeClass 'active'
      $(element).closest('li').addClass 'active'

      key = switch options.type
        when 'custom'
          ['editor', 'custom_sorting']
        when 'alphabetical'
          ['editor', 'alphabetical_sorting']
        when 'data'
          dataType = options.type_with_unit[0]
          switch options.direction
            when 'both'
              ['data_type', dataType]
            when 'in'
              ['flow', dataType, 'incoming']
            when 'out'
              ['flow', dataType, 'outgoing']
        when 'indicator'
          type = options.type_with_unit[0]
          ['indicators', type, 'short']

      @$('.current-sorting').text I18n.t(key...)

      return
