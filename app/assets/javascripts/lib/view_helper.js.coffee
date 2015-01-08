define [
  'underscore'
  'lib/utils'
  'lib/i18n'
  'lib/type_text_helper'
], (_, utils, I18n, TypeTextHelper) ->
  'use strict'

  # View helpers
  # ------------

  HAML.globals = ->
    t: I18n.t
    dh: TypeTextHelper
    template: I18n.template
    "_": _

  return
