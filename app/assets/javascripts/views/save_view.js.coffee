define (require) ->
  'use strict'
  ModalDialogView = require 'views/modal_dialog_view'

  class SaveView extends ModalDialogView

    templateName: 'save'

    className: 'modal-dialog save-dialog'

    autoFocus: false

    getTemplateData: ->
      data = super
      data.url = @model.getEditorURL()
      data

    addedToDOM: ->
      super
      # Set focus to the URL field
      @$('.url').focus().select()
      return
