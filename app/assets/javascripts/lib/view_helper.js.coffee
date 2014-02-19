define [
  'underscore'
  'lib/utils'
  'lib/i18n'
], (_, utils, I18n) ->
  'use strict'

  # View helpers
  # ------------

  HAML.globals = ->
    t: I18n.t
    template: I18n.template
    "_": _

  return
