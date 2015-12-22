define (require) ->
  'use strict'
  $ = require 'jquery'
  Model = require 'models/base/model'
  Bubble = require 'models/bubble'
  View = require 'views/base/view'
  BubbleView = require 'views/bubble_view'
  PromptView = require 'views/prompt_view'
  I18n = require 'lib/i18n'
  TypeData = require 'lib/type_data'

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
    update: (selectedCountries, usedCountries) ->
      countriesUsed = usedCountries.length > 0
      @selectedCountries = selectedCountries
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

      $li = $(event.currentTarget)
      return if $li.hasClass 'disabled'

      @hide()

      if $li.hasClass 'select-all'
        @trigger 'selectAll'

      else if $li.hasClass 'unselect-all'
        @trigger 'unselectAll'

      else if $li.hasClass 'group'
        @groupCountries()

      else if $li.hasClass 'ungroup'
        @trigger 'ungroup', @selectedCountries[0]

      else if $li.hasClass 'rename-group'
        @renameGroup()

      else if $li.hasClass 'remove'
        @trigger 'remove', @selectedCountries

      else if $li.hasClass 'clear'
        @trigger 'clear'

      else if $li.hasClass 'related'
        country = @selectedCountries[0]
        direction = $(event.target).data 'direction'
        @trigger 'addRelated', country, direction

      return

    groupCountries: ->
      defaultTitle = I18n.t 'editor', 'default_group_title'
      success = (title) =>
        title = defaultTitle if title is ''
        @trigger 'group', @selectedCountries, title
        return
      model = new Model
        label: I18n.t('editor', 'enter_group_title')
        default: defaultTitle
        success: success
      @subview 'prompt', new PromptView {model}
      return

    renameGroup: ->
      countryGroup = @selectedCountries[0]
      oldTitle = countryGroup.get 'title'
      success = (title) =>
        if title and title isnt oldTitle
          @trigger 'renameGroup', countryGroup, title
        return
      model = new Model
        label: I18n.t('editor', 'enter_new_group_title')
        default: oldTitle
        success: success
      @subview 'prompt', new PromptView {model}
      return