define [
  'views/modal_dialog_view'
], (ModalDialogView) ->
  'use strict'

  class OutdatedBrowserView extends ModalDialogView

    templateName: 'outdated_browser'

    className: 'modal-dialog outdated-browser'
