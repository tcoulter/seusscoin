window.Button = {
  setWaiting: (el) ->
    el = $(el)
    el.data("classes", el.attr("class") || "")
    el.addClass("waiting started")
    el.data("text", el.html())
    el.data("width", el.outerWidth())
    el.css("width", el.outerWidth())
    el.html("<div class='inner'><div class='loader'></div></div>")

  endWaiting: (el) ->
    el = $(el)
    @startAnimation(el, null, 400)

  reset: (el) ->
    el = $(el)
    el.removeClass("waiting success failure started done")
    el.css("width", "")
    el.data("classes", null)
    el.html(el.data("text")) if el.data("text")? and el.data("text") != ""

  setSuccess: (el, done) ->
    el = $(el)
    el.removeClass("waiting")
    el.html("<div class='inner'>&#x2713;</div>")
    el.addClass("success started")
    @startAnimation(el, done)

  setFailure: (el, done) ->
    el = $(el)
    el.removeClass("waiting")
    el.html("<div class='inner'>&#x2717;</div>")
    el.addClass("failure")
    @startAnimation(el, done)

  startAnimation: (el, done, initial_wait_time=2000) ->
    el.addClass("started")
    setTimeout () =>
      el.removeClass("started")
      el.addClass("done")
      setTimeout () =>
        @reset(el)
        done() if done?
      , 400
    , initial_wait_time

  isInProgress: (el) ->
    el = $(el)
    el.hasClass("waiting") or el.hasClass("success") or el.hasClass("failure")
}