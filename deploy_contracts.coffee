#!/usr/bin/env ./node_modules/.bin/coffee

web3 = require "web3"
async = require "async"
fs = require "fs"
loadconfig = require("./lib/loadconfig")
execSync = require("child_process").execSync

config = loadconfig("/config/config.json")

console.log "asdf"
child = execSync "echo 'asdfasd'", (a, b, c) ->
  console.log child
  console.log a, b, c
  console.log child.stdout.read()


console.log "dddd"

contracts = [
  "./contracts/seusscoin.sol"
]

# console.log "Setting provider..."
web3.setProvider(new web3.providers.HttpProvider("http://#{config.private_eth.host}:#{config.private_eth.port}"))

# Compile the contracts
async.mapSeries contracts, (file, callback) ->
  console.log "Compiling #{file}..."
  command = "solc --input-file #{file} --binary stdout --optimize on"
  console.log command
  console.log "----------"
  exec("ls", (a, b, c) ->
    console.log "a: " + a
    console.log "b: " + b
    console.log "c: " + c
    callback(a, b)
  )
, (err, results) ->
  if err?
    console.log "ERROR compiling contract:"
    console.log results[0]
    process.exit(1)

  console.log results

console.log "done"

# # Put them on the network
# console.log "Sending contracts to the network..."
# async.eachSeries contracts, (code, callback) ->
#   web3.eth.sendTransaction 
#     from: web3.eth.coinbase
#     code: code
#   , callback
# , (err, results) ->
#   if err?
#     console.log "ERROR sending contract:"
#     thorw err
#   else
#     console.log results

# Web3 keeps the process open (Note: I *think* it's web3...)
process.exit(0)



