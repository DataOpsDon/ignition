# Stack Scaffold Template

This directory contains template files for creating new infrastructure stacks.

## Files

- `terraform/` - Terraform configuration templates
- `../github/stack-workflow.yml` - GitHub Actions caller workflow written to `.github/workflows/<stack>.yml`

## Usage

Use the CLI tool to generate new stacks based on these templates:

```bash
ign add-stack --stack-name <name>
```
