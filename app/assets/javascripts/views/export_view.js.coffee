define [
  'jquery'
  'configuration'
  'lib/utils'
  'lib/i18n'
  'views/modal_dialog_view'
], ($, configuration, utils, I18n, ModalDialogView) ->
  'use strict'

  class ExportView extends ModalDialogView

    # Property declarations
    # ---------------------
    #
    # downloadingHandle: Number
    #   setTimeout handle for closing the dialog after download

    templateName: 'export'

    className: 'modal-dialog export-dialog'

    container: '#page-container'

    autoRender: true

    events:
      'click .download-button': 'download'
      'change .subset': 'subsetChanged'

    subsetChanged: ->
      select = @$('.keyframe-select')
      input = select.find 'input'
      if @$('.subset:checked').val() is 'some'
        select.show()
        input.prop 'disabled', false
      else
        select.hide()
        input.prop 'disabled', true
      return

    download: (event) ->
      event.preventDefault()
      $(event.target).text I18n.t('export_dialog', 'please_wait')
      @downloadingHandle = utils.after 5000, @dispose
      @$('.export-form').submit()
      return

    getTemplateData: ->
      data = super
      data.locale = configuration.locale
      data

    dispose: =>
      return if @disposed
      clearTimeout @downloadingHandle
      delete @downloadingHandle
      super
