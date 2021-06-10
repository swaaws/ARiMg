#!/bin/bash
clear
cat ~/pending_store | awk '{print $10}'
echo ----------------
echo Hosts in File: `grep -o -i "hostname:" ~/pending_store | wc -l`
echo Press [a] generate ansible host inventory.
echo Press [p] generate puppet host inventory.
echo Press [c] generate chef host inventory.
echo Press [n] clear file.
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
      echo Press [a] generate ansible host inventory.
      echo Press [p] generate puppet host inventory.
      echo Press [c] generate chef host inventory.
      echo Press [n] clear file.
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
            h) trapKey=hosts ;;
            n) trapKey=dropfile ;;
            q | $'\E') loop=false  ;;
        esac
    fi
    if [ "$trapKey" ]; then
        case $trapKey in
          hosts)
              echo "Create Hostsfile"
              while read p; do
                  echo "$p" | awk '{print $10, $6}' | rev | cut -c4- | rev >>  tmp.hosts
              done <~/pending_store

              mv tmp.hosts pending.hosts
              echo "pending.hosts Created"
              ;;

            ansible)
                echo "Create ansible inventory"
                echo > pending.ansible.inv

                echo
                while read p; do
                    echo "$p" | awk '{print "["$10"]"}' | sed 's/://g' >> pending.ansible.inv
                    echo "$p" | awk '{print $6}' | rev | cut -c4- | rev  >> pending.ansible.inv
                    echo "" >> pending.ansible.inv
                done <~/pending_store
                ansible-inventory -i pending.ansible.inv --list -y > pending.ansible.yaml
                rm pending.ansible.inv
                echo "pending.ansible.yaml Created"
                echo "ansible-playbook ansible/01_spinup.yml -i pending.ansible.yaml"


                ;;

            puppet)
                echo ""

                ;;

            chef)
                echo ""
                ;;

            dropfile)
                clear
                echo "file droped"
                echo > ~/pending_store
                cat ~/pending_store | awk '{print $10}'
                echo ----------------
                echo Hosts in File: `grep -o -i "hostname:" ~/pending_store | wc -l`
                echo Press [a] generate ansible host inventory.
                echo Press [p] generate puppet host inventory.
                echo Press [c] generate chef host inventory.
                echo Press [n] clear file.
                echo Press [q] when the number of hosts is correct.
                ;;
        esac
  fi


done
