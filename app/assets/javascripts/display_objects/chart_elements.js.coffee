define [
  'underscore'
  'display_objects/element'
], (_, Element) ->
  'use strict'

  # These methods are mixed into Chart
  # ----------------------------------

  # Helpers
  # -------

  # Get the element models from the keyframe
  getElements: ->
    @keyframe.get 'elements'

  getElementCount: ->
    @keyframe.get('elements').length

  # Creates elements from the keyframe data
  # ---------------------------------------

  createElements: ->
    @elements = []
    @elementsById = {}

    elements = @getElements()

    for elementData in elements
      @addElement elementData

    # Update elementIdsChanged flag
    @elementIdsChanged = true

    return

  # Syncs elements with keyframe
  # ----------------------------

  updateElements: ->
    elements = @getElements()
    oldElementIds = _(@elements).pluck('id').join()

    keepElements = {}

    for elementData in elements
      keepElements[elementData.id] = true
      element = @elementsById[elementData.id]
      if element
        # Update existing element
        element.update elementData, @dataTypeWithUnit
      else
        # Add new element
        @addElement elementData

    # Remove old elements
    for element in @elements
      unless element.id of keepElements
        @removeElement element

    @sortElements()

    # Update elementIdsChanged flag
    newElementIds = _(elements).pluck('id').join()
    @elementIdsChanged = newElementIds isnt oldElementIds

    return

  # Sort elements in the order they appear in the keyframe
  sortElements: ->
    @elements = _(@getElements()).map (elementData) =>
      @elementsById[elementData.id]
    return

  # Adds another element to the chart
  # ---------------------------------

  addElement: (elementData) ->
    element = new Element elementData, @dataTypeWithUnit
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
