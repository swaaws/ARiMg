#!/bin/bash
clear
cat ~/pending_store
echo Hosts in File: `grep -o -i "hostname:" ~/pending_store | wc -l`
echo Press [q] when the number of hosts is correct.
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
    echo -n .
    if [ -f ~/pending ]; then
      cat ~/pending >> ~/pending_store
      sort ~/pending_store > ~/pending_store.tmp
      uniq  ~/pending_store.tmp ~/pending_store.now
      mv ~/pending_store.now ~/pending_store
      clear
      cat ~/pending_store
      echo Hosts in File: `grep -o -i "hostname:" ~/pending_store | wc -l`
      echo Press [q] when the number of hosts is correct.
      rm ~/pending
      rm ~/pending_store.tmp
    fi
    sleep 5
done
