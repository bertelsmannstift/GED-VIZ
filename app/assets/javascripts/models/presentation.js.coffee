define [
  'underscore'
  'jquery'
  'configuration'
  'chaplin/lib/sync_machine'
  'models/base/model'
  'models/keyframe'
  'models/keyframes'
  'lib/local_storage'
], (_, $, configuration, SyncMachine, Model, Keyframe, Keyframes, LocalStorage) ->
  'use strict'

  class Presentation extends Model

    _.extend @prototype, SyncMachine

    urlRoot: '/presentations'

    defaults:
      # Flag that tracks whether the presentation changed since the last save
      changed: false

    initialize: (attributes) ->
      super

      # Create keyframes if they haven’t been created through parse/set
      @getOrCreateKeyframes()

    # Keyframes handling
    # ------------------

    getKeyframes:->
      @get 'keyframes'

    createKeyframes: ->
      keyframes = new Keyframes()
      # Set changed flag when keyframes are added/removed or
      # their title changes.
      @listenTo keyframes, 'add remove change:title', @setChanged
      @set {keyframes}
      keyframes

    getOrCreateKeyframes: ->
      @getKeyframes() or @createKeyframes()

    # When cloning the presentation, clone the keyframes as well
    clone: ->
      clone = super
      clone.set keyframes: @getKeyframes().clone()
      clone

    # Synchronization
    # ---------------

    # Override url for fetching by id
    url: ->
      @urlRoot + (if @id? then "/#{@id}" else '')

    # Fetching
    # --------

    # Fetch presentation from remote server
    fetch: ->
      @beginSync()
      super.done @fetchSuccess

    fetchSuccess: =>
      @triggerReset()
      @finishSync()

    # Fetch presentation from localStorage synchronously
    # Returns true if successful and false otherwise
    fetchLocally: ->
      @beginSync()
      presentationData = LocalStorage.fetch 'presentation'

      unless presentationData and presentationData.keyframes.length
        @abortSync()
        return false

      @set @parse(presentationData)
      @set id: 'draft', changed: true
      @triggerReset()
      @finishSync()
      true

    # Model was prefilled with data, just fire the sync events
    setSynced: ->
      @beginSync()
      @triggerReset()
      @finishSync()
      return

    # Deserialization

    parse: (data) ->
      # Fill existing keyframes collection silently instead of creating
      # a new one. Manually trigger a reset event later when all attributes
      # have been set.
      keyframes = @getOrCreateKeyframes()
      data.keyframes = keyframes.reset data.keyframes, silent: true
      data

    # Manually trigger a reset event on the keyframes collection
    triggerReset: ->
      keyframes = @getKeyframes()
      keyframes.trigger 'reset', keyframes.models, {}
      return

    # Saving
    # ------

    save: ->
      # Remove the ID so that a new presentation is created on every save
      @unset 'id'
      # Return the Ajax promise
      super.done(@saveSuccess).fail(@saveError)

    saveIfChanged: ->
      if @get('changed')
        @save()
      else
        # Return a resolved promise
        $.Deferred().resolve().promise()

    syncSaveIfChanged: ->
      return unless @get('changed')
      @save null, async: false
      return

    saveSuccess: =>
      # Reset changed flag
      @set changed: false
      return

    saveError: =>

    # Save presentation in localStorage synchronously
    saveLocally: ->
      LocalStorage.save 'presentation', this
      return

    # Serialization

    toJSON: ->
      {
        id: @id
        keyframes: @getKeyframes().toJSON()
        index: @get('index')
      }

    # Change flag
    # -------------

    setChanged: ->
      # The presentation was changed in the editor
      @set changed: true
      return

    # URL helpers
    # -----------

    getEditorURL: ->
      index = @get 'index'
      params = {}
      params = lang: configuration.locale
      url = "#{location.protocol}//#{location.host}/edit/#{@id}" +
        (if index? then "/#{index}" else '') + '?' + $.param(params)
      url

    getPlayerURL: (options = {}) ->
      url = "#{location.protocol}//#{location.host}/#{@id}"
      params = {}
      params.animate = 1 if options.animate
      params.show_titles = 0 unless options.showTitles
      params.lang = configuration.locale
      unless _.isEmpty params
        url += '?' + $.param(params)
      url

    staticKeyframeImage: (keyframe, size) ->
      index = @getKeyframes().indexOf keyframe
      return false if index is -1
      index = String index
      # Pad index with zeros
      while index.length < 4
        index = "0#{index}"
      "/system/static/#{@id}/keyframe_#{index}_#{size}.png?lang=#{configuration.locale}"

    # Disposal
    # --------

    dispose: ->
      return if @disposed
      @getKeyframes().dispose()
      super
