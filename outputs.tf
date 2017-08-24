output "address" {
  value = "${aws_elb.consul.dns_name}"
}

output "elb_zone_id" {
  value = "${aws_elb.consul.zone_id}"
}

// Can be used to add additional SG rules to consul instances.
output "consul_security_group" {
  value = "${aws_security_group.consul.id}"
}

// Can be used to add additional SG rules to the consul ELB.
output "elb_security_group" {
  value = "${aws_security_group.elb.id}"
}
