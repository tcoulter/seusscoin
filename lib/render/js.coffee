UglifyJS = require 'uglify-js'
coffee = require 'coffee-script'
beautify = require('js-beautify').js_beautify
fs = require "fs"
async = require "async"

render_partials = require "./render_partials"

module.exports = (app) ->
  (path, options, callback) ->
    render_partials app, path, options, (err, data) ->
      if err?
        callback(err)
        return

      # Do no processing if this is a partial. No need to beautify
      # or compress over and over.
      if options.is_partial? and options.is_partial == true
        callback(null, data)
        return

      if process.env.NODE_ENV == "development"
        data = beautify(data, { indent_size: 2 })
      else
        try
          result = UglifyJS.minify(data, {
            fromString: true
            compress: true
            mangle: true
          })

          data = result.code
        catch e
          e.message = "Error compressing js of #{path}: #{e.message}"
          callback(e)
          return

      callback(null, data)