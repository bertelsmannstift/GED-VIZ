define [
  'lib/type_data'
  'lib/i18n'
  'models/bubble'
  'views/base/view'
  'views/bubble_view'
  'jquery'
], (TypeData, I18n, Bubble, View, BubbleView, $) ->
  'use strict'

  class CountryContextView extends View

    templateName: 'keyframe_configuration/country_context'
    className: 'country-context'
    autoRender: true

    events:
      'click li': 'buttonClicked'

      'mouseenter li': 'showRollover'
      'mouseleave li': 'hideRollover'

    initialize: ->
      super
      @listenTo @model,
        'change:data_type_with_unit change:indicator_types_with_unit',
        @render

    # Notification bubbles
    # --------------------

    showRollover: (event) ->
      $li = $(event.target).closest 'li'

      # Only show rollovers for disabled actions.
      return unless $li.hasClass 'disabled'

      if $li.hasClass 'group'
        text = ['country_context', 'group']
      else if $li.hasClass 'ungroup'
        text = ['country_context', 'ungroup']
      else if $li.hasClass 'rename-group'
        text = ['country_context', 'rename_group']
      else if $li.hasClass 'related'
        text = ['country_context', 'top5']

      return unless text

      bubble = new Bubble
        type: 'rollover'
        text: text
        targetElement: $li
        position: 'left'
        positionTopReference: $li

      @subview 'rollover', new BubbleView(model: bubble)
      return

    hideRollover: ->
      @removeSubview 'rollover'
      return

    # Showing and hiding
    # ------------------

    toggle: (selectedCountries, usedCountries) ->
      if @$('.options').css('display') is 'none'
        @show selectedCountries, usedCountries
      else
        @hide()

    # Update and show
    show: (selectedCountries, usedCountries) ->
      @update selectedCountries, usedCountries
      @$el.addClass 'open'
      @$('.options').show()

    # Enable/disable buttons according to the used and selected countries
    update: (@selectedCountries, usedCountries) ->
      #console.log 'CountryContextView#update', selectedCountries, usedCountries

      countriesUsed = usedCountries.length > 0
      countriesSelected = selectedCountries.length > 0
      multipleSelected = selectedCountries.length > 1
      allSelected = selectedCountries.length is usedCountries.length
      groupSelected = selectedCountries.length is 1 and selectedCountries[0].isGroup

      buttonStates =
        '.select-all': countriesUsed
        '.unselect-all': countriesSelected
        '.group': multipleSelected
        '.ungroup': groupSelected
        '.rename-group': groupSelected
        '.remove': countriesSelected
        '.clear': countriesUsed
        '.related': countriesSelected

      for selector, enabled of buttonStates
        @$(selector).toggleClass 'disabled', not enabled

      return

    hide: ->
      @$el.removeClass 'open'
      @$('.options').hide()

    # Event handlers
    # --------------

    buttonClicked: (event) ->
      event.preventDefault()
      @hideRollover(event)
      #console.log 'CountryContextView#buttonClicked'

      $li = $(event.currentTarget)
      return if $li.hasClass 'disabled'

      @hide()

      if $li.hasClass 'select-all'
        @trigger 'selectAll'

      else if $li.hasClass 'unselect-all'
        @trigger 'unselectAll'

      else if $li.hasClass 'group'
        defaultTitle = I18n.t 'editor', 'default_group_title'
        title = prompt(
          I18n.t('editor', 'enter_group_title'),
          defaultTitle
        )
        if title isnt null
          title = defaultTitle if title is ''
          @trigger 'group', @selectedCountries, title

      else if $li.hasClass 'ungroup'
        @trigger 'ungroup', @selectedCountries[0]

      else if $li.hasClass 'rename-group'
        countryGroup = @selectedCountries[0]
        oldTitle = countryGroup.get('title')
        title = prompt I18n.t('editor', 'enter_new_group_title'), oldTitle
        if title and title isnt oldTitle
          @trigger 'renameGroup', countryGroup, title

      else if $li.hasClass 'remove'
        @trigger 'remove', @selectedCountries

      else if $li.hasClass 'clear'
        @trigger 'clear'

      else if $li.hasClass 'related'
        country = @selectedCountries[0]
        direction = $(event.target).data 'direction'
        @trigger 'addRelated', country, direction

      return