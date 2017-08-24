data "template_file" "consul" {
  template = <<EOF
#cloud-config
repo_update: false
repo_upgrade: false

mounts:
  - [ swap, null ]
  - [ ephemeral0, null ]
  - [ ephemeral1, null ]

write_files:
  - path: /etc/sysconfig/consul
    permissions: '0644'
    owner: root:root
    content: |
      CMD_OPTS="agent -server -bootstrap-expect=$${bootstrap_expect} -config-dir=/etc/consul -data-dir=/var/lib/consul -ui"

  - path: /etc/consul/consul.json
    permissions: '0640'
    owner: consul:root
    content: |
      {"datacenter": "$${datacenter}",
       "raft_protocol": 3,
       "data_dir":  "/var/lib/consul",
       "addresses": {
         "http": "0.0.0.0"
       },
       "ports": {
         "http": 8500
       },
       "retry_join_ec2": {
         "region": "$${datacenter}",
         "tag_key": "$${ec2_tag_key}",
         "tag_value": "$${ec2_tag_value}"
       },
       "leave_on_terminate": true,
       "performance": {"raft_multiplier": 1}}

runcmd:
   - chkconfig consul on
   - service consul start
EOF

  vars {
    bootstrap_expect = "${var.bootstrap_expect}"
    datacenter       = "${var.datacenter}"
    ec2_tag_key      = "${var.ec2_tag_key}"
    ec2_tag_value    = "${var.ec2_tag_value}"
  }
}

resource "aws_launch_configuration" "consul" {
  name_prefix          = "${format("%s-", var.name)}"
  image_id             = "${var.image_id}"
  instance_type        = "${var.instance_type}"
  ebs_optimized        = "${var.ebs_optimized}"
  iam_instance_profile = "${aws_iam_instance_profile.consul-instance-profile.id}"
  security_groups      = ["${aws_security_group.consul.id}"]
  user_data            = "${data.template_file.consul.rendered}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "consul-cluster-asg" {
  name_prefix          = "${format("%s-", var.name)}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  launch_configuration = "${aws_launch_configuration.consul.id}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"

  desired_capacity      = "${var.min_size}"
  wait_for_elb_capacity = "${var.min_size}"

  health_check_type         = "ELB"
  health_check_grace_period = 30

  load_balancers = ["${aws_elb.consul.id}"]

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "${var.ec2_tag_key}"
    value               = "${var.ec2_tag_value}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Launch the ELB that is serving consul. This has proper health checks
// to only serve healthy consul instances.
resource "aws_elb" "consul" {
  name                        = "${format("%s", var.name)}"
  connection_draining         = false
  connection_draining_timeout = 400
  internal                    = true
  subnets                     = ["${var.subnet_ids}"]
  security_groups             = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 8500
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    target              = "${var.elb-health-check}"
    interval            = 20
  }
}

resource "aws_security_group" "elb" {
  name        = "${format("%s-elb", var.name)}"  
  description = "${format("%s-elb", var.name)}"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "consul-elb-http" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "ingress"
  from_port         = 8500
  to_port           = 8500
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "consul-elb-egress" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Allow ELB to connect to 8500 port for health checks
resource "aws_security_group_rule" "allow-elb-http-check" {
  security_group_id        = "${aws_security_group.consul.id}"
  type                     = "ingress"
  from_port                = 8500
  to_port                  = 8500
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.elb.id}"
}
