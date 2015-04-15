#!/usr/bin/env ./node_modules/.bin/coffee

process.env.NODE_ENV = "production"

express = require "express"
async = require "async"
fs = require "fs"
loadconfig = require "./lib/loadconfig"
cache = require "./lib/cache"
config = loadconfig("config/config.json")

app = express()

#app.engine "markdown", require("./lib/render/markdown")(app)
app.engine "coffee", require("./lib/render/coffee")(app)
app.engine "html", require("./lib/render/default")(app)
app.engine "scss", require("./lib/render/sass")(app)
app.engine "css", require("./lib/render/css")(app)
app.engine "txt", require("./lib/render/default")(app)
app.engine "xml", require("./lib/render/default")(app)
app.engine "js", require("./lib/render/js")(app)
app.set("view engine", "html")

# "request path": "render path"
files = {
  "/site.css?v=#{config.asset_version}": "site.scss"
  "/site.js?v=#{config.asset_version}": "site.js"
}

# Ensure caching.
process.env.NODE_ENV = "production"

# Render in series so we can evaluate any errors easily
# -- this is a trade off for render time. If the files
# render successfully, then they'll be placed in the 
# redis cache forrrrevvvverrrr. 
async.eachSeries Object.keys(files), (request_path, callback) ->
  file = files[request_path]
  console.log "Rendering #{request_path}..."
  app.render file, (err, body) ->
    if err
      throw err
      process.exit(1)

    cache.add request_path, body, (cache_err, added) ->
      if cache_err
        throw cache_err
        process.exit(1)

      console.log "Added: #{added}"
      callback()

, () ->
  console.log "Done!"
  process.exit(0)
