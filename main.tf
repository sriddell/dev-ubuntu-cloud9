terraform {
  backend "s3" {
    bucket = "ellucian-ar-terraform-state"
    key = "shane-ubuntu-cloud9"
    region = "us-east-1"
  }
}

provider "aws" {
    version = "~> 2.3"
}

provider "template" {
    version = "~> 2.1"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.sh")}"
}

resource "aws_security_group" "sg" {
  name_prefix = "cloud9-dev"
  vpc_id      = "${var.vpc_id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["149.24.0.0/16","10.0.0.0/11","35.172.155.192/27","35.172.155.96/27"] # last two are cloud9 ip ranges
  }



  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev" {
  ami           = "ami-03e791d842b839f7e"
  instance_type = "m5a.xlarge"
  disable_api_termination = false
  key_name = "sriddell"
  subnet_id = "${var.subnet_id}"
  associate_public_ip_address = "true"
  user_data = "${data.template_file.user_data.rendered}"
  vpc_security_group_ids = ["${aws_security_group.sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.dev.name}"
  root_block_device {
    volume_type = "gp2"
    volume_size = 32
    delete_on_termination = true
  }
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 512
    volume_type = "gp2"
    encrypted = true
    delete_on_termination = true
  }
  tags = {
    Name = "shane-ubuntu-cloud9-1"
    POC = "shane.riddell@icloud.com"
    CostCenter = "73011"
  }
}

resource "aws_iam_instance_profile" "dev" {
  name_prefix = "dev"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name_prefix = "cloud9"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name_prefix = "cloud9"
  path        = "/"
  description = "My test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "route53:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
		  "Resource": "*"

    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dev" {
  role       = "${aws_iam_role.role.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}