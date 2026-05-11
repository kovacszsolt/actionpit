# version-number

Increment and persist an environment semantic version variable (`X.Y.Z`) in GitHub Actions.

## Action path

`/.github/actions/version-number`

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `environment_name` | Yes | — | GitHub Environment that contains the target variable. |
| `variable_name` | Yes | — | Environment variable key to read and update. |
| `write_token` | Yes | — | Token with permission to read and update environment variables. |
| `bump` | No | `patch` | Semantic segment to increment: `major`, `minor`, `patch`. |
| `repository_name` | No | `${{ github.repository }}` | Repository in `owner/name` format. |

## Output

| Output | Description |
|---|---|
| `version_number` | Incremented semantic version. Falls back to `0.0.0-unknown` on missing/invalid value or update verification failure. |

## Example

```yaml
- id: version_number
  uses: kovacszsolt/actionpit/.github/actions/version-number@main
  with:
    environment_name: main
    repository_name: username/repository
    variable_name: OO_BRIDGE_VERSION_NUMBER
    bump: patch
    write_token: ${{ secrets.GH_VARIABLES_TOKEN }}
```

## Required token permissions

For a fine-grained PAT, grant repository-level `Variables: Read and write` on the target repository.

