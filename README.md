# SPS UCS Bootstrap via Ansible

Ansible playbooks and variables that install, configure and customize the Univention Corporate Server for SPS
environment.

- [Files](#files)
  - [Configurations Files](#configurations-files)
  - [Directories](#directories)
- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Usage](#usage)
- [Accessing the configured stack](#accessing-the-configured-stack)
- [Setup](#setup)
  - [Installation Archive](#installation-archive)
  - [Setting up the Secrets](#setting-up-the-secrets)
- [Maintainer](#maintainer)

## Files

### Configurations Files

* `ansible.cfg` - ansible configuration file tailored to running the playbooks in this repo.
* `requirements.yml` - ansible collections to be installed from external sources, like ansible-galaxy, these should go
  into the `collections-galaxy` directory.

### Directories

* `files` - ansible standard directory containing ssh keys, images and additional files.
* `group_vars` - ansible standard directory where group variables are stored. We use group directories with multiple
  YAML files in them.
* `inventory` - ansible inventory directory, normally contains a dynamic inventory script. See ansible documentation on
  details.
* `collections-galaxy` - ansible roles directory meant for roles maintained by everyone else and normally found on
  galaxy.ansible.org

## Requirements

* `ansible` >= version 2.10
* `python` >= version 3.6
* the `id_rsa_ucs_kvm_image` private ssh key + passphrase
* the ansible `.vault-password-sps` vault passphrase
* [git-lfs](https://git-lfs.github.com/) in order to check out binary files needed for the installation when *not* using
  the [Installation Archive](#installation-archive).

## Dependencies

* [PyPy Openstack](https://pypi.org/project/python-openstackclient/) for the openstack dynamic inventory.
* [Openstack dynamic inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html#inventory-script-example-openstack)
  ffor the openstack dynamic inventory.

The openstack module can be installed into a virtualenv/venv using pip3 or user wide using
`pip3 install --user python-openstackclient`

## Usage

To configure a full server installation:

`ansible-playbook [options] playbook.yml`

To configure a full server installation without let's encrypt:

`ansible-playbook [options] playbook.yml --skip-tags install_lets_encrypt`

To only run UCS configuration after successful run use this:

`ansible-playbook [options] playbook_bootstrap_ucs.yml`

To create and install a new license run:

`ansible-playbook [options] playbook_bootstrap_ucs.yml --tags configure_license`

The commands shown above will run over all available stack machines, which is typically not what you would want. In
order to limit (`--limit/-l`) the ansible run to a single host (stack-001 in this case) use this:

`ansible-playbook [options] -l stack-001 playbook.yml`

`--limit` accepts patterns, which means that you can limit the run to multiple machines. For details please consult
the [ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html). Possible limits
include groups or a list consisting of hosts and groups separated by colons or commas.

## Accessing the configured stack

In order to access the resulting sandbox put your own personal ssh public key into a file in the `files/ssh_keys/add/`
directory, using `.pubkey` as extension. If you wish to add multiple keys put them into multiple files, only a single
key per file is allowed and it needs to be in a single line. If you're replacing a key move the old file to
`files/ssh_keys/remove/` and then add the new key file to the `.../add/` directory. This will allow for the old key to
be removed, else it will remain on the server. After the configuration has succeeded you then should be able to log into
the resulting sandbox using your ssh key. The remote user to use as of the time of writing this is root.

## Setup

There's two ways to set up the ansible installation. You can do it manually or use an installation archive which should
already contain all dependencies with the "secrets" being the exception. Read the section
[Installation Archive](#installation-archive). After reading the respective section please read
[Setting up the Secrets](#setting-up-the-secrets) for instructions common to both installation approaches.


### Installation Archive

Unpack the provided installation archive. To make sure that everything is in order check that the following
files/directories exist:

* `inventory/openstack_inventory.py`
* `collections-galaxy/ansible_collections/univention`

If those exist that's a good indicator that the archive is not faulty.


### Setting up the Secrets

Create `~/.vault-password-sps` with the ansible vault password as its content. This is needed so ansible can decrypt
ansible-vault maintained secrets. It is advised to remove this file once you've successfully run the playbooks you
intended to.

Afterwards you can decrypt the `id_rsa_ucs_kvm_image` ssh key:

```bash
# Decrypt SSH Key
ansible-vault decrypt id_rsa_ucs_kvm_image

# Change permission to comply with ssh client
chmod 0400 id_rsa_ucs_kvm_image
```

At this point all that is left before you can start using the provided playbooks is to set the openstack credentials.

## Known issues

When no application credentials could be generated in openstack, the dynamic inventory is not usable. Therefore, you
have to remove `inventory/openstack_inventory.py` script.

```bash
# In case of manual inventory
rm inventory/openstack_inventory.py
```

## Maintainer

- [Dominik Kaminski](mailto:kaminski@univention.de)
