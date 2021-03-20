# Building k3OS images via packer

> [k3OS](https://github.com/rancher/k3os) is a Linux distribution designed to remove as much OS maintenance as possible in a Kubernetes cluster. It is specifically designed to only have what is needed to run [k3s](https://github.com/rancher/k3s).

This setup uses packer to build VM images on two platforms:
- Proxmox (production bare-metal VM cluster)
- Virtualbox (for local testing)

## Configuration

Build parameters can be found in the variables in `k3os.pkr.hcl`.

The k3OS base config is in `config` for the respective environments.

## Usage

## Local testing

Although we don't run any provisioners, Virtualbox needs SSH to determine
when the install is finished.

In order to use this, put your github user name or pubkey into `config/local.yaml`.
Make sure you have a local ssh agent with your key running.

Running the local build:
```sh
packer build -only virtualbox-iso.local-vbox k3os.pkr.hcl
```

## Production

Running the production build:
_Only for reference, please use the [Github Actions CI flow](.github/workflows/packer.yml) instead!_

```sh
export PROXMOX_USERNAME=<USER>
export PROXMOX_PASSWORD=<PASSWORD>

packer build -only proxmox-iso.proxmox k3os.pkr.hcl
```

### Updating the k3os Release

Since the Proxmox API won't accept an ISO upload from packer, the ISO needs to be uploaded manually in Proxmox.
This can be done using the UI (very slow) or via curl on the host system:

```sh
export K3OS_VERSION=v0.19.5-rc.1
curl -L \
  -o /var/lib/vz/template/iso/k3os-amd64-${K3OS_VERSION}.iso \
  https://github.com/rancher/k3os/releases/download/${K3OS_VERSION}/k3os-amd64.iso
```

You can then adjust the `k3os_version` and `iso_checksum` packer variables to build based on the new version.
