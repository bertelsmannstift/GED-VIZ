define ->
  'use strict'

  # The routes for the application. This module returns a function.
  # `match` is match method of the Router
  (match) ->

    match ''                                 , 'editor#show'
    match 'edit/:id'                         , 'editor#show'
    match 'edit/:id/:index'                  , 'editor#show'
    match ':id'                              , 'player#show'
    match 'render/:presentation_id'          , 'static#render'
    match 'render/:presentation_id/:keyframe', 'static#render'

