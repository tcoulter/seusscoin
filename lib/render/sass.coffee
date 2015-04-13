sass = require "node-sass"

render_partials = require "./render_partials"

module.exports = (app) ->
  (path, options, callback) ->
    render_partials app, path, options, (err, data) ->
      if err?
        callback(err)
        return
      
      if options.is_partial? and options.is_partial == true
        callback null, data
        return

      sass.render
        data: data
        success: (results) ->
          callback null, results.css
        error: (error) ->
          callback new Error("Error rendering #{path}: #{error.message}: line #{error.line}, column #{error.column}")
