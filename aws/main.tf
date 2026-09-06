locals {
  catalog       = jsondecode(file("${path.module}/../catalog/platforms.json"))
  create        = var.desired_state == "present"
  os_definition = try(local.catalog.platforms.aws.operating_systems[var.os], null)
  resource_name = substr(replace(lower("${var.workload}-${var.os}-${var.server_name}"), "/[^a-z0-9-]/", "-"), 0, 40)
}

data "aws_subnet" "selected" {
  count = local.create ? 1 : 0
  id    = var.subnet_id
}

data "aws_ami" "selected" {
  count = local.create ? 1 : 0

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

data "aws_ec2_instance_type" "selected" {
  count         = local.create ? 1 : 0
  instance_type = var.instance_type
}

data "aws_iam_policy_document" "ec2_assume_role" {
  count = local.create ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_security_group" "server" {
  count = local.create ? 1 : 0

  description = "Managed no-ingress group for ${local.resource_name}"
  name_prefix = "${local.resource_name}-"
  vpc_id      = data.aws_subnet.selected[0].vpc_id

  tags = {
    Name = local.resource_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "ipv4" {
  count = local.create ? 1 : 0

  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  security_group_id = aws_security_group.server[0].id
}

resource "aws_iam_role" "ssm" {
  count = local.create ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role[0].json
  name               = "${local.resource_name}-ssm"

  tags = {
    Name = local.resource_name
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = local.create ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm[0].name
}

resource "aws_iam_instance_profile" "ssm" {
  count = local.create ? 1 : 0

  name = "${local.resource_name}-ssm"
  role = aws_iam_role.ssm[0].name
}

resource "aws_instance" "server" {
  count = local.create ? 1 : 0

  ami                         = data.aws_ami.selected[0].id
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = aws_iam_instance_profile.ssm[0].name
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected[0].id
  user_data                   = var.user_data
  vpc_security_group_ids      = concat([aws_security_group.server[0].id], var.additional_security_group_ids)

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  tags = {
    Name = var.server_name
    OS   = var.os
  }

  lifecycle {
    precondition {
      condition     = local.os_definition != null
      error_message = "The selected OS is not defined in the pinned platform catalog."
    }

    precondition {
      condition     = contains(data.aws_ec2_instance_type.selected[0].supported_architectures, data.aws_ami.selected[0].architecture)
      error_message = "The selected instance type does not support the pinned AMI architecture."
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_vpc_security_group_egress_rule.ipv4,
  ]
}
