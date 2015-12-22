define (require) ->
  'use strict'
  TypeData = require 'lib/type_data'
  Colors = require 'lib/colors'
  # Returns the magnet colors {incoming, outgoing} for a given data type.
  # Automatically ascends to the parent data type.
  (dataType) ->
    dataType = TypeData.data_types[dataType].parent or dataType
    Colors.magnets[dataType]
