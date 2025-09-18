# ghcommit-action

A GitHub Action to detect changed files during a Workflow run and to commit and
push them back to the GitHub repository using the [`ghcommit`](https://github.com/planetscale/ghcommit) utility.

The advantage of using `ghcommit` is that the commits will be signed by GitHub's
GPG key and show as **Verified**. This is important for repositories that require
signed commits.

The plugin is inspired by [stefanzweifel/git-auto-commit-action](https://github.com/stefanzweifel/git-auto-commit-action)
and uses some of the same input parameters. We expect to emulate more of its
parameters over time and PRs providing similar functionality will be considered.

## Usage

The plugin is currently implemented as a Docker style plugin. It must be run on
a Linux host, eg: `ubuntu-latest`.

```yaml
name: fmt

on:
  # NOTE: Need to run on a PR so that the ${{ github.head_ref }} (branch) is non-null
  pull_request:
    types:
      - opened
      - synchronize
      - reopened

jobs:
  fmt-code:
    runs-on: ubuntu-latest

    permissions:
      # Give the default GITHUB_TOKEN write permission to commit and push the
      # added or changed files to the repository.
      contents: write

    steps:
      - uses: actions/checkout@v4
      # Include the pull request ref in the checkout action to prevent merge commit
      # https://github.com/actions/checkout?tab=readme-ov-file#checkout-pull-request-head-commit-instead-of-merge-commit
        with:
          ref: ${{ github.event.pull_request.head.sha }}

      # Run steps that make changes to the local repo here.

      # Commit all changed files back to the repository
      - uses: step-security/ghcommit-action@v0
        with:
          commit_message: "🤖 fmt"
          repo: ${{ github.repository }}
          branch: ${{ github.head_ref || github.ref_name }}
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
```

Example showing all options:

```yaml
      - uses: step-security/ghcommit-action@v0
        with:
          commit_message: "🤖 fmt"
          repo: ${{ github.repository }}
          branch: ${{ github.head_ref || github.ref_name }}
          empty: true
          file_pattern: '*.txt *.md *.json *.hcl'
        env:
          GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
```

See [`action.yaml`](./action.yaml) for current list of supported inputs.
