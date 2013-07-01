define [
  'controllers/base/controller'
  'models/editor'
  'views/editor_view'
], (Controller, Editor, EditorView) ->
  'use strict'

  class EditorController extends Controller

    show: (params) ->
      attributes = id: params.id
      attributes.index = Number params.index if params.index?

      @editor = new Editor attributes
      @view = new EditorView model: @editor
      @editor.fetchPresentation()
