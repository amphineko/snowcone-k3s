## Short Description

A 3-node High-Availability Kubernetes cluster by Fedora CoreOS, Libvirt and K3s.

- etcd instances are external to K3s, and installed on all master nodes.
- CoreOS is used for automated provisioning and upgrading
- Fleet communication (etcd and flannel) is done via dedicated virtual network.

## Requirements

- Libvirt with QEMU (or other machine types can attach Ignition files, see [CoreOS provisioning guide](https://docs.fedoraproject.org/en-US/fedora-coreos/provisioning-qemu/))
- Fedora CoreOS
- Docker or other container runtimes (to run [Butane](https://docs.fedoraproject.org/en-US/fedora-coreos/producing-ign/#_getting_butane) and [Mustache](https://github.com/cbroglie/mustache))

## Getting Started

### 1. Populate node configurations

Example node properties are located under `inputs` directories. Make copies and rename into `common.yml` and `master<id>.yml`.

```
inputs
|- common.yml
|- master1.yml
|- master2.yml
\- master3.yml
...
```

### 2. Download Fedora CoreOS

Stable CoreOS images can be retrieved from [their Download page](https://fedoraproject.org/coreos/download?stream=stable). 

```
tools
\- fedora-coreos-39.20240112.3.0-qemu.x86_64.qcow2
...
```

### 3. Regenerate K3s tokens and CoreOS credentials

Modify `inputs/common.yml` to populate the K3s token and login credentials

```yaml
...

k3s_token: `{{ result of openssl rand -hex 16 }}`

...

user:
  name: "{{ your username here }}"
  password_hash: "{{ result of `podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt` }}"
  ssh_authorized_key: "{{ your ssh public key }}"

...
```

### 4. Locate your CoreOS base image and virtual machine storages

Modify `inputs/common.yml` to populate your working directories.

```yaml
...

libvirt_disk_base: "{{ location of coreos qcow2, example `/home/amphineko/downloads/fedora-coreos-39.20240112.3.0-qemu.x86_64.qcow2` }}"
libvirt_storage_base: "{{ location to store virtual machines, example `/mnt/vms` }}"

...
```

Virtual machines will be stored as following structure:
                        
```
/mnt/vms
|- snowecone-master1
  |- disk.qcow2         # overlay disk image
  |- domain.xml         # libvirt domain spec
  \- ignition.json      # ignition config for coreos
|- snowcone-master2
...
```

### 4. Create Libvirt networks

Two networks are required:
- `default`: the NAT network shipped with Libvirt by default, used for Internet access
- `virbr1`: Linux bridged network for inter-fleet communications (etcd and flannel)

`virbr1` can be simply created with `brctl addbr virbr1 && ip link set up dev virbr1`.

Please refer to Libvirt's document on [Virtual Networking](https://wiki.libvirt.org/VirtualNetworking.html) for details.

### 5. Generate disk images, Libvirt domain specs and Ignition files

Related files will be generated, and the virtual machines will be added to Libvirt.

```
$ make all
```

In case of need to reset disk images,

```
$ make vms/snowcone-master1/disk.qcow2 -B
```

### 6. Start virtual machines
