# UCS KVM Image with SSH/Password

This tool creates a KVM `qcow2` image with SSH Key and password for root.

## Requirements

- `curl`
- `libguestfs-tools`

## Execution

**Attention: The script has to executed in this (`docs/image`) and not from any other location**

```shell
./ucs_image_guestfish.sh
```

The result should look like:

```text
######################################################
#                                                    #
# SSH login credentials:                             #
# ----------------------                             #
# user: root                                         #
# pw:   MGVmYjQxYjJlMGMzZDJlNGMzZTI1Yzk2             #
#                                                    #
######################################################

######################################################
# SSH root password path                             #
######################################################
Root password: /home/SovereignProductivitySuite/sps/files/image_root_password

######################################################
# SSH Keypair path                                   #
######################################################
Private key: /home/SovereignProductivitySuite/sps/files/id_ed25519_ucs_kvm_image
Public key:  /home/SovereignProductivitySuite/sps/files/id_ed25519_ucs_kvm_image.pub

######################################################
# Image finished                                     #
######################################################
```

## Author
Univention GmbH