#
# run ./config/import-firewall-rules.sh
#

p 1 firewall add default 1 #SINK0
p 1 firewall add bulk ./config/firewall-rules.txt
