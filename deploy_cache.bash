#!/bin/bash
clear
echo Hosts in File: `wc -l pending_store | awk '{print $1}'`
cat pending_store

while true; do

  if [ -f ~/pending ]; then
    cat ~/pending >> ~/pending_store
    sort ~/pending_store > ~/pending_store.tmp
    uniq  ~/pending_store.tmp ~/pending_store.now
    clear
    echo Hosts in File: `wc -l pending_store.now | awk '{print $1}'`
    cat pending_store.now
    rm ~/pending
    cp ~/pending_store.now ~/pending_store
    rm ~/pending_store.tmp
    rm ~/pending_store.now
  fi


sleep 5
done
