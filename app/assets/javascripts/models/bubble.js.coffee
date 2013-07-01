define [
  'models/base/model'
], (Model) ->
  'use strict'

  class Bubble extends Model

    defaults:
      type: 'notification'
      text: 'default'
      offset: 12
      timeout: 300
