define (require) ->
  'use strict'
  _ = require 'underscore'
  Element = require 'display_objects/element'

  # These methods are mixed into Chart
  # ----------------------------------

  # Helpers
  # -------

  # Get the element models from the keyframe
  elementModels: ->
    @keyframe.get 'elements'

  getElementCount: ->
    @keyframe.get('elements').length

  # Creates elements from the keyframe data
  # ---------------------------------------

  createElements: ->
    @elements = []
    @elementsById = {}

    for elementModel in @elementModels()
      @addElement elementModel

    # Update elementIdsChanged flag
    @elementIdsChanged = true

    return

  # Syncs elements with keyframe
  # ----------------------------

  updateElements: ->
    elementModels = @elementModels()
    oldElementIds = _(@elements).pluck('id').join()

    keepElements = {}

    for elementModel in elementModels
      keepElements[elementModel.id] = true
      element = @elementsById[elementModel.id]
      if element
        # Update existing element
        element.update elementModel, @dataTypeWithUnit
      else
        # Add new element
        @addElement elementModel

    # Remove old elements
    for element in @elements
      unless element.id of keepElements
        @removeElement element

    @sortElements()

    # Update elementIdsChanged flag
    newElementIds = _(elementModels).pluck('id').join()
    @elementIdsChanged = newElementIds isnt oldElementIds

    return

  # Sort elements in the order they appear in the keyframe
  sortElements: ->
    @elements = _.map @elementModels(), (elementModel) =>
      @elementsById[elementModel.id]
    return

  # Adds another element to the chart
  # ---------------------------------

  addElement: (elementModel) ->
    element = new Element elementModel, @dataTypeWithUnit
    @addMagnetHandlers element.magnet
    @elementsById[element.id] = element
    @elements.push element
    element

  # Removes an element from the chart
  # ---------------------------------

  removeElement: (element) ->
    element.dispose()
    delete @elementsById[element.id]
    @elements = _(@elements).without element
    return

  # Removes all elements from the chart
  # -----------------------------------

  removeElements: ->
    if @elements
      for element in @elements
        element.dispose()
    delete @elements
    delete @elementsById
    return
