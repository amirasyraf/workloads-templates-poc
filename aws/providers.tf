provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_assume_role_name}"
    session_name = "workloads-${local.resource_name}"
  }

  default_tags {
    tags = merge(var.additional_tags, {
      ManagedBy = "workloads-poc"
      Workload  = var.workload
    })
  }
}
