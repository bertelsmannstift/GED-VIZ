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

  # Do not render rollovers in Mobile Safari because changing the DOM in
  # a mouseenter handler will prevent the click event from firing. See:
  # http://sitr.us/2011/07/28/how-mobile-safari-emulates-mouse-events.html
  # This is inconsistent across touch devices, so this is not a general
  # touch device / touch event detection.
  support.mouseover = do ->
    ua = navigator.userAgent
    not (
      /\sSafari\/[^\s]+(\s|$)/.test(ua) and
      /\sMobile\/[^\s]+(\s|$)/.test(ua)
    )

  Object.freeze? support

  support
