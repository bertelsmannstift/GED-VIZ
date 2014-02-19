define [
  'underscore'
  'lib/support'
], (_, support)->
  'use strict'

  # Store JavaScript objects in localStorage as JSON

  falseFunc = -> false

  supported = Boolean support.localStorage and
    window.JSON and
    typeof JSON.parse is 'function' and
    typeof JSON.stringify is 'function'

  fetch = (storageKey) ->
    serialization = localStorage.getItem storageKey
    return false unless serialization
    localStorage.removeItem storageKey
    JSON.parse serialization

  save = (storageKey, object) ->
    serialization = JSON.stringify object
    localStorage.setItem storageKey, serialization
    true

  # Public interface

  {
    fetch: if supported then fetch else falseFunc
    save: if supported then save else falseFunc
  }

