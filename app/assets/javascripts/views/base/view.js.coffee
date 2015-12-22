define (require) ->
  'use strict'
  Chaplin = require 'chaplin'
  require 'lib/view_helper'

  class View extends Chaplin.View

    getTemplateFunction: ->
      templateFunction = JST[@templateName]
      if typeof @templateName is 'string' and typeof templateFunction isnt 'function'
        throw new Error "View template #{@templateName} not found"
      templateFunction
