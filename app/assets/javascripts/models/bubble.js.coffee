define (require) ->
  'use strict'
  Model = require 'models/base/model'

  class Bubble extends Model

    defaults:
      type: 'notification'
      text: ''
      offset: 12
      timeout: 300
