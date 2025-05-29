# Git Branch and Release Management Guide for Python Packages

## Introduction

This guide outlines a complete workflow for managing branches, versions, and releases for a Python package. It follows GitFlow-inspired best practices while being practical for everyday development.

## Branch Structure

- **`main` (or `master`)**: Stable production code
- **`develop`**: Integration branch for ongoing development
- **`feature/*`**: For new features
- **`release/*`**: For preparing releases
- **`hotfix/*`**: For urgent production fixes

## Initial Setup

If you're starting with only a `main` branch, follow these steps to set up a proper development workflow:

1. Create a `develop` branch:
```bash
git checkout -b develop
git push -u origin develop
```

## Development Workflow

### 1. Starting a New Feature

```bash
# Start from develop branch
git checkout develop
git pull  # Get latest changes

# Create feature branch
git checkout -b feature/my-new-feature
```

### 2. Working on the Feature

```bash
# Make changes, then commit
git add .
git commit -m "Implement feature XYZ"

# Push to remote (first time)
git push -u origin feature/my-new-feature

# Push subsequent changes
git push
```

### 3. Completing a Feature

```bash
# Update develop branch first
git checkout develop
git pull

# Merge feature (using no-fast-forward to preserve history)
git merge --no-ff feature/my-new-feature -m "Merge feature/my-new-feature"
git push origin develop

# Delete feature branch (optional)
git branch -d feature/my-new-feature
git push origin --delete feature/my-new-feature
```

## Release Process

### 1. Preparing a Release

```bash
# Update version in pyproject.toml from "0.1.0" to "1.0.0" or whatever is appropriate
# Make sure develop branch is up to date
git checkout develop
git pull

# Create release branch
git checkout -b release/1.0.0
```

### 2. Update Version in Code

Edit `pyproject.toml` to update the version:

```toml
[project]
name = "base-data-project"
version = "1.0.0"  # Update this from development version
```

Commit the version change:

```bash
git commit -am "Bump version to 1.0.0"
```

### 3. Final Testing and Fixes

Make any final fixes directly in the release branch:

```bash
git commit -am "Fix issue discovered during release testing"
```

### 4. Finalizing the Release

```bash
# Merge to main
git checkout main
git pull
git merge --no-ff release/1.0.0 -m "Merge release 1.0.0"

# Tag the release
git tag -a v1.0.0 -m "Version 1.0.0"

# Push changes
git push origin main
git push origin v1.0.0

# Merge back to develop (CRITICAL STEP - DON'T SKIP!)
git checkout develop
git merge --no-ff release/1.0.0 -m "Merge release 1.0.0 back to develop"

# Update version in develop for next development cycle
# Edit pyproject.toml to set version = "1.0.1-dev" or similar
git commit -am "Start next development cycle"
git push origin develop

# Delete release branch
git branch -d release/1.0.0
git push origin --delete release/1.0.0
```

## Hotfix Process

For urgent fixes to production code:

```bash
# Create hotfix branch from main
git checkout main
git pull
git checkout -b hotfix/critical-bug-fix

# Fix the issue and update version (e.g., 1.0.0 to 1.0.1)
# Edit pyproject.toml
git commit -am "Fix critical bug and bump version to 1.0.1"

# Merge to main
git checkout main
git merge --no-ff hotfix/critical-bug-fix -m "Merge hotfix/critical-bug-fix"
git tag -a v1.0.1 -m "Version 1.0.1"
git push origin main
git push origin v1.0.1

# Also merge to develop
git checkout develop
git merge --no-ff hotfix/critical-bug-fix -m "Merge hotfix/critical-bug-fix"
git push origin develop

# Delete hotfix branch
git branch -d hotfix/critical-bug-fix
git push origin --delete hotfix/critical-bug-fix
```

## Branch Synchronization

If branches get out of sync (e.g., releases weren't properly merged back):

### Check branch status
```bash
# See how branches relate to each other
git log --graph --oneline --all --decorate

# Check how far behind/ahead branches are
git checkout develop
git status  # Will show "Your branch is X commits behind/ahead of origin/develop"
```

### Sync develop with main
```bash
git checkout develop
git merge main  # Bring all release changes into develop
git push origin develop
```

### Sync feature branches with develop
```bash
git checkout feature/my-feature
git merge develop
git push origin feature/my-feature
```

## Periodic Repository Maintenance

Every few releases, or at least monthly:

1. Ensure develop contains all changes from main:
   ```bash
   git checkout develop
   git merge main
   git push origin develop
   ```

2. Update all active feature branches with latest develop:
   ```bash
   git checkout feature/my-feature
   git merge develop
   git push origin feature/my-feature
   ```

3. Clean up old branches:
   ```bash
   # List merged branches
   git branch --merged

   # Delete local branches that have been merged
   git branch -d branch-name

   # Delete remote branches
   git push origin --delete branch-name
   ```

## GitHub Releases

After pushing tags to GitHub, create proper GitHub releases:

1. Go to your repository on GitHub
2. Click on "Releases" in the right sidebar
3. Click "Create a new release" or "Draft a new release"
4. Select the tag (e.g., `v1.0.0`)
5. Add a title (e.g., "Version 1.0.0")
6. Write release notes detailing changes, new features, bug fixes, etc.
7. Optionally attach build artifacts (wheel files, etc.)
8. Click "Publish release"

## Troubleshooting

### If branches are out of sync
Follow the "Branch Synchronization" section above.

### If you get merge conflicts
1. Open the conflicted files (marked with `<<<<<<< HEAD`)
2. Edit to resolve conflicts, removing conflict markers
3. Save files
4. `git add .` to mark as resolved
5. `git commit` to complete the merge

### If you accidentally committed to the wrong branch
```bash
# Save your changes
git stash

# Switch to correct branch
git checkout correct-branch

# Apply your changes here
git stash apply

# Commit to the correct branch
git add .
git commit -m "Your commit message"
```

## Version Numbering Conventions

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 1.0.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible
- **Development versions**: Add `-dev` suffix (e.g., `1.1.0-dev`)

## Managing Development Dependencies

In your `pyproject.toml`, keep development dependencies under `[project.optional-dependencies]`:

```toml
[project.optional-dependencies]
dev = [
    "pytest>=6.0.0",
    "black>=22.0.0",
    "isort>=5.0.0",
    "flake8>=4.0.0",
    "mypy>=0.900",
]
```

Install with: `pip install -e '.[dev]'`

## Common Git Commands Reference

- Show branches: `git branch`
- Switch branches: `git checkout branch-name`
- Create and switch: `git checkout -b new-branch`
- Pull latest changes: `git pull`
- See commit history: `git log --oneline --graph --decorate`
- See differences: `git diff branch1..branch2`
- List tags: `git tag`
- Push all tags: `git push --tags`
- Create backup of a branch: `git branch branch-backup-name`

## Release Checklist

1. ✅ All features for the release are merged to `develop`
2. ✅ Create `release/x.y.z` branch
3. ✅ Update version in `pyproject.toml`
4. ✅ Perform final testing
5. ✅ Merge to `main`
6. ✅ Tag release
7. ✅ Create GitHub release with notes
8. ✅ Merge back to `develop` (CRITICAL)
9. ✅ Update `develop` version for next cycle
