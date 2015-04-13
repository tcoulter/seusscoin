marked = require "marked"
fs = require "fs"
_ = require "lodash"

render_partials = require "./render_partials"

module.exports = (app) ->
  (path, options, callback) ->
    render_partials app, path, options, (err, data) ->
      if err?
        callback(err)
        return

      try
        data = marked(data)
      catch error
        console.log "ERROR processing file with markdown: #{error}"
        callback(error)
        return

      if options.is_partial? and options.is_partial == true
        callback(null, data)
      else
        # Render a specific template for all markdown files.
        app.render "templates/_markdown.html", _.merge(content: data), callback