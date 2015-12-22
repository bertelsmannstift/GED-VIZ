define (require) ->
  'use strict'
  utils = require 'lib/utils'

  # Simple state management
  # -----------------------

  States =

    _states: null
    _currentState: null
    _inTransition: false
    _singleGroup: true

    initStates: (options) ->
      @_singleGroup = options.states instanceof Array
      @_states = options.states

      # _currentState is an object if we have state groups
      unless @_singleGroup
        @_currentState = {}
        @_inTransition = {}

      if @_singleGroup
        # default behavior if we don't have state groups
        @transitionTo options.initialState
      else
        # set all groups to their default state if we have state groups
        for group, state of options.initialState
          @transitionTo group, state

    state: (group) ->
      if @_singleGroup
        @_currentState
      else
        unless group
          throw new Error "Group must be given"
        @_currentState[group]

    transitionTo: (group, newState) ->
      # Support disposable objects
      return if @disposed

      if @_singleGroup
        newState = group # newState comes in as first argument
        group = ''
        unless newState in @_states
          throw new Error "State #{newState} does not exist"
      else
        unless group and newState
          throw new Error "Group and new state must be given"
        unless newState in @_states[group]
          throw new Error "State #{newState} does not exist for group #{group}"

      if (@_singleGroup and @_inTransition) or
        (not @_singleGroup and @_inTransition[group])
          return

      oldState = @state group
      if newState is oldState
        return

      groupUpcase = utils.upcase group

      # Prepare old state names
      if oldState
        oldStateUpcase = utils.upcase oldState
        oldStateWithGroup = if @_singleGroup then oldState else group + oldStateUpcase
        unless @_singleGroup
          oldStateUpcase = groupUpcase + oldStateUpcase

      # Prepare new state names
      newStateUpcase = utils.upcase newState
      newStateWithGroup = if @_singleGroup then newState else group + newStateUpcase
      unless @_singleGroup
        newStateUpcase = groupUpcase + newStateUpcase

      # Set lock
      if @_singleGroup
        @_inTransition = true
      else
        @_inTransition[group] = true

      # Fire leave state events / leaveState handlers
      if oldState
        @trigger 'leaveState', this, oldStateWithGroup, newStateWithGroup
        @trigger "leave#{oldStateUpcase}State", this, newState

      # Update the current state
      if @_singleGroup
        @_currentState = newState
      else
        @_currentState[group] = newState

      # Fire enter state events / stateChange handlers
      @["enter#{newStateUpcase}State"]? oldState

      # Release lock
      if @_singleGroup
        @_inTransition = false
      else
        @_inTransition[group] = false

      @trigger 'stateChange', this, newStateWithGroup, oldStateWithGroup

      this

    disposeStates: ->
      delete @_states
      delete @_currentState
      delete @_inTransition
      delete @_singleGroup

  Object.freeze? States

  States
