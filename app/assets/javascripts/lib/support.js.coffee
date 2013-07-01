define [
  'underscore'
  'lib/utils'
  'chaplin'
], (_, utils, Chaplin) ->
  'use strict'

  # Application-specific feature detection
  # --------------------------------------

  # Delegate to Chaplin’s support module
  support = utils.beget Chaplin.support

  # Add additional application-specific properties and methods

  # Whether the browser supports local storage
  support.localStorage = do ->
    try
      localStorage.setItem 'check', 'check'
      localStorage.removeItem 'check'
      return true
    catch error
      return false

  #support.cssTransitionProperty = do ->
  #  style = document.documentElement.style
  #  stringType = 'string'
  #  baseProp = 'transition'
  #  return baseProp if typeof style[baseProp] is stringType
  #  for prefix in ['Moz', 'Webkit', 'Khtml', 'O', 'ms']
  #    prop = prefix + baseProp.charAt(0).toUppercase() + baseProp.substring(1)
  #    return prop if typeof style[prop] is stringType
  #  false

  Object.freeze? support

  support
