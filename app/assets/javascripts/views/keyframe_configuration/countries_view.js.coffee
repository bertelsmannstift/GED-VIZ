define (require) ->
  'use strict'
  $ = require 'jquery'
  Collection = require 'models/base/collection'
  Bubble = require 'models/bubble'
  View = require 'views/base/view'
  CountryContextView = require 'views/keyframe_configuration/country_context_view'
  SortCountriesView = require 'views/keyframe_configuration/sort_countries_view'
  CountryPickerView = require 'views/keyframe_configuration/country_picker_view'
  UsedCountriesView = require 'views/keyframe_configuration/used_countries_view'
  BubbleView = require 'views/bubble_view'
  SortCountriesRequest = require 'lib/sort_countries_request'
  RelatedCountriesRequest = require 'lib/related_countries_request'

  class CountriesView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe
    # usedCountries: Collection
    # _usedIsos: Array
    #   Cached list of ISO3 codes for the used countries

    templateName: 'keyframe_configuration/countries'

    tagName: 'section'
    className: 'countries'

    events:
      'click .country-context .toggle-button': 'toggleCountryContext'
      'click .add-countries-button': 'toggleCountryPicker'
      'click .sort-used-countries .change-sorting': 'toggleSortCountries'

      'mouseenter .sort-used-countries .current-sorting': 'showSortRollover'
      'mouseleave .sort-used-countries .current-sorting': 'hideSortRollover'

    initialize: ->
      super
      @listenTo @model, 'change:countries', @countriesChanged
      $(document).on 'click', @clickedOutside

      # Wrap the countries into a collection
      @usedCountries = new Collection @model.get('countries')

    # Sort rollover
    # ---------------

    showSortRollover: ->
      $sortUsedCountries = @$('.sort-used-countries')
      return if $sortUsedCountries.hasClass('open')

      target = $sortUsedCountries.find('.current-sorting')
      bubble = new Bubble
        type: 'rollover'
        text: 'country_sort_by'
        targetElement: target
        position: 'below'
        positionRightReference: target

      @subview 'sortRollover', new BubbleView(model: bubble)
      return

    hideSortRollover: ->
      @removeSubview 'sortRollover'
      return

    # Toggle subviews
    # ---------------

    # Country context

    toggleCountryContext: (event) ->
      event.preventDefault()
      @publishEvent 'counties:toggleContext', this
      selectedCountries = @subview('usedCountries').getSelectedCountries()
      @subview('countryContext').toggle selectedCountries, @usedCountries

    hideCountryContext: ->
      @subview('countryContext').hide()

    # Sort countries

    toggleSortCountries: (event) ->
      event.preventDefault()
      @hideSortRollover()
      @$('.sort-used-countries .sort-options').toggle()
      @$('.sort-used-countries').toggleClass 'open'

    hideSortCountries: ->
      @$('.sort-used-countries .sort-options').hide()
      @$('.sort-used-countries').removeClass 'open'

    # Country picker

    toggleCountryPicker: (event) ->
      event.preventDefault()
      @subview('countryPicker').toggle()

    hideCountryPicker: ->
      @subview('countryPicker').hide()

    # Hide subviews automatically

    clickedOutside: (event) =>
      $parents = $(event.target).parents()

      # Country context
      el = @subview('countryContext').el
      outsideView = $parents.index(el) is -1
      if outsideView
        @hideCountryContext()

      # Sort countries
      el = @subview('sortCountries').el
      outsideView = $parents.index(el) is -1
      if outsideView
        @hideSortCountries()

      # Country picker
      el = @subview('countryPicker').el
      outsideView = $parents.index(el) is -1
      outsideButton =
        @$('.add-countries-button').get(0) isnt event.target
      if outsideView and outsideButton
        @hideCountryPicker()

    # Rendering
    # ---------

    render: ->
      super

      # Country context
      # ---------------

      view = new CountryContextView
        model: @model
        container: @$('.country-context-container')
      @listenTo view, 'selectAll', @selectAllCountries
      @listenTo view, 'unselectAll', @unselectAllCountries
      @listenTo view, 'group', @groupCountries
      @listenTo view, 'ungroup', @ungroupCountries
      @listenTo view, 'renameGroup', @renameGroup
      @listenTo view, 'remove', @removeCountries
      @listenTo view, 'clear', @clearCountries
      @listenTo view, 'addRelated', @addRelatedCountries
      @subview 'countryContext', view

      # Sort countries
      # --------------

      view = new SortCountriesView
        model: @model
        container: @$('.sort-used-countries')
      @listenTo view, 'sort', @sortCountries
      @subview 'sortCountries', view

      # Re-render the view when types or countries change
      @listenTo(
        @model,
        'change:countries change:data_type_with_unit change:indicator_types_with_unit',
        @renderSortCountriesView
      )

      # Country picker
      # --------------

      view = new CountryPickerView
        model: @model
        container: @$('.country-picker-container')
      view.filter @countryFilterer
      @listenTo view, 'add', @addCountry
      @listenTo view, 'addMultiple', @addCountries
      @listenTo view, 'addGroup', @addGroup
      @listenTo view, 'close', @hideCountryPicker
      @subview 'countryPicker', view

      # Used countries
      # --------------

      view = new UsedCountriesView
        collection: @usedCountries
        container: @$('.used-countries-container')
      @listenTo view, 'remove', @removeCountry
      @listenTo view, 'move', @moveCountry
      @subview 'usedCountries', view

    renderSortCountriesView: (keyframe, changes, options) ->
      # Do not re-render after sorting
      unless options.sorting
        @subview('sortCountries').render()
      return

    # Filtering
    # ---------

    countryFilterer: (country) =>
      # Accept the country if it is not already used
      country.get('iso3') not in @usedIsos()

    refilter: ->
      delete @_usedIsos
      @subview('countryPicker').refilter()

    usedIsos: ->
      return @_usedIsos if @_usedIsos
      isos = {}
      @usedCountries.each (countryOrGroup) ->
        if countryOrGroup.isGroup
          for country in countryOrGroup.get('countries')
            isos[country.get('iso3')] = true
        else
          isos[countryOrGroup.get('iso3')] = true
        return
      usedIsos = _(isos).keys()
      @_usedIsos = usedIsos
      usedIsos

    # Country context events
    # ----------------------

    selectAllCountries: ->
      @subview('usedCountries').selectAllCountries()

    unselectAllCountries: ->
      @subview('usedCountries').unselectAllCountries()

    groupCountries: (countries, title) ->
      @model.groupCountries countries, title
      @refilter()

    ungroupCountries: (group) ->
      @model.ungroupCountries group
      @refilter()

    renameGroup: (group, title) ->
      @model.renameGroup group, title

    removeCountries: (countries) ->
      for country in countries
        @model.removeCountry country
      @refilter()

    clearCountries: ->
      @model.clearCountries()
      @refilter()

    addRelatedCountries: (country, direction) ->
      promise = RelatedCountriesRequest.send {
        country
        direction
        year: @model.get('year')
        data_type_with_unit: @model.get('data_type_with_unit')
      }
      promise.then (sortedCountries) =>
        @model.addCountries sortedCountries
        @refilter()
      return

    # Sort countries events
    # ---------------------

    sortCountries: (options) ->
      options.countries = @usedCountries.toArray()
      options.year = @model.get 'year'
      promise = SortCountriesRequest.send options
      promise.then (sortedCountries) =>
        @model.resetCountries sortedCountries, sorting: true
        @refilter()
      @hideSortCountries()
      return

    # Country picker events
    # ---------------------

    addCountry: (country) ->
      @model.addCountry country
      @hideCountryPicker()
      @refilter()

    addCountries: (countries) ->
      @model.addCountries countries
      @hideCountryPicker()
      @refilter()

    addGroup: (group) ->
      @addCountry group
      @refilter()

    # Used countries events
    # ---------------------

    removeCountry: (country) ->
      @subview('usedCountries').hide country
      @model.removeCountry country
      @refilter()

    moveCountry: (oldIndex, newIndex) ->
      @model.moveCountry oldIndex, newIndex
      @refilter()

    # React to keyframe changes
    # -------------------------

    countriesChanged: (keyframe, countries) ->
      @usedCountries.reset countries
      @refilter()

    dispose: ->
      return if @disposed
      @usedCountries.dispose()
      delete @usedCountries
      $(document).off 'click', @clickedOutside
      super
