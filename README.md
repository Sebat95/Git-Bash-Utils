# Git-Bash-Utils

Utility Bash scripts to handle tedious (git) terminal tasks — batch pulling, pruning, contribution stats, Node.js version switching, and monorepo release ordering.

## Table of Contents

- [Requirements](#requirements)
- [Scripts](#scripts)
  - [pull_all.sh](#pull_allsh)
  - [prune_all.sh](#prune_allsh)
  - [contributions.sh](#contributionssh)
  - [change_node.sh](#change_nodesh)
  - [get_order_of_release.sh](#get_order_of_releasesh)
- [License](#license)

## Requirements

| Dependency | Used by |
|---|---|
| **Bash** | All scripts
| **Git** | `pull_all.sh`, `prune_all.sh`, `contributions.sh` |
| **Node.js / npm** | `change_node.sh`, `pull_all.sh` (optional) |
| **[jq](https://stedolan.github.io/jq/)** | `get_order_of_release.sh` |

---

## Scripts

### `pull_all.sh`

Iterates over every sibling directory (excluding `node_modules`) and runs `git pull` in each one. Optionally checks out a specific branch first and/or triggers an npm build after pulling.

This is useful when you work with a multi-repo setup where several repositories live side-by-side in one parent folder.

#### Usage

```bash
# Pull every repo in the current directory
./pull_all.sh

# Checkout a branch first, then pull
./pull_all.sh <branch>

# Checkout a branch, pull, and build
./pull_all.sh <branch> Y
```

#### Parameters

| # | Name | Required | Description |
|---|---|---|---|
| 1 | `branch` | No | Branch name to `git checkout` before pulling. If omitted, pulls the currently checked-out branch. |
| 2 | `build` | No | Pass `Y` to run `npm run build:dev` after pulling. Any other value (or omitting it) skips the build step. |

#### Example

```bash
cd ~/projects
./pull_all.sh develop Y
```

This enters each subdirectory, checks out `develop`, pulls the latest changes, and runs `npm run build:dev`.

---

### `prune_all.sh`

Iterates over every sibling directory (excluding `node_modules`) and runs `git fetch --prune` to clean up stale remote-tracking references. It also lists local branches whose upstream has been deleted (marked `gone`).

#### Usage

```bash
./prune_all.sh
```

#### Parameters

None.

#### What it does

For each subdirectory:

1. Runs `git fetch --prune` to remove remote-tracking branches that no longer exist on the remote.
2. Runs `git branch -vv | grep ': gone]'` to show local branches whose upstream was deleted, so you know which ones are safe to delete manually.

---

### `contributions.sh`

Displays per-author contribution statistics (lines added, removed, and total) for the current Git repository, along with each author's percentage of total line changes.

#### Usage

```bash
cd /path/to/your/repo
/path/to/contributions.sh
```

#### Parameters

None. Must be run from inside a Git repository.

#### How it works

1. Registers a global Git alias `count-lines` that uses `git log --numstat` to sum added/removed/total lines per author.
2. Collects all unique author emails from `git log`.
3. For each author, computes the line stats and the percentage of total changes across the project.
4. Prints one line per author with added lines, removed lines, total lines, and contribution percentage.

#### Example output

```
alice@example.com =>  added lines: 12045, removed lines: 3021, total lines: 9024 (62.5%)
bob@example.com =>  added lines: 4520, removed lines: 1100, total lines: 3420 (23.7%)
carol@example.com =>  added lines: 2500, removed lines: 510, total lines: 1990 (13.8%)
```

> **Note:** This script creates a global Git alias (`count-lines`). It will overwrite any existing alias with the same name.

---

### `change_node.sh`

Switches between multiple portable Node.js installations that live alongside the global `npm root` directory. Designed for environments where several Node versions are stored as `___node-<version>` directories (e.g., `___node-v18.17.0`, `___node-v20.5.1`).

#### Usage

```bash
./change_node.sh
```

#### Parameters

None — the script is interactive. It presents a numbered menu of available Node.js versions and prompts you to pick one.

#### How it works

1. Navigates to the parent of the global npm root (`npm root --global`).
2. Discovers all directories matching `___node*`.
3. Displays a numbered list of available versions.
4. After you select a version:
   - Moves the current Node files and `node_modules/` into a directory named `___node-<current version>`.
   - Moves the selected version's files out of its `___node-<selected version>` directory into the active location.

#### Prerequisites

- Node.js must be installed in a "portable" layout where multiple versions are stored as `___node-<version>` directories next to the active installation.
- `npm` must be available on `PATH`.

#### Example session

```
Change node to which available version:
[1] v18.17.0
[2] v20.5.1
Enter the number of your choice: 2
You selected: v20.5.1
Moving old version back to its directory...
Done
Moving new version out of its directory...
Done
```

---

### `get_order_of_release.sh`

Analyzes `package.json` dependency graphs across different related repos (where each subdirectory is a package) and outputs the correct build/release order — packages with no internal dependencies first, then those that depend on them, and so on.

#### Usage

```bash
# Determine the build order for all packages
./get_order_of_release.sh

# Check a specific module (non-recursive)
./get_order_of_release.sh <module_name>
./get_order_of_release.sh <module_name> N

# Check a specific module with full recursive dependency chain
./get_order_of_release.sh <module_name> Y
```

#### Parameters

| # | Name | Required | Description |
|---|---|---|---|
| 1 | `module_name` | No | Name of a specific module (subdirectory) to inspect. If omitted, all modules are analyzed and the full release order is printed. |
| 2 | `recursive` | No | `Y` to recursively resolve the full dependency chain for the given module. `N` (or omitted) to only validate the module exists. |

#### How it works

1. Reads every subdirectory's `package.json` and counts how many sibling packages each one depends on.
2. Sorts packages from fewest to most internal dependencies.
3. Iteratively prints packages that have zero unresolved dependencies, removing them from the pool, until all packages are printed.

With the recursive flag (`Y`), it performs a depth-first traversal starting from the given module to produce its complete dependency chain.

#### Prerequisites

- **`jq`** must be installed. The script will exit with an error and installation instructions if `jq` is not found.
- Must be run from the root of a monorepo where each subdirectory contains a `package.json`.

#### Example output

```
shared-utils
core-lib
api-client
web-app
```

This means `shared-utils` should be built first, then `core-lib`, and so on.
