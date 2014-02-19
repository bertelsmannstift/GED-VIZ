define [
  'models/base/collection'
  'models/country_group'
  'models/bubble'
  'views/base/view'
  'views/bubble_view'
  'views/keyframe_configuration/available_country_groups_view'
  'views/keyframe_configuration/available_countries_view'
  'views/keyframe_configuration/sort_countries_view'
  'lib/i18n'
  'lib/sort_countries_request'
  'lib/type_data'
], (
  Collection, CountryGroup, Bubble,
  View, BubbleView, AvailableCountryGroupsView, AvailableCountriesView,
  SortCountriesView,
  I18n, SortCountriesRequest, TypeData
) ->
  'use strict'

  class CountryPickerView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe
    # allCountries: Array
    # availableCountries: Collection
    #   The list of countries shown in the results section on the right side
    # allCountriesGroup: CountryGroup
    #   A group with all countries
    # availableCountryGroups: Collection
    #   Collection of predefined country groups shown in the query section
    #   on the left side
    # selectedGroup: CountryGroup
    #   The group which was selected from the group list on the left side

    templateName: 'keyframe_configuration/country_picker'

    className: 'country-picker'

    autoRender: true

    events:
      # Search field
      'focus .search-field': 'searchFieldFocussed'
      'keyup .search-field': 'searchFieldKeyup'

      # Sorting
      'click .change-sorting': 'toggleSortOptions'

      # Actions

      'click .add-all-countries': 'addAllCountries'
      'mouseenter .add-all-countries': 'showAddAllRollover'
      'mouseleave .add-all-countries': 'hideRollover'

      'click .add-as-group': 'addAllAsGroup'
      'mouseenter .add-as-group': 'showAddGroupRollover'
      'mouseleave .add-as-group': 'hideRollover'

      'click .add-remaining-as-group': 'addRemainingAsGroup'
      'mouseenter .add-remaining-as-group': 'showAddRemainingRollover'
      'mouseleave .add-remaining-as-group': 'hideRollover'

    initialize: ->
      super
      @listenTo @model, 'change:countries', @refilter

      # Array with all countries ordered by name
      @allCountries = _(TypeData.countries)
        .chain()
        .values()
        .sortBy((country) -> country.name())
        .value()

      # Initialize the results with all countries
      @availableCountries = new Collection @allCountries

      # Create groups collection
      title = I18n.t 'editor', 'all_countries_group'
      @allCountriesGroup = CountryGroup.build {countries: @allCountries, title}
      groups = [@allCountriesGroup].concat TypeData.country_groups
      @availableCountryGroups = new Collection groups

    # Rendering
    # ---------

    render: ->
      super

      # Available country groups
      # ------------------------

      view = new AvailableCountryGroupsView
        collection: @availableCountryGroups
        container: @$('.available-country-groups-container')
      @listenTo view, 'select', @groupSelected
      @subview 'availableCountryGroups', view

      # Sort countries
      # --------------

      view = new SortCountriesView
        model: @model
        container: @$('.sort-countries-container')
        defaultSorting: 'alphabetical'
      @listenTo view, 'sort', @sortCountries
      @subview 'sortCountries', view

      # Re-render the view when keyframe types change
      @listenTo(
        @model,
        'change:data_type_with_unit change:indicator_types_with_unit',
        @renderSortCountriesView
      )
      # Re-render the view when results change
      @listenTo @availableCountries, 'reset', @availableCountriesReset

      # Available countries
      # -------------------

      view = new AvailableCountriesView
        collection: @availableCountries
        container: @$('.available-countries-container')
      # Pass add events from collection view
      @listenTo view, 'add', (country) ->
        @trigger 'add', country
      @subview 'availableCountries', view

      # Focus the search field
      @$('.search').addClass 'active-query'

      return

    availableCountriesReset: (collection, options) ->
      # Do not re-render after sorting
      @renderSortCountriesView() unless options.sorting
      return

    renderSortCountriesView: ->
      @subview('sortCountries').render()
      return

    # Visibility
    # ----------

    toggle: ->
      if @$el.css('display') is 'none'
        @$el.show()
        unless @selectedGroup
          @$('.search-field').focus().select()
      else
        @$el.hide()
      return

    hide: ->
      @$el.hide()
      return

    # Filtering
    # ---------

    filter: (filterer) ->
      @countryFilterer = filterer
      @subview('availableCountries').filter filterer
      @updateActions()
      @updateMarker()

    refilter: ->
      @filter @countryFilterer

    getFilteredCountries: ->
      @availableCountries.filter @countryFilterer

    # Rollover stuff
    # --------------

    showAddAllRollover: ->
      filteredCount = @getFilteredCountries().length
      return if filteredCount > 0

      target = @$('.add-all-countries')
      bubble = new Bubble
        type: 'rollover'
        text: 'picker_add_all'
        targetElement: target
        position: 'left'
        positionTopReference: target

      @subview 'rollover', new BubbleView(model: bubble)
      return

    showAddGroupRollover: ->
      filteredCount = @getFilteredCountries().length
      allCount = @availableCountries.length
      return unless filteredCount < 2 or filteredCount isnt allCount

      target = @$('.add-as-group')
      bubble = new Bubble
        type: 'rollover'
        text: 'picker_as_group'
        targetElement: target
        position: 'left'
        positionTopReference: target

      @subview 'rollover', new BubbleView(model: bubble)
      return

    showAddRemainingRollover: ->
      filteredCount = @getFilteredCountries().length
      allCount = @availableCountries.length
      return unless filteredCount is 0 or not @selectedGroup or filteredCount is allCount

      target = @$('.add-remaining-as-group')
      bubble = new Bubble
        type: 'rollover'
        text: 'picker_remaining'
        targetElement: target
        position: 'left'
        positionTopReference: target

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    # Event handlers
    # --------------

    groupSelected: (countryGroup, view) ->
      @selectedGroup = countryGroup

      # Update results
      countries = countryGroup.get 'countries'
      countries = _(countries).sortBy (country) -> country.name()
      @availableCountries.reset countries

      # Mark the group on the left
      @$('.search, .available-country-group').removeClass 'active-query'
      view.$el.addClass 'active-query'
      @$('.search-field').val ''

      @updateMarker()
      @updateActions()

    searchFieldFocussed: ->
      @$('.available-country-group').removeClass 'active-query'
      @$('.search').addClass 'active-query'
      @search @$('.search-field').val()

    searchFieldKeyup: (event) ->
      value = event.target.value

      # Add the first available country on enter key
      if value and event.keyCode is 13
        firstCountry = @availableCountries.filter(@countryFilterer)[0]
        @trigger 'add', firstCountry if firstCountry
        return

      # Close on escape key
      if event.keyCode is 27
        @trigger 'close'
        return

      @search value

    search: (value) ->
      @selectedGroup = null
      query = ///#{value}///i
      countries = _(@allCountries).filter (country) ->
        query.test(country.get('iso3')) or query.test(country.name())
      @availableCountries.reset countries
      @updateMarker()
      @updateActions()

    # When searching, mark the first available result
    updateMarker: ->
      view = @subview 'availableCountries'
      view.$('li').removeClass 'current'
      unless @selectedGroup
        view.$('li:not(.disabled)').first().addClass 'current'

    # Sorting
    # -------

    toggleSortOptions: (event) ->
      event.preventDefault()
      @$('.sort-options').slideToggle 300

    sortCountries: (options) ->
      options.countries = @availableCountries.toArray()
      options.year = @model.get 'year'
      promise = SortCountriesRequest.send options
      promise.then (sortedCountries) =>
        @availableCountries.reset sortedCountries, sorting: true
      @$('.sort-options').slideUp 300
      return

    # Action buttons and their event handlers
    # ---------------------------------------

    updateActions: ->
      allCount = @availableCountries.length
      filteredCount = @getFilteredCountries().length

      @$('.add-all-countries').toggleClass 'disabled',
        filteredCount is 0 or not @selectedGroup

      @$('.add-as-group').toggleClass 'disabled',
        filteredCount < 2 or filteredCount isnt allCount

      @$('.group-name').text(
        if @selectedGroup then @selectedGroup.name() else ''
      )

      @$('.add-remaining-as-group').toggleClass 'disabled',
        filteredCount is 0 or not @selectedGroup or filteredCount is allCount

    addAllCountries: (event) ->
      event.preventDefault()
      @hideRollover()
      @trigger 'addMultiple', @getFilteredCountries()

    addAllAsGroup: (event) ->
      event.preventDefault()
      @hideRollover()
      # Create a new country group
      title = if @selectedGroup
        @selectedGroup.get 'title'
      else
        prompt I18n.t('editor', 'enter_group_title'), ''
      countries = @getFilteredCountries()
      countryGroup = CountryGroup.build {countries, title}
      @trigger 'addGroup', countryGroup

    addRemainingAsGroup: (event) ->
      event.preventDefault()
      @hideRollover()
      return unless @selectedGroup
      title = I18n.template(
        ['editor', 'rest_of_group']
        title: @selectedGroup.get('title')
      )
      countries = @getFilteredCountries()
      countryGroup = CountryGroup.build {countries, title}
      @trigger 'addGroup', countryGroup

    # Disposal
    # --------

    dispose: ->
      return if @disposed
      for prop in ['availableCountries', 'availableCountryGroups']
        @[prop].dispose()
        delete @[prop]
      super
