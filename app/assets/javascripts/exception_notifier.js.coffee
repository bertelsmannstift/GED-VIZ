window.onerror = (message, scriptURL, lineNumber) ->
  return false unless window.jQuery
  $.ajax '/javascript_exceptions', {
    type: 'POST'
    data:
      url: location.href,
      userAgent: navigator.userAgent,
      screen:
        width: screen.width,
        height: screen.height
      viewport:
        width: window.innerWidth or document.documentElement.clientWidth,
        height: window.innerHeight or document.documentElement.clientHeight
      message: message,
      scriptURL: scriptURL,
      lineNumber: lineNumber
  }
  return false
