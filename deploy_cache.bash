#!/bin/bash
clear
cat pending_store
echo Hosts in File: `wc -l pending_store | awk '{print $1}'`

loop=true
while $loop; do
    trapKey=
    if IFS= read -d '' -rsn 1 -t .002 str; then
        while IFS= read -d '' -rsn 1 -t .002 chr; do
            str+="$chr"
        done
        case $str in
            $'\E[A') trapKey=UP    ;;
            $'\E[B') trapKey=DOWN  ;;
            $'\E[C') trapKey=RIGHT ;;
            $'\E[D') trapKey=LEFT  ;;
            q | $'\E') loop=false  ;;
        esac
    fi
    if [ "$trapKey" ] ;then
        printf "\nDoing something with '%s'.\n" $trapKey
    fi
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
