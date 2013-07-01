define [
  'views/modal_dialog_view'
], (ModalDialogView) ->
  'use strict'

  class SaveView extends ModalDialogView

    templateName: 'save'

    className: 'modal-dialog save-dialog'

    container: '#page-container'

    autoRender: true

    getTemplateData: ->
      data = super
      data.url = @model.getEditorURL()
      data

    addedToDOM: ->
      # Set focus to the URL field
      @$('.url').focus().select()
