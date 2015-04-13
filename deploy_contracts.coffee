#!/usr/bin/env ./node_modules/.bin/coffee

web3 = require "web3"
async = require "async"
fs = require "fs"
loadconfig = require("./lib/loadconfig")
child_process = require "child_process"

config = loadconfig("/config/config.json")

contracts = [
  {name: "SeussCoin", file: "./contracts/seusscoin.sol"}
]

provider = new web3.providers.HttpProvider("http://#{config.private_eth.host}:#{config.private_eth.port}")
coinbase = "0x0"

async.series [
  (c) ->
    # Working around this bug in web3:
    # https://github.com/ethereum/web3.js/issues/156
    console.log "Getting coinbase..."
    provider.sendAsync
      jsonrpc: "2.0"
      method: "eth_coinbase"
      params: []
      id: 1
    , (err, result) ->
      coinbase = result.result
      c()

  (c) ->
    # Compile the contracts
    async.mapSeries contracts, (contract, callback) ->
      file = contract.file
      console.log "Compiling #{file}..."
      child_process.exec "solc --input-file #{file} --json-abi stdout --binary stdout --optimize on 2>&1", 
        cwd: process.cwd()
      , (err, stdout) ->
        if err?
          callback(err, stdout)
        else
          # We expect repeatable, structured output from solc. This isn't my favorite
          # way of doing things, and could be better if I got web3.eth.compile.solidity working.
          stdout = stdout.trim().split("\n")
          code = stdout[2]
          stdout.splice(0, 4)
          abi = stdout.join("\n")
          contract.code = code
          contract.abi = JSON.parse(abi)
          callback(null, contract)
          #callback(null, stdout)
    , (err, results) ->
      if err?
        console.log "ERROR compiling contract:"
        console.log results[0]
        process.exit(1)
      else
        contracts = results
        c()
  (c) ->
    # Put them on the network
    async.mapSeries contracts, (contract, callback) ->
      console.log "Sending #{contract.file} to the network..."
      code = contract.code
      # web3.eth.sendTransaction doesn't seem to work...
      provider.sendAsync
        jsonrpc: "2.0"
        method: "eth_sendTransaction"
        params: [{
          from: coinbase
          gas: web3.toHex(100000) # I have no idea if these values are good.
          gasPrice: web3.toHex(10000),
          data: "0x#{code}"
        }]
        id: 1
      , (err, result) ->
        if err?
          callback(err, result)
        else
          if result.error?
            console.log "Error received from eth client:"
            console.log result
            process.exit(1)

          contract.address = result.result
          callback(err, contract)

    , (err, results) ->
      if err?
        console.log "ERROR sending contract:"
        c(err)
      else
        contracts = results
        c()
], (err) ->
  console.log "Writing contract config..."

  addresses = {}
  for contract in contracts
    addresses[contract.name] = 
      address: contract.address
      abi: contract.abi

  fs.writeFileSync(process.cwd() + "/config/contracts.json", JSON.stringify(addresses), {flag: "w+"})

  console.log "Done!"



