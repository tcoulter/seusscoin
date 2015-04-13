#!/usr/bin/env ./node_modules/.bin/coffee

express = require "express"
async = require "async"
fs = require "fs"
loadconfig = require "./lib/loadconfig"

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

files = [
  "/site.css"
  "/site.js"
]

# Ensure caching.
process.env.NODE_ENV = "production"

# Render in series so we can evaluate any errors easily
# -- this is a trade off for render time. If the files
# render successfully, then they'll be placed in the 
# redis cache forrrrevvvverrrr. 
async.eachSeries files, (file, callback) ->
  console.log "Rendering #{file}..."
  app.render file, (err, body) ->
    if err
      throw err
      exit(1)

    cache.add config.cache_prefix + file, body, (cache_err, added) ->
      if cache_err
        throw cache_err
        exit(1)
