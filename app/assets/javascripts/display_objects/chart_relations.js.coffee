define (require) ->
  'use strict'
  _ = require 'underscore'
  Relation = require 'display_objects/relation'
  utils = require 'lib/utils'

  # These methods are mixed into Chart
  # ----------------------------------

  # Create relations from keyframe
  # ------------------------------

  createRelations: ->
    elementModels = @elementModels()
    @createOutgoingRelations elementModels
    @createIncomingRelations elementModels
    @filterRelations()
    return

  # Create a new relation and add it to its elements
  # ------------------------------------------------

  createRelation: (fromId, from, toId, to, amount,
    stackedAmountFrom, stackedAmountTo, missingRelations) ->

    relation = new Relation fromId, from, toId, to, amount,
      stackedAmountFrom, stackedAmountTo, missingRelations, @$container

    @connectRelation relation
    @addRelationHandlers relation

    relation

  # Connect the relation with its elements
  # --------------------------------------

  connectRelation: (relation) ->
    {from, to} = relation
    from.addRelationOut relation if from
    to.addRelationIn relation if to
    return

  # Disconnect the relation from their elements
  # -------------------------------------------

  disconnectRelation: (relation) ->
    {from, to} = relation
    from.removeRelationOut relation if from
    to.removeRelationIn relation if to
    return

  # Outgoing relations
  # ------------------

  createOutgoingRelations: (elementModels) ->
    for elementModel in elementModels
      @createOutgoingRelation elementModel
    return

  createOutgoingRelation: (elementModel) ->
    fromId = elementModel.id
    from = @elementsById[fromId]

    for toId, stackedAmounts of elementModel.outgoing
      continue if stackedAmounts.value is 0
      to = @elementsById[toId] or null
      missingRelations = elementModel.missingRelations[toId] or null
      @createRelation(
        fromId, from,
        toId, to,
        stackedAmounts.value,
        stackedAmounts.stacked_amount_from,
        stackedAmounts.stacked_amount_to,
        missingRelations
      )
    return

  updateOutgoingRelation: (relation, to, amount, stackedAmountFrom,
      stackedAmountTo, missingRelations) ->

    @disconnectRelation relation

    # Update the amount
    relation.amount = amount
    relation.stackedAmountFrom = stackedAmountFrom
    relation.stackedAmountTo = stackedAmountTo

    # Update missing relations
    relation.missingRelations = missingRelations

    # Update `to` element because it might
    # be added to or removed from the chart
    relation.to = to

    # Ensure a relation to a country that isn’t
    # in the chart isn’t visible any longer
    relation.hide() unless to

    @connectRelation relation

    return

  # Incoming relations
  # ------------------

  # Create incoming relations from countries that are not in the chart
  # (i.e. relations without a `from` element). Used in charts with 1-2 elements.
  createIncomingRelations: (elementModels) ->
    for elementModel in elementModels
      incoming = elementModel.incoming
      continue unless incoming
      toId = elementModel.id
      to = @elementsById[toId]
      for fromId, stackedAmounts of incoming when stackedAmounts.value > 0
        from = @elementsById[fromId]
        # Skip if the from element is in the chart (a relation already exists)
        continue if from
        @createRelation(
          fromId, null,
          toId, to,
          stackedAmounts.value,
          stackedAmounts.stacked_amount_from,
          stackedAmounts.stacked_amount_to
        )

    return

  # Dispose all incoming relations with an empty `from`
  removeIncomingRelations: ->
    for element in @elements
      for relation in element.relationsIn when relation.from is null
        relation.dispose()
    return

  # Synchronize relations with keyframe
  # -----------------------------------

  updateRelations: ->
    elementModels = @elementModels()

    # Update outgoing properly
    @updateOutgoingRelations elementModels

    # Recreate incoming relations from scratch
    @removeIncomingRelations()
    @createIncomingRelations elementModels

    @filterRelations()

    return

  updateOutgoingRelations: (elementModels) ->
    keepRelations = {}

    for elementModel in elementModels
      fromId = elementModel.id
      from = @elementsById[fromId]
      for toId, stackedAmounts of elementModel.outgoing
        keepRelations["#{fromId}>#{toId}"] = true
        to = @elementsById[toId] or null # Might be null
        missingRelations = elementModel.missingRelations[toId] or null
        relation = _.find from.relationsOut, (r) -> r.toId is toId
        # Update existing or create new relation
        if relation
          @updateOutgoingRelation(
            relation, to,
            stackedAmounts.value,
            stackedAmounts.stacked_amount_from,
            stackedAmounts.stacked_amount_to,
            missingRelations
          )
        else
          @createRelation(
            from.id, from, toId, to,
            stackedAmounts.value,
            stackedAmounts.stacked_amount_from,
            stackedAmounts.stacked_amount_to,
            missingRelations
          )

    # Remove old outgoing relations
    for element in @elements
      for relation in element.relationsOut
        unless relation.id of keepRelations
          # The relation removes itself from
          # the relationsOut and relationsIn lists
          relation.dispose()

    return

  # Show only the most important relations, hide the rest
  # -----------------------------------------------------

  filterRelations: ->
    allRelations = @getAllRelations()

    # Show all relations if less than 9 countries
    if @elements.length < 9
      for relation in allRelations
        relation.show()
      return

    # Gather visible relations
    visibleRelations = {}

    # Show the x biggest relations of the y biggest countries
    BIGGEST_COUNTRIES = 5
    BIGGEST_COUNTRIES_RELATIONS = 4

    # Sort a copy of the elements
    elements = @elements.concat().sort utils.elementsSorter
    for element in elements[0...BIGGEST_COUNTRIES]
      relationsOut = element.relationsOut[0...BIGGEST_COUNTRIES_RELATIONS]
      for relation in relationsOut
        visibleRelations[relation.id] = true

    # Show the z next biggest relations
    BIGGEST_RELATIONS = 5

    # Sort relations by their amount (descending)
    allRelations.sort utils.relationSorter
    found = 0
    for relation in allRelations
      unless relation.id of visibleRelations
        visibleRelations[relation.id] = true
        found++
        break if found is BIGGEST_RELATIONS

    # Finally, hide relations which are not preserved
    for relation in allRelations
      visible = relation.id of visibleRelations
      if visible
        relation.show()
      else
        relation.hide()

    return

  # Return an array with all outgoing relations of all elements
  getAllRelations: ->
    allRelations = []
    for element in @elements
      for relation in element.relationsOut
        allRelations.push relation
    allRelations

  # Find an outgoing relation by from and to IDs
  getRelation: (fromId, toId) ->
    for element in @elements
      for relation in element.relationsOut
        if relation.fromId is fromId and relation.toId is toId
          return relation
    false
