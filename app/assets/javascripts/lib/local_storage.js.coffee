define (require) ->
  'use strict'
  _ = require 'underscore'
  support = require 'lib/support'

  # Store JavaScript objects in localStorage as JSON

  falseFunc = -> false

  supported = Boolean support.localStorage and
    window.JSON and
    typeof JSON.parse is 'function' and
    typeof JSON.stringify is 'function'

  # Fetches an object by key and then REMOVES it from the storage.
  fetch = (storageKey) ->
    serialization = localStorage.getItem storageKey
    return false unless serialization
    localStorage.removeItem storageKey
    JSON.parse serialization

  # Saves an object under a given key.
  save = (storageKey, object) ->
    serialization = JSON.stringify object
    localStorage.setItem storageKey, serialization
    true

  # Public interface

  {
    fetch: if supported then fetch else falseFunc
    save: if supported then save else falseFunc
  }

