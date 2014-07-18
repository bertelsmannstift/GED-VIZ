define ->
  'use strict'

  # The routes for the application. This module returns a function.
  # `match` is match method of the Router
  (match) ->

    # Editor
    match '', 'editor#show'
    match 'edit/:id', 'editor#show'
    match 'edit/:id/:index', 'editor#show'

    # Player
    match ':id', 'player#show', constraints: { id: /^\d+$/ }

    # Static presentation
    match 'render/:presentation_id', 'static#render'
    match 'render/:presentation_id/:keyframe', 'static#render'

