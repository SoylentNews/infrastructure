./setup-env.sh
sudo iptables -t nat -A POSTROUTING -s 192.168.203.0/24 ! -o br-2747fbf40960 -j SNAT --to-source $BIND_IPV4
sudo ip6-tables -t nat -A POSTROUTING -s fd84:21df:8ee:beef::/64 ! -o br-2747fbf40960 -j SNAT --to-source $BIND_IPV6
