provider "aws" {
  allowed_account_ids = [var.aws_account_id]
  region              = var.aws_region

  default_tags {
    tags = merge(var.additional_tags, {
      ManagedBy = "workloads-poc"
      Workload  = var.workload
    })
  }
}
