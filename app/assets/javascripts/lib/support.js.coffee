define (require) ->
  'use strict'
  _ = require 'underscore'
  Chaplin = require 'chaplin'
  utils = require 'lib/utils'

  # Application-specific feature detection
  # --------------------------------------

  # Delegate to Chaplin’s support module
  support = utils.beget Chaplin.support

  # Add additional application-specific properties and methods

  # Whether the browser supports local storage
  support.localStorage = do ->
    try
      localStorage.setItem 'check', 'check'
      unless localStorage.getItem('check') is 'check'
        return false
      localStorage.removeItem 'check'
      return true
    catch error
      return false

  support.testCSSProperty = (property) ->
    style = document.documentElement.style
    stringType = 'string'
    return property if typeof style[property] is stringType
    for prefix in ['Moz', 'Webkit', 'Khtml', 'O', 'ms']
      prop = prefix + property.charAt(0).toUpperCase() + property.substring(1)
      return prop if typeof style[prop] is stringType
    false

  support.cssTransitionProperty = support.testCSSProperty 'transition'
  support.cssTransformProperty = support.testCSSProperty 'transform'

  # Do not render rollovers in Mobile Safari because changing the DOM in
  # a mouseenter handler will prevent the click event from firing. See:
  # http://sitr.us/2011/07/28/how-mobile-safari-emulates-mouse-events.html
  # This is inconsistent across touch devices, so this is not a general
  # touch device / touch event detection.
  support.mouseover = do ->
    ua = navigator.userAgent
    not (
      /(^|\s)AppleWebKit\/[^\s]+(\s|$)/.test(ua) and
      /(^|\s)Mobile\/[^\s]+(\s|$)/.test(ua)
    )

  Object.freeze? support

  support
