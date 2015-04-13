coffee = require "coffee-script"

render_partials = require "./render_partials"

module.exports = (app) ->
  (path, options, callback) ->
    render_partials app, path, options, (err, data) ->
      if err?
        callback(err)
        return

      try
        data = coffee.compile(data)
      catch e
        e.message = "ERROR compiling coffeescript file #{path}: #{e.message}"
        callback(e)

        return

      callback null, data