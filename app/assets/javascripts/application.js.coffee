#= require hamlcoffee
#= require_tree ./templates

# Bootstrap the application
require [
  'ged_viz'
], (GedViz) ->
  'use strict'
  app = new GedViz()
  app.initialize()