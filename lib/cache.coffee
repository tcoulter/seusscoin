loadconfig = require "./loadconfig"
_ = require "lodash"

config = loadconfig("./config/config.json")

create = () ->
  # Cache in prod, not in development.
  if process.env.NODE_ENV == "production"
    cache = require('express-redis-cache')
  else
    cache =
      route: () ->
        return (req, res, next) ->
          # Let's be double sure we don't cache
          res.use_express_redis_cache = false
          res.header("Cache-Control", "max-age=0, must-revalidate")
          next()

    return cache
          
module.exports = create()