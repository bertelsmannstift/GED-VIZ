define ->
  'use strict'
  translations = <%= raw @translations.to_json %>
  Object.freeze? translations
  translations
