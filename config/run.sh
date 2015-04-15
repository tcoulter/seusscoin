#!/bin/bash

cd /src

# Compile the assets if they're not yet compiled.
# Do this in parallel with server start. 
lines="`redis-cli keys \* | wc -l`"
if [ $lines == "1" ]
  then
    ./compile_assets.coffee &
fi

./server.coffee
