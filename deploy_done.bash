echo remove ssh access
echo "$(grep -v "`cat ~/.ssh/reverse_rsa.pub`" ~/.ssh/authorized_keys)" > ~/.ssh/authorized_keys
echo run finish.bash as root on each host
