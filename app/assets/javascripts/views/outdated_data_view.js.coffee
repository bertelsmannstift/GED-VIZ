define (require) ->
  'use strict'
  configuration = require 'configuration'
  ModalDialogView = require 'views/modal_dialog_view'

  class OutdatedDataView extends ModalDialogView

    # Property declarations
    # ---------------------
    #
    # model: Editor

    templateName: 'outdated_data'

    className: 'modal-dialog outdated-data'

    events:
      'click .update-button': 'updateData'

    updateData: (event) ->
      event.preventDefault()
      # Re-fetch all keyframes
      @model.fetchAllKeyframes()
      # Set the presentation to changed
      @model.getPresentation().setChanged()
      @dispose()
      return

    getTemplateData: ->
      presentation = @model.get('presentation')
      {
        data_version: presentation.get('data_version')
        latest_data_version: configuration.latest_data_version
      }