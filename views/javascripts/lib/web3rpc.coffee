# A lighter wrapper around the web3 JSON RPC, that uses
# all asynchronous calls. To be used in conjunction with web3,
# mainly because web3 includes nice, utility functions and
# eventually the issues with web3 will be ironed out.

factory = (web3, XMLHttpRequest) ->
  class Web3RPC
    class @RequestError extends Error
      constructor: (@message, @xhr) ->
        @name = "Web3RPC.RequestError"

    constructor: (@host, @port) ->
      @nonce = 0

    # method: RPC call method name, i.e., "eth_coinbase"
    # params: (optional) Array of paramaters to pass to the RPC call
    # callback: function(err, result) {}
    send: (method, params, callback) -> 
      if typeof params == "function"
        callback = params
        params = []

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
    # fn_name: The name of the contract function you want to call.
    #          If you want to call getOwner(), fn_name would be "getOwner"
    # address: Address of the contract.
    # abi:     ABI of the contract.
    # params:  (optional) Array of parameters you want to pass to the function.
    # block:   (optional) Block you want to query. Default is "latest"
    # callback: function(err, result) {}
    call: (fn_name, address, abi, params=[], block="latest", callback) ->
      if typeof block == "function"
        callback = block
        block = "latest"

      if typeof params == "function"
        callback = params
        block = "latest"
        params = []

      if !(params instanceof Array)
        callback = block
        block = params
        params = []

      # Get function name from abi
      fully_qualified_name = null

      for item in abi
        continue if item.name != fn_name
        
        fully_qualified_name = fn_name + "("

        for input in item.inputs
          fully_qualified_name += input.type + ","

        # Remove the last comma
        fully_qualified_name = fully_qualified_name.slice(0, fully_qualified_name.length - 1)
        fully_qualified_name += ")"

      throw "Couldn't find function for #{fn_name}!" if fully_qualified_name == null

      @send "web3_sha3", [web3.fromAscii(fully_qualified_name)], (err, hex) =>
        if err?
          callback(err, hex)
          return

        fn_identifier = hex.slice(0, 10)

        parsed = web3.abi.inputParser(abi)[fn_name].apply(null, params)

        rpc_params = [
          {
            to: address
            data: fn_identifier + parsed
          }
          block
        ]

        @send "eth_call", rpc_params, (err, result) ->
          if err?
            callback(err, result)
          else
            callback(null, web3.abi.outputParser(abi)[fn_name].call(null, result)[0])

  return Web3RPC

if module? && module.exports?
  module.exports = factory(require("web3"), require("xmlhttprequest").XMLHttpRequest)
else
  window.Web3RPC = factory(web3, XMLHttpRequest)