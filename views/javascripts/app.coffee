# Simply a glorified object that provides blocks of javascript
# to be registered for specific URLs.

class App
  instance = null

  class PrivateClass
    constructor: () ->
      @actions = {}
    add: (path, fn) ->
      @actions[path] = fn
    exec: (path) ->
      fn = @actions[path]
      fn() if fn?

  @get: () =>
    instance ?= new PrivateClass()

  @add: (url, fn) =>
    @get().add(url, fn)

  @exec: (path) =>
    @get().exec(path)

$(document).on "ready", () ->
  App.exec(document.location.pathname)

  # Prevent the default behavior when clicking on a label.
  # I don't want it to select the box it refers to.
  $("label").on "click", (e) ->
    e.preventDefault()

window.App = App