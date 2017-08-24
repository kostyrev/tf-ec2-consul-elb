resource "aws_security_group" "consul" {
  name        = "${format("%s", var.name)}"
  description = "${format("%s", var.name)}"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${format("%s", var.name)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "consul-ssh" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul-echo-request" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul-rpc" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8300
  to_port           = 8300
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul-serf-lan-tcp" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8301
  to_port           = 8301
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul-serf-lan-udp" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8301
  to_port           = 8301
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "consul-serf-wan-tcp" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8302
  to_port           = 8302
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul-serf-wan-udp" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8302
  to_port           = 8302
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "consul-http-api" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul-dns-tcp" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "consul-dns-udp" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "ingress"
  from_port         = 8600
  to_port           = 8600
  protocol          = "udp"
  self              = true
}

resource "aws_security_group_rule" "consul-egress" {
  security_group_id = "${aws_security_group.consul.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
