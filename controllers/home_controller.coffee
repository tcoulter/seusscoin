express = require "express"
cache = require "../lib/cache"
fs = require "fs"
async = require "async"

home = express()

home.get "/site.js", cache.route(), (req, res) ->
  res.type "js" 
  res.render "site.js"

home.get "/site.css", cache.route(), (req, res) ->
  res.type "css" 
  res.render "site.scss"

home.get "/", cache.route(), (req, res) ->
  res.render("index")

# If someone goes directly to a view, with or without the
# extension, render that.
home.get "*", cache.route(), (req, res) ->
  filepath = home.get("views") + req.params[0]

  slash = filepath.lastIndexOf("/")
  dir = filepath.substring(0, slash)
  filename = filepath.substring(slash + 1)

  fs.readdir dir, (err, files) => 
    if err?
      res.status(404).render("404")
      return

    # If the request includes the extension, look 
    # for an exact match (i.e., robots.txt). If not, 
    # look for any extension.
    if filename.indexOf(".") >= 0
      regex = filename
    else
      regex = new RegExp("#{filename}\.[^.]*")

    async.detect files, (file, callback) -> 
      callback(file.match(regex)?)
    , (file) ->
      if !file?
        res.status(404).render("404")
      else
        # Get the path relative to the views directory
        newpath = (dir + "/" + file).replace(home.get("views") + "/", "")
        res.render(newpath)

    
module.exports = home