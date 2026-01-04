# IRAN Docker

A simple and powerful Bash script to simplify Docker usage on Iranian servers.

## Features

* Easily switch between popular DNS providers (Shecan, Radar, Begzar, Google, etc.)
* Automated Docker installation and setup
* Apply Iranian Docker registry mirrors (ArvanCloud, Haiocloud, Iranserver, etc.)
* Auto-select fastest Docker registry mirror
* DNS auto-backup before changes
* Support for Debian/Ubuntu systems

## Usage

```bash
git clone https://github.com/Linuxmaster14/iran-docker.git
cd iran-docker
chmod +x iran-docker.sh
sudo ./iran-docker.sh
```

## Menu Options

1) Set DNS
2) Install Docker
3) Update Docker
4) Set Docker Proxy
5) Exit

## Supported DNS Providers

* Shecan
* Radar
* Electro
* Begzar
* DNSPro
* 403
* DynX
* Google
* Cloudflare

## Supported Docker Proxies

* docker.kernel.ir
* focker.ir
* registry.docker.ir
* docker.arvancloud.ir
* docker.haiocloud.com
* docker.iranserver.com
* docker.mobinhost.com
* hub.mecan.ir
* Auto-select fastest proxy (Benchmark)

These proxies are applied to /etc/docker/daemon.json and the Docker service will be restarted automatically.

## License

MIT – free for personal and commercial use.
See [`LICENSE`](./LICENSE) for details.

## Author

Made with [Linuxmaster14](https://github.com/Linuxmaster14)
