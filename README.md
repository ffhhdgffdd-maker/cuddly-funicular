# WolFox

The repository now uses **`main` as its only active GitHub branch**. The former branch snapshots are preserved under [`projects/`](projects/README_AR.md), grouped into project directories derived from their release configuration. No new repositories were created.

## Repository layout

- **Repository root** — canonical WolFox build source and CI entry points.
- **`release.json`** — active release configuration for the `masajid` project on `main`.
- **`projects/<project-config>/branches/<branch-slug>/`** — archived source snapshots retained for each former branch; `/` in an original branch name becomes `--` in the folder name, while the exact name remains in the project index. Nested workflow files are historical and are not active GitHub Actions workflows.
- **`projects/index.json`** — machine-readable project and source-branch catalog.
- **`tools/verify_projects.py`** — checks project naming, source file counts, and SHA-256 tree digests.

See the [Arabic project catalog](projects/README_AR.md) and the [Arabic repository guide](README_AR.md).

## Build and validation

The root workflows continue to build the active `main` project. Run the local Linux test suite with:

```bash
bash run_all_linux_tests.sh
```

Validate the consolidated project catalog with:

```bash
python3 tools/verify_projects.py
```

The CI workflow definitions are in [`.github/workflows/`](.github/workflows/).
