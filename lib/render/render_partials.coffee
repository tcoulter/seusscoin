async = require "async"
fs = require "fs"
_ = require "lodash"

module.exports = (app, path, options, callback) ->
  fs.readFile path, "utf8", (err, data) ->
    if err?
      callback(err)
      return

    partials_reference = {}

    new_options = _.merge(
      include: (file, options={}) ->
        id = "__partial_#{Object.keys(partials_reference).length + 1}"
        partials_reference[id] = 
          file: file
          options: options
        "{{ #{id} }}"
    , options)

    # Do a first pass over the file to perform all the default
    # EJS rendering, as well as including an `include` function
    # that will return partial variables that can be parsed. 
    try
      compiled = _.template(data)
      data = compiled(new_options)
    catch e
      e.message = "Error rendering #{path}: #{e.message}"
      callback e
      return

    # Render each of the partials using express's render function. 
    # This is nice because we can render views of different types as
    # partials.
    async.each Object.keys(partials_reference), (key, partial_callback) ->
      partial_path = partials_reference[key].file

      clone_options = _.clone(options)
      clone_options = _.merge(clone_options, partials_reference[key].options)
      clone_options.is_partial = true

      app.render partial_path, clone_options, (err, rendered) ->
        if err?
          partial_callback(err)
          return

        partials_reference[key] = rendered
        partial_callback()

    , (err) ->
      if err?
        callback(err)
        return

      # Once rendering is complete for all partials found, do a pass once
      # more replacing the variables we injected earlier with the data from
      # each partial. Viola! That's it.
      try
        compiled = _.template(data, {interpolate: /{{([\s\S]+?)}}/g})
        data = compiled(partials_reference)
      catch e
        e.message = "Error rendering partial data: #{e.message}"
        callback(e)
        return

      callback(null, data)
