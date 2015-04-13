_ = require "lodash"
path = require "path"
module.exports = (relative_path, extra_config={}, relative=false) ->
  main_dir_path = path.dirname(require.main.filename)
  full_path = path.join(main_dir_path, relative_path)

  config = {}

  file_contents = (require "#{full_path}")
  environment = process.env.NODE_ENV || "development"
  
  if file_contents["base"]?
    _.merge(config, file_contents["base"])

  if file_contents[environment]?
    _.merge(config, file_contents[environment])

  return _.merge(config, extra_config)