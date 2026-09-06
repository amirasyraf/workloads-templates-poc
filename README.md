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
  release.yml
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
catalog/
  platforms.json
mise.toml
release-please-config.json
.release-please-manifest.json
```

## AWS Root

The AWS root creates:

- one EC2 instance using a definition-pinned AMI;
- one security group with no ingress and unrestricted outbound access;
- one IAM role and instance profile with `AmazonSSMManagedInstanceCore`;
- encrypted `gp3` root storage and required IMDSv2 tokens.

The instance display name is not derived from the path. Set `instance_name` in
the definition to control the EC2 `Name` tag. `server_name` remains the stable
path and state identity.

The OS family and version are part of the immutable server identity. They are
included in both the workload path and generated AWS resource names. A different
OS requires a separate definition and Terraform state; it is never treated as an
in-place update of an existing instance.

The catalog at `catalog/platforms.json` is the source of truth for OS catalog
keys and AWS image-resolution parameters. Its entries intentionally contain only
the SSM parameter path. The workload pipeline reads the catalog from the pinned
template release, and the AWS root validates that the selected OS key exists.
The catalog key is also the value of the `os` variable and the OS directory in a
workload definition, for example `ubuntu24`.

The provider uses GitHub's OIDC credentials directly in the `amirasyraf` AWS
account (`134584031874`). `allowed_account_ids` rejects credentials for any other
account. The S3 backend is supplied by `terraform init -backend-config=...` in
the workload pipeline.

The example definitions use public subnet `subnet-0a1d48f2ff2bd0332` in account
`134584031874` and `ap-southeast-1`.

Set `desired_state` to `absent` to destroy all resources while retaining the
definition and state identity for auditability.

## Releasing

Releases are automated with release-please. The version starts at `0.3.0` in
`.release-please-manifest.json` and is calculated from Conventional Commit
messages after the last release. A push to `main` creates or updates a release
pull request. Merging that release pull request creates the immutable Git tag,
GitHub Release, and changelog entry.

Use these commit types:

| Commit prefix | Release bump | Example |
| --- | --- | --- |
| `fix:` | Patch | `v0.3.0` -> `v0.3.1` |
| `feat:` | Minor | `v0.3.0` -> `v0.4.0` |
| `feat!:` or `BREAKING CHANGE:` | Minor while below `1.0.0` | `v0.3.0` -> `v0.4.0` |
| `docs:`, `chore:`, `ci:`, `test:` | No release | No tag |

The highest required bump wins when several commits are included. Breaking
changes use a minor bump before `1.0.0` because this POC enables
`bump-minor-pre-major`. After `1.0.0`, breaking changes use a major bump.

The template release does not update `amirasyraf/workloads-poc`. That repository
continues to use an explicit `TEMPLATE_VERSION` value and each workload pins its
own template tag.

```bash
git commit -m "fix: correct AWS instance metadata"
git push origin main
```

Project tools are pinned in `mise.toml` and installed the same way locally and
in CI. Before opening a release PR:

```bash
mise install
mise run check
```
