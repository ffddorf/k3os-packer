variable "config_url" {
  type    = string
  default = "https://gist.github.com/mraerino/15221a3f83b80c43f05237591e49921f/raw/064d9207ad7df54a47e35cd5d6846c1d78ef1300/k3os-ffddorf.yaml"
}

variable "iso_checksum" {
  type    = string
  default = "30d676374666ad435aa607c18d664ecf1a4eb5fa5d0ff7f6798b43a259e5d600"
}

variable "k3os_version" {
  type    = string
  default = "v0.20.4-k3s1r0-patched"
}

variable "storage_pool" {
  type    = string
  default = "system"
}

variable "target_node" {
  type    = string
  default = "pm2"
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
  boot_command_pre = ["<wait>", "<tab>", "<down>", "<wait>", "e", "<down>", "<down>", "<down>", "<down>", "<down>", "<down>", "<end>"]
  boot_command_args = [
    " ", "k3os.install.device=/dev/sda",
    " ", "k3os.install.silent=true",
    " ", "k3os.install.debug=true",
  ]
  boot_command_args_proxmox = [
    " ", "k3os.install.power_off=true",
    " ", "k3os.install.config_url=${var.config_url}",
    " ", "k3os.install.tty=ttyS0"
  ]
  boot_command_post = [
    "<F10>",
    # packer attempts to shut the VM down directly after booting
    # but we need to wait for it to run the installation first
    "<wait30s>"
  ]
}

source "proxmox-iso" "proxmox" {
  proxmox_url  = "https://pve.freifunk-duesseldorf.de/api2/json"
  node         = var.target_node
  pool         = "Packer"
  communicator = "none"
  qemu_agent   = true
  boot_command = concat(local.boot_command_pre, local.boot_command_args, local.boot_command_args_proxmox, local.boot_command_post)
  boot_wait    = "5s"

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
    model  = "virtio"
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
