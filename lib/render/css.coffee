CleanCSS = require "clean-css"

render_partials = require "./render_partials"

module.exports = (app) ->
  (path, options, callback) ->
    render_partials app, path, options, (err, data) ->
      if err?
        callback(err)
        return

      # Do no processing if this is a partial. No need to minify css
      # over and over
      if options.is_partial? and options.is_partial == true
        callback(null, data)
        return

      if process.env.NODE_ENV != "development"

        try
          result = new CleanCSS().minify(data)

          data = result.styles
        catch e
          e.message = "Error minifying css of #{path}: #{e.message}"
          callback(e)
          return

      callback(null, data)