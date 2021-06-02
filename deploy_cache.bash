#!/bin/bash
clear
cat pending_store
echo Hosts in File: `wc -l pending_store | awk '{print $1}'`

while true; do

  if [ -f ~/pending ]; then
    cat ~/pending >> ~/pending_store
    sort ~/pending_store > ~/pending_store.tmp
    uniq  ~/pending_store.tmp ~/pending_store.now
    clear
    cat pending_store.now
    echo Hosts in File: `wc -l pending_store.now | awk '{print $1}'`
    rm ~/pending
    cp ~/pending_store.now ~/pending_store
    rm ~/pending_store.tmp
    rm ~/pending_store.now
  fi


sleep 5
done
