# Building k3OS images via packer

> [k3OS](https://github.com/rancher/k3os) is a Linux distribution designed to remove as much OS maintenance as possible in a Kubernetes cluster. It is specifically designed to only have what is needed to run [k3s](https://github.com/rancher/k3s).

This setup uses packer to build VM images on two platforms:
- Proxmox (production bare-metal VM cluster)
- Virtualbox (for local testing)

## Configuration

Build parameters can be found in the variables in `k3os.pkr.hcl`.

The k3OS base config is in `config` for the respective environments.

## Usage

Running the local build:
```sh
packer build -only virtualbox-iso.local-vbox k3os.pkr.hcl
```

Running the production build:
_Only for reference, please use the Github Actions CI flow instead!_

```sh
export PROXMOX_USERNAME=<USER>
export PROXMOX_PASSWORD=<PASSWORD>

packer build -only proxmox-iso.proxmox k3os.pkr.hcl
```
