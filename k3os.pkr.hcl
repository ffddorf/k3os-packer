variable "config_url" {
  type    = string
  default = "https://gist.github.com/mraerino/15221a3f83b80c43f05237591e49921f/raw/064d9207ad7df54a47e35cd5d6846c1d78ef1300/k3os-ffddorf.yaml"
}

variable "iso_checksum" {
  type    = string
  default = "fa4d95676ddf94b8a5488781c638ca13b6c532ea06bb74d2bcefd194b5ce760b"
}

variable "k3os_version" {
  type    = string
  default = "v0.19.5-rc.1"
}

variable "storage_pool" {
  type    = string
  default = "local"
}

variable "git_ref" {
  type    = string
  default = "unknown"
}

variable "git_sha" {
  type    = string
  default = "unknown"
}

locals {
  boot_command_pre  = ["<wait>", "<tab>", "<down>", "<wait>", "e", "<down>", "<down>", "<down>", "<down>", "<down>", "<down>", "<end>"]
  boot_command_args = [" ", "k3os.install.device=/dev/sda", " ", "k3os.mode=install", " ", "k3os.install.silent=true", " ", "k3os.install.debug=true", " ", "k3os.install.power_off=true"]
  boot_command_post = ["<F10>"]
}

source "proxmox-iso" "proxmox" {
  proxmox_url  = "https://pve.freifunk-duesseldorf.de/api2/json"
  node         = "pm2"
  pool         = "Packer"
  communicator = "none"
  boot_command = concat(local.boot_command_pre, local.boot_command_args, [" ", "k3os.install.config_url=${var.config_url}"], local.boot_command_post)

  template_name        = "k3os-${var.k3os_version}"
  template_description = <<EOF
    k3os ${var.k3os_version}
    generated on ${timestamp()}"
    git ref: ${var.git_ref}
    git sha: ${var.git_sha}
  EOF

  # It's not feasible to upload the ISO to Proxmox during the packer run.
  # Please upload the iso to Proxmox manually when upgrading to a new version.
  iso_file     = "local:iso/k3os-amd64-${var.k3os_version}.iso"
  iso_checksum = "sha256:${var.iso_checksum}"

  os          = "l26"
  memory      = "2048"
  cloud_init  = false
  unmount_iso = true

  disks {
    disk_size         = "4G"
    format            = "qcow2"
    storage_pool      = var.storage_pool
    storage_pool_type = "directory"
    type              = "scsi"
  }

  network_adapters {
    bridge = "vmbr0"
  }
}

source "virtualbox-iso" "local-vbox" {
  guest_os_type   = "Linux26_64"
  keep_registered = true

  iso_checksum = "sha256:${var.iso_checksum}"
  iso_url      = "https://github.com/rancher/k3os/releases/download/${var.k3os_version}/k3os-amd64.iso"

  boot_command   = concat(local.boot_command_pre, local.boot_command_args, [" ", "k3os.install.config_url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/local.yaml"], local.boot_command_post)
  http_directory = "config"

  # Although we don't run any provisioners, Virtualbox needs SSH to determine
  # when the install is finished.
  # In order to use this, put your github user name or pubkey into `config/local.yaml`.
  # Make sure you have a local ssh agent with your key running.
  ssh_username   = "rancher"
  ssh_agent_auth = true
}

build {
  sources = ["source.proxmox-iso.proxmox", "source.virtualbox-iso.local-vbox"]
}
