# workloads-templates-poc

Versioned Terraform root modules used by
[`amirasyraf/workloads-poc`](https://github.com/amirasyraf/workloads-poc).

## Design

The POC has one Terraform root per compute provider, not one root per operating
system. Provider resources and authentication differ enough to justify separate
roots. An OS is data passed to a provider root and selects image-specific
validation and settings.

The workload repository checks out a release tag from this repository and runs
the appropriate root with a server's `terraform.tfvars.json`. No Terraform source
is copied into workload definitions, so a server is fully described by one JSON
file and its pinned `template_version`.

Only AWS is implemented in this POC. Azure and vSphere are intentionally out of
scope until those providers are needed and environments are available for live
testing.

## Layout

```text
.github/workflows/
  ci.yml
aws/
  backend.tf
  main.tf
  outputs.tf
  providers.tf
  variables.tf
  versions.tf
examples/
  aws-ubuntu.tfvars.json
  aws-windows.tfvars.json
mise.toml
```

## AWS Root

The AWS root creates:

- one EC2 instance using a definition-pinned AMI;
- one security group with no ingress and unrestricted outbound access;
- one IAM role and instance profile with `AmazonSSMManagedInstanceCore`;
- encrypted `gp3` root storage and required IMDSv2 tokens.

The provider uses GitHub's OIDC credentials directly in the `amirasyraf` AWS
account (`134584031874`). `allowed_account_ids` rejects credentials for any other
account. The S3 backend is supplied by `terraform init -backend-config=...` in
the workload pipeline.

The example definitions use public subnet `subnet-0a1d48f2ff2bd0332` in account
`134584031874` and `ap-southeast-1`.

Set `desired_state` to `absent` to destroy all resources while retaining the
definition and state identity for auditability.

## Releasing

Every behavioral change must be released under a new immutable semantic version
tag. Existing server definitions remain on their pinned version until changed.

```bash
VERSION=v0.2.0
git tag "$VERSION"
git push origin "$VERSION"
gh release create "$VERSION" --generate-notes
```

Project tools are pinned in `mise.toml` and installed the same way locally and
in CI. Before releasing:

```bash
mise install
mise run check
```
