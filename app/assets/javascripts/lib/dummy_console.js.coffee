define ->
  # Create a dummy console
  unless window.console
    window.console = {}
  noop = new Function
  for name in ['log', 'debug', 'dir']
    unless name of console
      console[name] = noop
