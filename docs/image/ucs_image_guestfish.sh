#!/bin/bash
set +x

UCS_DEPLOY_IMAGE_ROOT_FOLDER=$(builtin cd ../../; pwd)

# Check if image is available
if [ ! -f UCS-4.4-KVM-Image.qcow2 ]; then
  curl https://updates.software-univention.de/download/images/UCS-4.4-KVM-Image.qcow2 -o UCS-4.4-KVM-Image.qcow2
fi

# Generate SSH Keypair
if [ ! -f  "${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/id_ed25519_ucs_kvm_image" ] || [ ! -f  "${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/id_ed25519_ucs_kvm_image.pub"  ]; then
  ssh-keygen -t ed25519 -f "${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/id_ed25519_ucs_kvm_image" -N ""
fi
UCS_DEPLOY_IMAGE_ROOT_PUB_KEY=$(cat "${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/id_ed25519_ucs_kvm_image.pub")

# Generate root password
if [ ! -f ../../files/image_root_password ]; then
  date +%s | sha256sum | base64 | head -c 32  > "${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/image_root_password"

fi
UCS_DEPLOY_IMAGE_ROOT_PASSWORD=$(cat "${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/image_root_password")

sudo guestfish --rw -x -a UCS-4.4-KVM-Image.qcow2<<_EOF_
run
mount /dev/vg_ucs/root /

# Change root password
echo "${UCS_DEPLOY_IMAGE_ROOT_PASSWORD}\n${UCS_DEPLOY_IMAGE_ROOT_PASSWORD}" | passwd root

# Copy public SSH Key to image
mkdir-p /root/.ssh
write /root/.ssh/authorized_keys "${UCS_DEPLOY_IMAGE_ROOT_PUB_KEY}"

# Await DHCP on eth0 network interface
sh "ucr set interfaces/eth0/type=dhcp"

# Use ethX instead of ensX interface
sh "ucr set grub/append='net.ifnames=0 biosdevname=0'"

# Create a new machine-id on boot
rm-f /etc/machine-id /var/lib/dbus/machine-id
exit
_EOF_

echo ""
echo "######################################################"
echo "#                                                    #"
echo "# SSH login credentials:                             #"
echo "# ----------------------                             #"
echo "# user: root                                         #"
echo "# pw:   ${UCS_DEPLOY_IMAGE_ROOT_PASSWORD}             #"
echo "#                                                    #"
echo "######################################################"
echo ""
echo "######################################################"
echo "# SSH root password path                             #"
echo "######################################################"
echo "Root password: ${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/image_root_password"
echo ""
echo "######################################################"
echo "# SSH Keypair path                                   #"
echo "######################################################"
echo "Private key: ${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/id_ed25519_ucs_kvm_image"
echo "Public key:  ${UCS_DEPLOY_IMAGE_ROOT_FOLDER}/files/id_ed25519_ucs_kvm_image.pub"
echo ""
echo "######################################################"
echo "# Image finished                                     #"
echo "######################################################"