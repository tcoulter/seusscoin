render_partials = require "./render_partials"

module.exports = (app) ->
  (path, options, callback) ->
    render_partials app, path, options, callback