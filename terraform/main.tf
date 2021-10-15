terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.44.0"
    }
    desec = {
      source = "Valodim/desec"
      version = "0.2.1"
    }
  }
  #backend "http" {
  #}
}

####################################################
# Network                                          #
####################################################
data "openstack_networking_network_v2" "net-sps" {
  # The name of the network [string].
  name = "kd500884-SPS_Univention-network"

  # The ID of the network [string].
  network_id = "03745769-5830-4081-9451-f794a5c8a7b7"
}

####################################################
# Security                                         #
####################################################
data "openstack_networking_secgroup_v2" "sps-security" {

  # The name of the security group [string].
  name = "sps-security"

  # The ID of the security group [string].
  secgroup_id = "5b688892-7bbe-485c-8329-331eef4b0843"
}

####################################################
# Image                                            #
####################################################
data "openstack_images_image_v2" "ucs-4" {
  # The name of the image [string].
  name        = "UCS-4.4-8"

  # If more than one result is returned, use the most recent image [string].
  most_recent = true

  # a map of key/value pairs to match an image with. All specified properties
  # must be matched. Unlike other options filtering by properties does by client
  # on the result of OpenStack search query. Filtering is applied if server
  # responce contains at least 2 images. In case there is only one image the
  # properties ignores [map].
  properties = {
    os_hash_value = "4a8ca9d50083a0caac7a9c51cabed889f8ebc3ec1341ea04fcbac1eb2768499e92d09f1649540704f9c6955db98c4d7902202fc3ee060696ea3bffba1935554f"
  }
}

####################################################
# Flavor                                           #
####################################################
data "openstack_compute_flavor_v2" "stack-flavor" {
  # The name of the flavor. Conflicts with the flavor_id.
  name = "2C-8GB-20GB"
}

####################################################
# Server                                           #
####################################################
resource "openstack_compute_instance_v2" "stack" {
  # The name of the server [string].
  name             = "${var.dns-slug}.sovereignproductivitysuite.de"

  # The flavor ID of the desired flavor for the server. Changing this resizes
  # the existing server [string].
  flavor_id     = data.openstack_compute_flavor_v2.stack-flavor.id

  # An array of one or more security group names to associate with the server.
  # Changing this results in adding/removing security groups from the existing
  # server. Note: When attaching the instance to networks using Ports, place
  # the security groups on the Port and not the instance. Note: Names should be
  # used and not ids, as ids trigger unnecessary updates.
  security_groups = [
    data.openstack_networking_secgroup_v2.sps-security.name
  ]

  # An array of one or more networks to attach to the instance. The network
  # object structure is documented below. Changing this creates a new server.
  network {
    # (Required unless port or name is provided) The network UUID to attach to
    # the server. Changing this creates a new server [string].
    uuid = data.openstack_networking_network_v2.net-sps.id
  }

  block_device {
    # The boot index of the volume. It defaults to 0. Changing this creates a
    # new server [number]
    boot_index            = 0

    # Delete the volume / block device upon termination of the instance.
    # Defaults to false. Changing this creates a new server [boolean]
    delete_on_termination = true

    # The source type of the device. Must be one of "blank", "image", "volume",
    # or "snapshot". Changing this creates a new server [string].
    source_type           = "image"

    # The type that gets created. Possible values are "volume" and "local".
    # Changing this creates a new server [string].
    destination_type      = "volume"

    # The size of the volume to create (in gigabytes). Required in the following
    # combinations: source=image and destination=volume, source=blank and
    # destination=local, and source=blank and destination=volume. Changing this
    # creates a new server [number].
    volume_size           = "20"

    # The UUID of the image, volume, or snapshot. Changing this creates a new
    # server [string].
    uuid                  = data.openstack_images_image_v2.ucs-4.id
  }
}

####################################################
# Floating IP                                      #
####################################################

resource "openstack_networking_floatingip_v2" "stack-ip" {

  # The name of the pool from which to obtain the floating IP. Changing this
  # creates a new floating IP.
  pool = "ext01"

}

####################################################
# Floating IP                                      #
####################################################

resource "openstack_compute_floatingip_associate_v2" "stack-ip" {
  # The floating IP to associate [string].
  floating_ip = openstack_networking_floatingip_v2.stack-ip.address

  # The instance to associte the floating IP with [string].
  instance_id = openstack_compute_instance_v2.stack.id

  # In cases where the OpenStack environment does not automatically wait until
  # the association has finished, set this option to have Terraform poll the
  # instance until the floating IP has been associated. Defaults to false.
  wait_until_associated = true

  depends_on = [
    openstack_networking_floatingip_v2.stack-ip,
    openstack_compute_instance_v2.stack
  ]
}

####################################################
# DNS                                              #
####################################################
resource "desec_rrset" "record" {
  # Control if a DNS record should be created.
  count = var.create-dns-record ? 1 : 0

  # The record's domain part [string].
  domain = "sovereignproductivitysuite.de"

  # The record's subdomain part. May be empty string to denote the zone apex [string].
  subname = var.dns-slug

  # The record type [string].
  # Possible values: "A", "AAAA", "NS", "TXT", ...
  type = "A"

  # The record content, as a set of strings [list].
  records = [
    openstack_networking_floatingip_v2.stack-ip.address
  ]

  # The TTL to set for the records [integer].
  # Possible values: >=3600
  ttl = 3600

  depends_on = [
    openstack_compute_instance_v2.stack
  ]
}
