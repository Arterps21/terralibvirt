terraform {
        required_providers {
                libvirt = {
                        source = "dmacvicar/libvirt"
                        version = "~> 0.8.1"
                }
        }
}



variable "VM_COUNT" {
        default = 3
        type = number
}

variable "VM_USER" {
        default = "developer"
        type = string
}

variable "VM_HOSTNAME" {
        default = "vm"
        type = string
}

variable "VM_IMG_URL" {
        default = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
        type = string
}

variable "VM_IMG_FORMAT" {
        default = "qcow2"
        type = string
}

variable "VM_CIDR_RANGE" {
        default = "10.10.10.10/24"
        type = string
}

provider "libvirt" {
        uri = "qemu:///system"
}


resource "libvirt_pool" "vm" {
        name = "${var.VM_HOSTNAME}_pool"
        type = "dir"
        path = "/var/lib/libvirt/images/terraform-provider-libvirt-pool-ubuntu"
}

resource "libvirt_volume" "vm" {
        count = var.VM_COUNT
        name = "${var.VM_HOSTNAME}-${count.index}_volume.${var.VM_IMG_FORMAT}"
        pool = libvirt_pool.vm.name
        source = var.VM_IMG_URL
        format = var.VM_IMG_FORMAT
}

resource "libvirt_network" "vm_public_network" {
        name = "${var.VM_HOSTNAME}_network"
        mode = "nat"
        domain = "${var.VM_HOSTNAME}.local"
        addresses = ["${var.VM_CIDR_RANGE}"]
        dhcp {
                enabled = true
        }
        dns {
                enabled = true
        }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "${var.VM_HOSTNAME}_cloudinit.iso"
  user_data      = templatefile("${path.module}/cloud_init.cfg", { VM_USER = var.VM_USER })
  network_config = templatefile("${path.module}/network_config.cfg", {})
  pool           = libvirt_pool.vm.name
}

resource "libvirt_domain" "vm" {
        count = var.VM_COUNT
        name = "${var.VM_HOSTNAME}=${count.index}"
        memory = "1024"
        vcpu = 1

        cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"

        # TODO: Automate the creation of public network
        network_interface {
                network_id = "${libvirt_network.vm_public_network.id}"
                network_name = "${libvirt_network.vm_public_network.name}"
        }

        console {
                type = "pty"
                target_port = "0"
                target_type = "serial"
        }

        disk {
                volume_id = "${libvirt_volume.vm[count.index].id}"
        }

        graphics {
                type = "spice"
                listen_type = "address"
                autoport = true
        }
}
