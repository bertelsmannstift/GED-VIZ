define (require) ->
  'use strict'
  ModalDialogView = require 'views/modal_dialog_view'

  class OutdatedBrowserView extends ModalDialogView

    templateName: 'outdated_browser'

    className: 'modal-dialog outdated-browser'
