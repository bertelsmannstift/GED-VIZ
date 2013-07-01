define [
  'underscore'
  'lib/type_data'
  'lib/currency'
  'models/base/collection'
  'models/bubble'
  'views/base/view'
  'views/base/collection_view'
  'views/keyframe_configuration/used_indicators_view'
  'views/bubble_view'
  'jquery.sortable'
], (_, TypeData, Currency, Collection, Bubble, View, CollectionView,
    UsedIndicatorsView, BubbleView) ->
  'use strict'

  class IndicatorsView extends View

    # Property declarations
    # ---------------------
    #
    # model: Keyframe

    templateName: 'keyframe_configuration/indicators'

    tagName: 'section'
    className: 'indicators'

    events:
      'click .add-indicator': 'addIndicatorClicked'
      'click .add-indicator-menu a': 'indicatorTypeClicked'
      'click a.remove': 'removeClicked'

    initialize: ->
      super
      @usedIndicators = new Collection @getTypesWithUnitFromModel()
      @listenTo @model, 'change:indicator_types_with_unit', @indicatorsUpdated
      @listenTo @model, 'change:countries', @updateVisibility
      $(document).on 'click', @clickedOutside

    # Model getters
    # -------------

    getTypesWithUnitFromModel: ->
      _(@model.get('indicator_types_with_unit')).map (twu) ->
        {type: twu[0], unit: twu[1]}

    getDisplayedIndicatorCount: ->
      countryCount = @model.get('countries').length
      if countryCount >= 9
        1
      else if countryCount >= 6
        2
      else if countryCount >= 3
        3
      else
        5

    canAddIndicators: ->
      @model.get('indicator_types_with_unit').length < 5

    isTypeWithUnitUsed: (typeWithUnit) ->
      _(@model.get('indicator_types_with_unit')).any (twu) ->
        twu[0] is typeWithUnit[0] and twu[1] is typeWithUnit[1]

    # DOM event handlers
    # ------------------

    addIndicatorClicked: (event) ->
      event.preventDefault()
      @toggleMenu() if @canAddIndicators()

    indicatorTypeClicked: (event) ->
      event.preventDefault()
      type = $(event.currentTarget).data('type')
      return unless type?

      units = TypeData.indicator_types[type].units
      currency = @model.get 'currency'
      unit = _.find(units, (unit) ->
        Currency.isVisible unit.key, currency
      ).key
      return unless unit?

      twu = [type, unit]
      return if @isTypeWithUnitUsed twu
      @model.addIndicatorTypeWithUnit twu
      @hideMenu()

    removeClicked: (event) ->
      event.preventDefault()
      index = @$('.used-indicators .remove').index event.currentTarget
      @model.removeIndicatorAt index

    clickedOutside: (event) =>
      $parents = $(event.target).parents()
      menu = @$('.add-indicator-menu')
      outsideMenu = $parents.index(menu) is -1
      outsideButton = @$('.add-indicator').get(0) isnt event.target
      if outsideMenu and outsideButton
        @hideMenu()

    # Model event handlers
    # --------------------

    indicatorsUpdated: ->
      @usedIndicators.reset @getTypesWithUnitFromModel()
      @updateVisibility()
      @updateAddIndicatorMenu()

    updateVisibility: ->
      countVisible = @getDisplayedIndicatorCount()
      @$('.used-indicator').each (index, li) =>
        if countVisible < index + 1
          invisible = true
          @showInvisibleNotification()
        else
          invisible = false
        $(li).toggleClass 'invisible', invisible
      return

    # Rendering
    # ---------

    getTemplateData: ->
      data = super
      indicatorTypes = _(TypeData.indicator_types).values()
      data.indicator_type_groups = _(indicatorTypes).groupBy (indicator) ->
        indicator.group or indicator.key
      data

    render: ->
      super
      @renderUsedIndicators()
      @updateVisibility()
      @updateAddIndicatorMenu()

    renderUsedIndicators: ->
      usedIndicatorsView = new UsedIndicatorsView
        collection: @usedIndicators
        container: @el
        keyframe: @model
      @listenTo usedIndicatorsView, 'move', @indicatorMoved
      @subview 'usedIndicators', usedIndicatorsView

    showInvisibleNotification: ->
      target = @$('.used-indicator.invisible')
      bubble = new Bubble
        type: 'notification'
        text: 'hidden_country'
        targetElement: target
        position: 'left'
        positionTopReference: target
        customClass: 'invisible'
        timeout: 800

      @subview 'invisibleNotification', new BubbleView(model: bubble)
      return

    indicatorMoved: (oldIndex, newIndex) ->
      @updateVisibility()
      @model.moveIndicator(oldIndex, newIndex)

    updateAddIndicatorMenu: ->
      $menu = @$('.add-indicator-menu')

      if @canAddIndicators()
        @$('.add-indicator').removeClass 'disabled'

        $menu.find('li.type')
          .removeClass('disabled')
          .addClass('enabled')
        for twu in @model.get('indicator_types_with_unit')
          $menu.find("li.type[data-type=#{twu[0]}]")
            .addClass('disabled')
            .removeClass('enabled')
      else
        @$('.add-indicator').addClass 'disabled'

    # Toggle Menu
    # -----------

    toggleMenu: (show) ->
      @$('.add-indicator-menu').toggle show

    showMenu: ->
      @toggleMenu true

    hideMenu: ->
      @toggleMenu false

    # Disposal
    # --------

    dispose: ->
      return if @disposed
      $(document).off 'click', @clickedOutside
      super
