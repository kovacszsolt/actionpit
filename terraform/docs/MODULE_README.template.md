# Module: `<module-name>`

One sentence: what Azure capability this module provisions and when to use it.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.x |
| azurerm | >= x.y |

## Usage

```hcl
module "example" {
  source = "../modules/azure/<module-name>"

  # Required arguments — replace with real values
  resource_group_name = azurerm_resource_group.example.name
  location            = "westeurope"
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `location` | Azure region (ARM ID, e.g. `westeurope`). | `string` | … | yes/no |

*(Maintain this table manually or generate with `terraform-docs` — see root [README](../README.md).)*

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of … |

## Notes

- Security: call out sensitive outputs, Key Vault vs inline secrets, state implications.
- Links: Microsoft Learn for resource-specific limits or SKU matrices.

## Breaking changes

### `<version-or-date>`

- Describe incompatible input/output renames and required caller updates.
