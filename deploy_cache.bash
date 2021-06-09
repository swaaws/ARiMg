#!/bin/bash
clear
cat ~/pending_store | awk '{print $10}'
echo ----------------
echo Hosts in File: `grep -o -i "hostname:" ~/pending_store | wc -l`
echo Press [q] when the number of hosts is correct.
loop=true
while $loop; do
    trapKey=
    if [ -f ~/pending ]; then
      cat ~/pending >> ~/pending_store
      sort ~/pending_store > ~/pending_store.tmp
      uniq  ~/pending_store.tmp ~/pending_store.now
      mv ~/pending_store.now ~/pending_store
      clear
      cat ~/pending_store | awk '{print $10}'
      echo ----------------
      echo Hosts in File: `grep -o -i "hostname:" ~/pending_store | wc -l`
      echo Press [q] when the number of hosts is correct.
      rm ~/pending
      rm ~/pending_store.tmp
    fi
    if IFS= read -d '' -rsn 1 -t .002 str; then
        while IFS= read -d '' -rsn 1 -t .002 chr; do
            str+="$chr"
        done
        case $str in
            a) trapKey=ansible    ;;
            p) trapKey=puppet  ;;
            c) trapKey=chef ;;
            q | $'\E') loop=false  ;;
        esac
    fi
    if [ "$trapKey" ]; then
        case $trapKey in

            ansible)
                echo "ansible"

                ;;

            puppet)
                echo "puppet"

                ;;

            chef)
                echo "chef"
                ;;
        esac
  fi


done
