define [
  'views/modal_dialog_view'
], (ModalDialogView) ->
  'use strict'

  class PromptView extends ModalDialogView

    templateName: 'prompt'

    className: 'modal-dialog prompt'

    autoFocus: false

    events:
      'click .okay-button': 'submit'
      'submit form': 'submit'

    addedToDOM: ->
      super
      # Set focus to the input field and select the content
      @$('.input-field').focus().select()
      return

    submit: (event) =>
      event.preventDefault()
      value = @$('.input-field').val()
      @model.get('success')?(value)
      @dispose()
      return

    closeButtonClicked: ->
      @model.get('error')?()
      super
      return
