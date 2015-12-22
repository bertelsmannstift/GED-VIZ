define (require) ->
  'use strict'
  _ = require 'underscore'
  mediator = require 'chaplin/mediator'

  # These methods are mixed into Chart
  # ----------------------------------

  initChartStates: ->

    # animation states
    #   on: currently animating
    #   off: not animating
    @initStates
      states:
        animation: ['on', 'off']
      initialState:
        animation: 'off'

  # Handles clicks on the canvas itself
  # -----------------------------------

  canvasClicked: (event) ->
    if @elements and event.currentTarget is event.target
      @resetStates preserveLocking: false
    return

  # Resets state of all magnets and relations
  # -----------------------------------------

  resetStates: (options = {}) ->
    _.defaults options, preserveLocking: true
    @resetMagnets options
    @resetRelations options
    @resetIndicators options
    @publishLocking()
    return

  # Magnet state handling
  # ---------------------

  addMagnetHandlers: (magnet) ->
    @listenTo magnet, 'mouseleave', @magnetMouseleave
    @listenTo magnet, 'leaveState', @magnetLeaveState
    return

  magnetMouseleave: (magnet) ->
    # If this magnet is active, do nothing
    return if magnet.state('mode') is 'active'

    # If there is a locked magnet, transition to dimmedOut, otherwise to normal
    magnet.transitionTo 'mode', if @getLockedMagnet(magnet)
        'dimmedOut'
      else
        'normal'

    return

  magnetLeaveState: (magnet, oldState, newState) ->
    # If a magnet was highlighted
    # ---------------------------

    if oldState in ['modeNormal', 'modeDimmedOut'] and newState in ['modeHighlight']

      @forMagnets magnet, (otherMagnet) ->

        # Dim out all other magnets
        otherMagnet.transitionTo 'mode', 'dimmedOut'

        # Hide temporarily visible indicators
        indicators = otherMagnet.element.indicators
        if indicators.state() is 'highlight'
          indicators.transitionTo 'invisible'

        return

      # Reset all relations, then activate the right ones
      @resetRelations preserveLocking: true
      @activateRelationsForElement magnet.element

    # If a magnet was highlighted or activated
    # ----------------------------------------

    if newState in ['modeActive', 'modeHighlight']
      # Show invisible indicators
      indicators = magnet.element.indicators
      if indicators.state() is 'invisible'
        indicators.transitionTo 'highlight'

    # If a magnet was dehighlighted or deactivated
    # --------------------------------------------

    if oldState in ['modeHighlight'] and newState in ['modeNormal', 'modeDimmedOut']

      # Restore the locked magnet
      lockedMagnet = @getLockedMagnet()
      if lockedMagnet

        # Reset the relations of the current magnet
        @resetRelationsForElement magnet.element

        # Transition the locked magnet back to active
        lockedMagnet.transitionTo 'mode', 'active'

        # Activate its relations
        @activateRelationsForElement lockedMagnet.element

      else
        # No locked magnet

        # Reset dimmed-out magnets to normal
        @forMagnets magnet, (otherMagnet) ->
          if otherMagnet.state('mode') is 'dimmedOut'
            otherMagnet.transitionTo 'mode', 'normal'

        # Reset all relations
        @resetRelations preserveLocking: true

        # Restore locked relation
        lockedRelation = @getLockedRelation()
        if lockedRelation
          lockedRelation.transitionTo 'path', 'active'
          lockedRelation.transitionTo 'labels', 'on'

      # Hide corresponding indicators if they are temporarily visible
      indicators = magnet.element.indicators
      if indicators.state() is 'highlight'
        indicators.transitionTo 'invisible'

    # If a magnet was locked
    # ----------------------

    if newState is 'lockedOn'

      @forMagnets magnet, (otherMagnet) ->
        # Unlock and dim out other magnets
        otherMagnet.transitionTo 'locked', 'off'
        otherMagnet.transitionTo 'mode', 'dimmedOut'

      # Reset all relations
      @resetRelations preserveLocking: false

      # Activate relations for locked magnet
      @activateRelationsForElement magnet.element
      @publishLocking magnet

    else if newState is 'lockedOff'
      @publishLocking()

    return

  # Magnet state helpers
  # --------------------

  # Call a function for each magnet except the given
  forMagnets: (exceptMagnet, callback) ->
    for element in @elements
      magnet = element.magnet
      if exceptMagnet is magnet
        continue
      callback magnet
    return

  # Get the locked magnet, filter by given magnet
  getLockedMagnet: (exceptMagnet) ->
    for element in @elements
      magnet = element.magnet
      if exceptMagnet is magnet
        continue
      if magnet.state('locked') is 'on'
        return magnet
    false

  # Reset all magnets
  # Options:
  #   preserveLocking: whether to preserve the locking state or reset it too
  resetMagnets: (options = {}) ->
    _.defaults options, preserveLocking: true
    for element in @elements
      magnet = element.magnet
      magnet.transitionTo 'mode', 'normal'
      unless options.preserveLocking
        magnet.transitionTo 'locked', 'off'
    return

  # Indicator state handling
  # ------------------------

  # Reset all temporarily highlighted indicators to invisible
  resetIndicators: ->
    for element in @elements
      indicators = element.indicators
      if indicators.state() is 'highlight'
        indicators.transitionTo 'invisible'
    return

  # Relation state handling
  # -----------------------

  addRelationHandlers: (relation) ->
    @removeRelationHandlers relation
    @listenTo relation, 'leaveState', @relationLeaveState
    return

  removeRelationHandlers: (relation) ->
    @stopListening relation, 'leaveState', @relationLeaveState
    return

  relationLeaveState: (relation, oldState, newState) ->
    # If a relation is highlighted
    if newState is 'pathHighlight'

      # Reset other highlighted or active relations
      @forRelations relation, (relation) ->
        if relation.state('path') in ['highlight', 'active']
          relation.transitionTo 'path', 'normal'
          relation.transitionTo 'labels', 'off'

    # If a relation is dehighlighted
    if oldState is 'pathHighlight' and newState is 'pathNormal'

      # Restore the locked relation
      lockedRelation = @getLockedRelation()
      if lockedRelation
        lockedRelation.transitionTo 'path', 'active'
        lockedRelation.transitionTo 'labels', 'on'

    # If a relation is locked
    if newState is 'lockedOn'

      # Reset all magnets
      @resetMagnets preserveLocking: false

      # Reset activeIn & activeOut relations to normal
      @forRelations relation, (otherRelation) ->
        if otherRelation.state('path') in ['activeIn', 'activeOut']
          otherRelation.transitionTo 'path', 'normal'

      # Reset old locked relation
      lockedRelation = @getLockedRelation relation
      if lockedRelation
        lockedRelation.transitionTo 'path', 'normal'
        lockedRelation.transitionTo 'labels', 'off'
        lockedRelation.transitionTo 'locked', 'off'

      @publishLocking relation

    else if newState is 'lockedOff'
      @publishLocking()

    return

  # Relation state helpers
  # ----------------------

  # Call a function for each relation except the given
  forRelations: (exceptRelation, callback) ->
    if arguments.length is 1
      callback = exceptRelation
      exceptRelation = null
    for element in @elements
      for relation in element.relationsOut when relation isnt exceptRelation
        callback relation
    return

  # Reset all relations
  # Options:
  #   except: Relation not to reset
  #   preserveLocking: whether to preserve the locking state or reset it too
  resetRelations: (options = {}) ->
    _.defaults options, preserveLocking: true
    for element in @elements
      for relation in element.relationsOut when relation isnt options.except
        relation.transitionTo 'path', 'normal'
        relation.transitionTo 'labels', 'off'
        unless options.preserveLocking
          relation.transitionTo 'locked', 'off'
    return

  # Get the locked relation, except the given
  getLockedRelation: (exceptRelation) ->
    for element in @elements
      for relation in element.relationsOut
        if relation isnt exceptRelation and relation.state('locked') is 'on'
          return relation
    false

  # Activate the relations for a given element properly (activeIn/activeOut)
  activateRelationsForElement: (element) ->
    for relation in element.relationsOut
      relation.transitionTo 'path', 'activeOut'
    for relation in element.relationsIn
      relation.transitionTo 'path', 'activeIn'
    return

  # Reset the relations for given element,
  # but spare those from or to active magnets
  resetRelationsForElement: (element) ->
    # Gather all relations
    relations = element.relationsOut.concat element.relationsIn
    for relation in relations

      # Get the other magnet
      otherElement = if relation.from is element
          relation.to
        else
          relation.from
      otherMagnet = otherElement.magnet
      otherMagnetState = otherMagnet.state 'mode'

      # Reset relation if the other magnet isn’t active
      unless otherMagnetState is 'active'
        relation.transitionTo 'path', 'normal'
        relation.transitionTo 'labels', 'off'

    return

  # Locking
  # -------

  # Lock a magnet or a relation
  publishLocking: (target) ->
    return if @lockingPublisherMuted

    # Disable update while publishing. We don't want the change notification
    # from the keyframe to cause the chart to redraw.
    @updateDisabled = true

    unless target?
      # Remove locking
      mediator.publish 'locking:set', null
    else if target.element
      # Locking a magnet
      mediator.publish 'locking:set', target.element.id
    else if target.from and target.to
      # Locking a relation
      mediator.publish 'locking:set', [target.from.id, target.to.id]

    @updateDisabled = false
    return

  initLocking: ->
    locking = @keyframe.get 'locking'

    # Don’t publish locking removal to keyframe
    @lockingPublisherMuted = true

    # Reset all states and current locking
    @resetStates preserveLocking: false

    if locking
      if _.isArray(locking)
        # Locking is an array with two IDs, i.e. a relation is locked
        @initRelationLocking locking[0], locking[1]
      else
        # Locking is an ID, i.e. a magnet is locked
        @initMagnetLocking locking

    # Release lock
    @lockingPublisherMuted = false
    return

  initRelationLocking: (fromId, toId) ->
    relation = @getRelation fromId, toId
    return unless relation
    @resetRelations except: relation
    relation.transitionTo 'locked', 'on'
    relation.transitionTo 'path', 'active'
    relation.transitionTo 'labels', 'on'

  initMagnetLocking: (id) ->
    element = @elementsById[id]
    return unless element
    magnet = element.magnet
    magnet.transitionTo 'locked', 'on'
    magnet.transitionTo 'mode', 'active'
    @activateRelationsForElement element
