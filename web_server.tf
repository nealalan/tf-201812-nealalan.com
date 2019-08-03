###############################################################################
# 11 : Upload Public key for access to EC2 instances
###############################################################################
resource "aws_key_pair" "default" {
  key_name = "${var.pub_key_name}"
  public_key = "${file("${var.pub_key_path}")}"
}

###############################################################################
# 12 : Create EC2 Instance
#
# Execute install.sh for Ubuntu to configure
#   NGINX, CERTBOT
#   Pull git repos with websites
#
###############################################################################
resource "aws_instance" "wb" {
    ami  = "${var.ami}"
    instance_type = "t2.micro"
    key_name = "${var.pub_key_name}"
    subnet_id = "${aws_subnet.subnet-1.id}"
    vpc_security_group_ids = ["${aws_security_group.sgpub.id}",
                              "${aws_security_group.sgpubssh.id}"]
    associate_public_ip_address = true
    availability_zone = "${var.az_a}"
    tags = {
      Name = "${var.project_name}"
      Author = "${var.author_name}"
    }
#    provisioner "file" {
#        source      = "install.sh"
#        destination = "/tmp/install.sh"
#    }
#    provisioner "remote-exec" {
#        inline = [
#          "chmod +x /tmp/install.sh",
#          "/tmp/install.sh",
#        ]
#    }
}

###############################################################################
# 13 : Assign Existing EIP
#
# NOTE: I have an EIP already and assign it in the variables. If it sits
#  without being assigned to an instance or nat gateway, it will occur hourly
#  charges!!!!!
###############################################################################
resource "aws_eip_association" "static_ip" {
  instance_id   = "${aws_instance.wb.id}"
  public_ip = "${var.instance_assigned_elastic_ip}"
}

###############################################################################
# 14 : Create CloudWatch Alarm to restart the instance if unreachable
###############################################################################
resource "aws_cloudwatch_metric_alarm" "autorecover" {
  alarm_name          = "ec2-autorecover-High-Status-Check-Failed"
  namespace           = "AWS/EC2"
  evaluation_periods  = "2"
  period              = "60"
  alarm_description   = "This metric auto recovers EC2 instances"
  alarm_actions       = ["arn:aws:automate:${var.aws_region}:ec2:reboot"]
  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  metric_name         = "StatusCheckFailed"
  dimensions = {
    InstanceId = "${aws_instance.wb.id}"
  }
  tags = {
    Name = "CloudWatch Alarm EC2 Instance Unreachable"
    Author = "${var.author_name}"
  }
}