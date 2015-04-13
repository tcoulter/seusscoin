#!/usr/bin/env ./node_modules/.bin/coffee
loadconfig = require "./lib/loadconfig"
compression = require "compression"
responseTime = require "response-time"
timeout = require "connect-timeout"
morgan = require "morgan"
bodyParser = require "body-parser"
_ = require "lodash"

process.env.NODE_ENV = "development" if !process.env.NODE_ENV?

config = loadconfig("config/config.json")

express = require 'express'
app = express()

app.use(morgan("combined"))
app.use(compression())
app.use(responseTime())
app.use(timeout(30000))
app.use(bodyParser.json()) # Do I need this? 

# Define rendering enginges we'll use to help render files.
app.engine "coffee", require("./lib/render/coffee")(app)
app.engine "html", require("./lib/render/default")(app)
app.engine "scss", require("./lib/render/sass")(app)
app.engine "css", require("./lib/render/css")(app)
app.engine "txt", require("./lib/render/default")(app)
app.engine "xml", require("./lib/render/default")(app)
app.engine "js", require("./lib/render/js")(app)
app.set("view engine", "html")

# HACK: Overwriting render function to inject default render options.
# This likely isn't the best way to pass variables, but... eh.
app.use (req, res, next) ->
  # Create CSS class to post on the body based on the URL.
  cssClass = req.url.replace(/\./g, " ").replace(/\//g, " ").trim()
  cssClass = cssClass.substring(0, cssClass.indexOf("?")) if cssClass.indexOf("?") >= 0
  cssClass = "index" if !cssClass? or cssClass == ""

  default_options = 
    config: config
    style: 
      cssClass: cssClass

  _.merge(default_options, app.locals)
  _.merge(default_options, res.locals)

  res_render = res.render

  res.render = (path, options={}) ->
    _.extend(default_options, options)
    res_render.call(res, path, default_options)

  app_render = app.render

  app.render = (path, options={}, callback) ->
    _.extend(default_options, options)
    app_render.call(app, path, default_options, callback)

  next()

app.use "/fonts", express.static(process.cwd() + config.font_dir)
app.use "/images", express.static(process.cwd() + config.image_dir)

# Define main application controller.
app.use(require("./controllers/home_controller"))

# Start the web app!
server = app.listen 80, ->
  host = server.address().address
  port = server.address().port
  console.log 'Web server listening at http://%s:%s', host, port
  
