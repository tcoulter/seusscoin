App.add "/", () ->
  numberWithCommas = (x) ->
    parts = x.toString().split('.')
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',')
    parts.join '.'

  openWallet = $("#open_wallet")
  useCoinbase = $("#use_coinbase")
  clientHost = $("#client_host")
  clientHostLabel = $("#client_host_label")
  clientAddress = $("#client_address")
  clientAddressLabel = $("#client_address_label")
  
  useCoinbase.on "change", () ->
    # Remember: We're getting
    if useCoinbase.is(":checked") == false
      clientAddress.show()
      clientAddressLabel.show()
      clientHostLabel.show()
    else
      clientAddress.hide()
      clientAddressLabel.hide()
      clientHostLabel.hide()

  $(".use_coinbase_wrapper").find("div").on "click", (e) ->
    e.preventDefault()
    useCoinbase.prop("checked", !useCoinbase.prop("checked"))
    useCoinbase.trigger("change")
    return false

  close = $(".close")
  sendCoin = $("#sendcoin")
  sendAmount = $("#send_amount")
  enterAddress = $("#enter_address")
  sendAddress = $("#send_address")
  getFreeCoin = $("#request_from_faucet")
  finalize = $("#finalize")

  contracts = $("#contracts").data("contracts")

  # Variables set later that will be used elsewhere.
  web3rpc = null
  seuss = null

  nextStep = (id) ->
    current = $(".step.current")
    if id?
      next = $("##{id}")
    else
      next = current.next()

    current.removeClass("current")
    next.addClass("current")

  testConnection = () ->
    client_host = localStorage.getItem("client_host")

    Button.setWaiting(openWallet)
    
    # Use getBlock() to test the connection.
    web3rpc = new Web3RPC(client_host)
    web3rpc.send "eth_coinbase", (error, result) ->
      if error?
        Button.setFailure(openWallet)
      else
        Button.setSuccess(openWallet)
        localStorage.setItem("coinbase", result)

        if useCoinbase.is(":checked")
          localStorage.setItem("client_address", result)
        
        if localStorage.getItem("coinbase") != localStorage.getItem("client_address")
          useCoinbase.prop("checked", false)
          useCoinbase.trigger("change")        

        # Put the client address in the cientAddress box for 
        # convenience later - if the user goes back to that screen.
        clientHost.val(localStorage.getItem("client_host")) 
        clientAddress.val(localStorage.getItem("client_address").replace("0x", ""))  

        SeussCoin = web3rpc.contract(contracts.SeussCoin.abi)
        seuss = new SeussCoin(contracts.SeussCoin.address)

        seuss.balance localStorage.getItem("client_address"), (error, result) ->
          $("#balance").html(numberWithCommas(result.valueOf()))

          watchBalance()
          nextStep()

  openWallet.on "click", () ->
    address = clientAddress.val()
    if address.indexOf("0x") != 0
      address = "0x" + address

    localStorage.setItem("client_host", clientHost.val())
    localStorage.setItem("client_address", address)
    testConnection()

  sendCoin.on "click", () ->
    nextStep("amount_step")
    sendAmount.focus()

  $("button.cancel").on "click", () ->
    nextStep("balance_step")

  # Only allow numbers.
  sendAmount.on "keyup", () ->
    original = sendAmount.val()
    newValue = original.replace(/[^\d]/g, "")

    if original != newValue
      sendAmount.val(newValue)

  enterAddress.on "click", () ->
    nextStep("address_step")
    sendAddress.focus()

  getFreeCoin.on "click", () ->
    Button.setWaiting(getFreeCoin)
    seuss.requestFreeSeussCoin().send {from: localStorage.getItem("client_address")}, (error, result) ->
      if error?
        alert "Error procesing your request! Please try again."
        Button.setFailure(getFreeCoin)
      else
        alert "Transaction successfully queued! Note you won't receive your coin until the transaction is processed by the network."
        Button.setSuccess(getFreeCoin)

  finalize.on "click", () ->
    Button.setWaiting(finalize)
    receiver = sendAddress.val()
    receiver = "0x" + receiver if receiver.indexOf("0x") != 0
    amount = parseInt(sendAmount.val())
    seuss.sendCoin(receiver, amount).send {from: localStorage.getItem("client_address")}, (error, result) ->
      if error?
        alert "Error procesing your request! Please check your amount and receiver address and try again."
        Button.setFailure(finalize)
      else
        alert "Transaction successfully queued! Note you won't receive your coin until the transaction is processed by the network."
        Button.setSuccess(finalize)
        nextStep("balance_step")

  close.on "click", () ->
    stopWatchingBalance()
    nextStep("open_step")

  # If there's an address saved, populate the text box with it.
  # This is a nice convenience of connecting to the client host fails.
  if localStorage.hasOwnProperty("client_address")
    clientAddress.val(localStorage.getItem("client_address"))

    # If there's also a host (which there should be), test the connection.
    if localStorage.hasOwnProperty("client_host") && localStorage.hasOwnProperty("client_address")
      clientHost.val(localStorage.getItem("client_host")) 
      clientAddress.val(localStorage.getItem("client_address").replace("0x", ""))
      testConnection()
    

  watchInterval = null
  watchBalance = () ->
    watchInterval = setInterval () ->
      seuss.balance localStorage.getItem("client_address"), (error, result) ->
        $("#balance").html(numberWithCommas(result.valueOf()))
    , 3000

  stopWatchingBalance = () ->
    clearInterval(watchInterval)

  scrollToFaq = (e) ->
    e.preventDefault()
    $('html, body').animate({
        scrollTop: $("#faq").offset().top
    }, 1000);

  $(".scroll-down").on "click", scrollToFaq
  $("#huh").on "click", scrollToFaq




