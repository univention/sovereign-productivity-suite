####################################################
# Server                                           #
####################################################

output "server-ip" {
  value = openstack_networking_floatingip_v2.stack-ip.address
}
