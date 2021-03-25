INVENTORY = inventory

apply:
	ansible-playbook -i "inventories/${INVENTORY}.yml" "wireguard.yml"

test:
	ansible-playbook -i "inventories/${INVENTORY}.yml" "ping.yml"
