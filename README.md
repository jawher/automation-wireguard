# Multi server Wireguard mesh with ansible

A playbook which given an inventory file with:

* a list of hosts
    * for each host a `wireguard_ip` variable with the desired host (private) Wireguard IP
* `wireguard_mask_bits` variable with the number of the wireguard (private) network mask bits
* `wireguard_port` variable with the UDP port to use

will:

* install wireguard in all hosts
* generate public/private key pairs in all hosts
* generate the pre-shared keys for all host pairs
* create a `wg0` virtual network device and a `wg0` network

optionally, when the `ufw_enabled` variable is set to `true`:

* enable ufw on all hosts
* reject everything by default
* allow ssh protocol from all sources
* allow traffic from all the inventory wireguard IPs

More details and explanation can be found in this blog post: https://jawher.me/wireguard-ansible-systemd-ubuntu/

## Example

In this example, we'll create 3 Hetzner cloud CX11 servers (~3€/month) using [Hetzner's cli](https://github.com/hetznercloud/cli),
1 in each of their 3 datacenters (Nuremberg, Falkenstein & Helsinki):

```shell
env_id=wireguard-test
server_type=cx11
image=ubuntu-20.04

args=()

for k in $(hcloud ssh-key list -o=noheader -ocolumns=name); do
  args+=("--ssh-key=$k")
done

for datacenter in nbg1-dc3 fsn1-dc14 hel1-dc2; do
    hcloud server create "${args[@]}" \
    --datacenter="${datacenter}" \
    --type="${server_type}" \
    --image="${image}" \
    --label=env="${env_id}" \
    --name="${env_id}-${datacenter}"
done
```


### Inventory

Next you need to prepapre an inventory file with the 3 servers we created in `inventories/inventory.yml`:

Run `hcloud server list -l env=wireguard-test`:

```
ID         NAME                       STATUS    IPV4             IPV6                      DATACENTER
10889123   wireguard-test-nbg1-dc3    running   xxx.xx.xxx.xx    2a01:xxxx:xxxx:xxxx::/64   nbg1-dc3
10889126   wireguard-test-fsn1-dc14   running   xxx.xx.xxx.xxx   2a01:xxxx:xxxx:xxxx::/64   fsn1-dc14
10889127   wireguard-test-hel1-dc2    running   xx.xxx.xx.xxx    2a01:xxxx:xxxx:xxxx::/64   hel1-dc2
```

And use the server names and IPv4s to build your inventory:

```yml
all:
  hosts:

    host1:
      pipelining: true
      ansible_ssh_user: root
      ansible_host: "$host1_public_ip"
      ansible_ssh_port: 22

      wireguard_ip: 192.168.0.1

    host2:
      pipelining: true
      ansible_ssh_user: root
      ansible_host: "$host2_public_ip"
      ansible_ssh_port: 22

      wireguard_ip: 192.168.0.2

    host3:
      pipelining: true
      ansible_ssh_user: root
      ansible_host: "$host3_public_ip"
      ansible_ssh_port: 22

      wireguard_ip: 192.168.0.3

  vars:
    ansible_become_method: su 

    wireguard_mask_bits: 24
    wireguard_port: 51871
```

### Apply

Run `make apply`

### Test connectivity

Run `make test`, which will perform ping tests between the 3 servers using their wireguard private IPs.

You could also ssh to each/any host and run `ping` manually if you prefer.
