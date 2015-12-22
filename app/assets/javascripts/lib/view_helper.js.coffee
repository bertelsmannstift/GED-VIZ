define (require) ->
  'use strict'
  _ = require 'underscore'
  utils = require 'lib/utils'
  I18n = require 'lib/i18n'
  TypeTextHelper = require 'lib/type_text_helper'

  # View helpers
  # ------------

  HAML.globals = ->
    t: I18n.t
    dh: TypeTextHelper
    template: I18n.template
    "_": _

  return
