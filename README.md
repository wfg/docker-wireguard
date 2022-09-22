# WireGuard client for Docker
## What is this and what does it do?
`wireguard` is exactly what it says on the tin (a containerized WireGuard client).
It has a built-in kill switch to stop Internet connectivity if the VPN goes down for any reason.

## Why?
Having a containerized VPN client lets you use container networking to easily choose which applications you want using the VPN instead of having to set up split tunnelling.

## How do I use it?
### Getting the image
You can either pull it from GitHub Container Registry or build it yourself.

To pull it from GitHub Container Registry, run
```
docker pull ghcr.io/wfg/wireguard
```

To build it yourself, run
```
docker build -t ghcr.io/wfg/wireguard https://github.com/wfg/docker-wireguard.git#:build
```

### Creating and running a container
Below are bare-bones examples for `docker run` and Compose; however, you'll probably want to do more than just run the VPN client.
See the sections below to learn how to have [other containers use `wireguard`'s network stack](#using-with-other-containers).

#### `docker run`
```
docker run --detach \
  --name wireguard \
  --cap-add NET_ADMIN \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  --volume <path/to/config>:/etc/wireguard/wg0.conf \
  ghcr.io/wfg/wireguard
```

#### `docker-compose`
```yaml
services:
  wireguard:
    image: ghcr.io/wfg/wireguard
    container_name: wireguard
    cap_add:
    - NET_ADMIN
    sysctls:
    - net.ipv4.conf.all.src_valid_mark=1
    volumes:
    - <path/to/config>:/etc/wireguard/wg0.conf
    restart: unless-stopped
```

#### Environment variables
| Variable | Default (blank is unset) | Description |
| --- | --- | --- |
| `ALLOWED_SUBNETS` |  | A list of one or more comma-separated subnets (e.g. `192.168.0.0/24,192.168.1.0/24`) to allow outside of the VPN tunnel. |

##### Environment variable considerations
###### `ALLOWED_SUBNETS`
If you intend on connecting to containers that use the WireGuard container's network stack (which you probably do), **you will want to use this variable**.

### Using with other containers
Once you have your `wireguard` container up and running, you can tell other containers to use `wireguard`'s network stack which gives them the ability to utilize the VPN tunnel.
There are a few ways to accomplish this depending how how your container is created.

If your container is being created with
1. the same Compose YAML file as `wireguard`, add `network_mode: service:wireguard` to the container's service definition.
2. a different Compose YAML file than `wireguard`, add `network_mode: container:wireguard` to the container's service definition.
3. `docker run`, add `--network=container:wireguard` as an option to `docker run`.

Once running and provided your container has `wget` or `curl`, you can run `docker exec <container_name> wget -qO - ifconfig.me` or `docker exec <container_name> curl -s ifconfig.me` to get the public IP of the container and make sure everything is working as expected.
This IP should match the one of `wireguard`.

#### Handling ports intended for connected containers
If you have a connected container and you need to access a port that container, you'll want to publish that port on the `wireguard` container instead of the connected container.
To do that, add `-p <host_port>:<container_port>` if you're using `docker run`, or add the below snippet to the `wireguard` service definition in your Compose file if using `docker-compose`.
```yaml
ports:
  - <host_port>:<container_port>
```
In both cases, replace `<host_port>` and `<container_port>` with the port used by your connected container.

### Verifying functionality
Once you have container running `ghcr.io/wfg/wireguard`, run the following command to spin up a temporary container using `wireguard` for networking.
The `wget -qO - ifconfig.me` bit will return the public IP of the container.
You should see an IP address owned by your VPN provider.
```bash
docker run --rm -it --network=container:wireguard alpine wget -qO - ifconfig.me
```
