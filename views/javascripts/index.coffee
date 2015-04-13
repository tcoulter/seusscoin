App.add "/", () ->
  step1 = $("#step1")
  step2 = $("#step2")

  nextBox = () ->
    current = $(".step.current")
    next = current.next()

    current.removeClass("current")
    next.addClass("current")

  step1.on "click", () ->
    nextBox()

  step2.on "click", () ->
    customer_eth = $("#input").val()

    Button.setWaiting(step2)
    
    web3.setProvider(new web3.providers.HttpProvider("http://#{customer_eth}"))

    # Use getBlock() to test the connection.
    web3.eth.getBlock 1, (error, result) ->
      if error?
        console.log error
        Button.setFailure(step2)
      else
        Button.setSuccess(step2)
        console.log result
    

    #console.log coinbase




