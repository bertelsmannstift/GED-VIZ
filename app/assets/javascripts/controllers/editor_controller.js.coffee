define [
  'controllers/base/controller'
  'models/editor'
  'views/editor_view'
], (Controller, Editor, EditorView) ->
  'use strict'

  class EditorController extends Controller

    show: (params) ->
      # Import global params
      presentationData = window.presentation
      fetchFromRemote = false

      if params.id
        # URL: /edit/:id
        if String(presentationData.id) isnt String(params.id)
          # Hash URL: /#edit/:id
          # Don’t use the embedded JSON, it’s not the requested presentation
          presentationData = id: params.id
          fetchFromRemote = true
      else
        # URL: /
        # If no ID was given, set the special value “new"
        presentationData.id = 'new'

      # Editor model attributes
      attributes = {}
      attributes.index = Number params.index if params.index?

      @editor = new Editor attributes, {presentationData}
      @view = new EditorView model: @editor
      @editor.fetchPresentation fetchFromRemote
