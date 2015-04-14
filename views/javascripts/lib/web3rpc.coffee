# A lighter wrapper around the web3 JSON RPC, that uses
# all asynchronous calls. To be used in conjunction with web3,
# mainly because web3 includes nice, utility functions and
# eventually the issues with web3 will be ironed out.

factory = (web3, XMLHttpRequest) ->
  class Web3RPC
    class @RequestError extends Error
      constructor: (@message, @xhr) ->
        @name = "Web3RPC.RequestError"

    # Allow ("127.0.0.1", "8080"), as well as ("127.0.0.1:8080")
    constructor: (@host, @port) ->
      if !@port?
        split = @host.split(":")
        @host = split[0]
        @port = split[1]

      @nonce = 0

    # method: RPC call method name, i.e., "eth_coinbase"
    # params: (optional) Array of paramaters to pass to the RPC call
    # callback: function(err, result) {}
    send: (method, params, callback) -> 
      if typeof params == "function"
        callback = params
        params = []

      if !callback?
        throw "send() must be passed a callback!"

      payload = 
        jsonrpc: "2.0"
        method: method
        params: params
        id: @nonce

      xhr = new XMLHttpRequest()

      xhr.onreadystatechange = ->
        if @readyState == 4
          if @.status != 200
            callback(new Web3RPC.RequestError("Unexpected response code: #{xhr.status}", @))
            return

          try
            response = JSON.parse(@.responseText)
          catch
            callback(new Web3RPC.RequestError("Couldn't parse response", @))
            return 

          if response.error?
            callback(new Web3RPC.RequestError(response.error.message, @))
            return

          # No request errors and no errors messages from the server?
          # Great, we must have gotten a good response.
          callback(null, response.result)

      xhr.open "POST", "http://#{@host}:#{@port}/", true
      xhr.send(JSON.stringify(payload))

      @nonce += 1

    # Helper function for calling specific contract functions.
    # Use the contract() method instead of calling this function directly.
    #
    # method: "eth_call" or "eth_sendTransaction"
    # fully_qualified_name: The name of the contract function you want to call.
    #     If you want to call sendCoin(address receiver, uint256 amount), for instance, 
    #     the fully_qualified_name will be "sendCoin(address,uint256)"
    # abi:     ABI of the contract.
    # params:  (optional) Array of parameters you want to pass to the function.
    # tx_params: Parameters of the call or transaction, like "to", "from", "gas", and "gasPrice"
    # block:   (optional) Block you want to query. Default is "latest"
    # callback: function(err, result) {}
    #
    # These methods aren't meant to be used for adding new contract code to the network.
    # use send() with the "eth_sendTransaction" method.
    call_or_transact: (method="eth_call", fully_qualified_name, abi, params, tx_params, block, callback) ->
      prefix = fully_qualified_name.slice(0, fully_qualified_name.indexOf("("))

      @send "web3_sha3", [web3.fromAscii(fully_qualified_name)], (err, hex) =>
        if err?
          callback(err, hex)
          return

        fn_identifier = hex.slice(0, 10)

        parsed = web3.abi.inputParser(abi)[prefix].apply(null, params)

        tx_params.data = fn_identifier + parsed

        @send method, [tx_params, block], (err, result) ->
          if err?
            callback(err, result)
          else
            if method == "eth_call"
              # Return the result via the output parser
              callback(null, web3.abi.outputParser(abi)[prefix].call(null, result)[0])
            else
              # We made a transaction, so just return the tx address that gets sent back.
              callback(null, result)

    # Get fully qualified function names from abi
    fullyQualifyNames: (abi) ->
      names = {}
      for fn in abi
        fully_qualified_name = fn.name + "("

        for input in fn.inputs
          fully_qualified_name += input.type + ","

        # Remove the last comma
        if fn.inputs.length > 0
          fully_qualified_name = fully_qualified_name.slice(0, fully_qualified_name.length - 1)

        fully_qualified_name += ")"

        names[fn.name] = fully_qualified_name

      names

    contract: (abi) ->
      names = @fullyQualifyNames(abi)

      web3rpc = @

      class Contract
        web3rpc: web3rpc
        constructor: (@address) ->

      # If no callback function is passed to the callhandler, then 
      # the code will assume you want to send this method as a transaction,
      # and will return a transaction handler to process the request.
      # This allows for the following syntax:
      #
      # myContract.sendCoin(receiver, amount).send({gas: 10000})
      createHandler = (fully_qualified_name, abi) =>
        web3rpc = @
        return () ->
          callfn = (method, params, tx_params, callback) =>
            final_tx_params = {to: @address}

            for key, value of tx_params
              final_tx_params[key] = value

            console.log fully_qualified_name

            web3rpc.call_or_transact(method, fully_qualified_name, abi, params, final_tx_params, "latest", callback)

          args = Array.prototype.slice.call(arguments)
          callback = args[args.length - 1] if typeof args[args.length - 1] == "function"
          
          if callback?
            # There's a callback, so don't send the callback
            params = args.splice(0, args.length - 1)
            callfn("eth_call", params, {}, callback)
          else
            params = args
            # no callback, so return *another* function that will allow
            # the user to send the transaction it.
            return {
              send: (tx_params={}, callback) =>
                if typeof tx_params == "function"
                  callback = tx_params
                  tx_params = {}

                if !callback?
                  throw "send() function must be passed a callback!"

                callfn("eth_sendTransaction", params, tx_params, callback)
            }

      for prefix, fully_qualified_name of names
        Contract.prototype[prefix] = createHandler(fully_qualified_name, abi)

      Contract

  return Web3RPC

if module? && module.exports?
  module.exports = factory(require("web3"), require("xmlhttprequest").XMLHttpRequest)
else
  window.Web3RPC = factory(web3, XMLHttpRequest)