variable "template_version" {
  description = "Release tag of workloads-templates-poc used for this server."
  type        = string

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.template_version))
    error_message = "template_version must be a semantic version tag such as v1.2.3."
  }
}

variable "aws_account_id" {
  description = "AWS account in which the server will be provisioned."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must contain exactly 12 digits."
  }
}

variable "aws_region" {
  description = "AWS region in which the server will be provisioned."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name."
  }
}

variable "workload" {
  description = "Owning workload or application identifier."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,31}$", var.workload))
    error_message = "workload must be 1-32 characters using letters, digits, underscores, or hyphens."
  }
}

variable "server_name" {
  description = "Stable server identifier within the workload."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{0,47}$", var.server_name))
    error_message = "server_name must be 1-48 characters using letters, digits, underscores, or hyphens."
  }
}

variable "instance_name" {
  description = "AWS Name tag for the EC2 instance."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9 ._-]{0,127}$", var.instance_name))
    error_message = "instance_name must be 1-128 characters using letters, digits, spaces, dots, underscores, or hyphens."
  }
}

variable "desired_state" {
  description = "Whether the server and its supporting resources should exist."
  type        = string
  default     = "present"

  validation {
    condition     = contains(["present", "absent"], var.desired_state)
    error_message = "desired_state must be present or absent."
  }
}

variable "os" {
  description = "OS catalog key installed by the pinned AMI, for example ubuntu24."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]{0,31}$", var.os))
    error_message = "os must be a valid lowercase catalog key."
  }
}

variable "ami_id" {
  description = "Pinned AMI ID resolved when the definition is created."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID."
  }
}

variable "subnet_id" {
  description = "Subnet in which the EC2 network interface will be created."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "subnet_id must be a valid subnet ID."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z0-9]+[a-z0-9.-]*$", var.instance_type))
    error_message = "instance_type must be a valid EC2 instance type name."
  }
}

variable "associate_public_ip_address" {
  description = "Whether the primary network interface receives a public IPv4 address."
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size in GiB. Windows Server 2025 requires at least 30 GiB."
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384 && floor(var.root_volume_size) == var.root_volume_size
    error_message = "root_volume_size must be a whole number between 8 and 16384 GiB."
  }
}

variable "additional_security_group_ids" {
  description = "Existing security groups attached in addition to the managed no-ingress group."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.additional_security_group_ids : can(regex("^sg-[0-9a-f]{8,17}$", id))])
    error_message = "Every additional_security_group_ids value must be a valid security group ID."
  }
}

variable "additional_tags" {
  description = "Additional AWS tags. ManagedBy, Name, and Workload are reserved."
  type        = map(string)
  default     = {}
}

variable "user_data" {
  description = "Optional cloud-init or PowerShell user data."
  type        = string
  default     = null
  sensitive   = true
}
