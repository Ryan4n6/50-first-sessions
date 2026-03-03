# Contributing to 50 First Sessions

First off, thank you for considering contributing to 50 First Sessions! This system was born from real failures and gets better with every contribution.

This document outlines the process and conventions for contributing to the repository.

## Table of Contents
1. [Reporting Bugs vs Requesting Features](#reporting-bugs-vs-requesting-features)
2. [Local Development and Testing](#local-development-and-testing)
3. [Adding a New Slash Command](#adding-a-new-slash-command)
4. [Adding a New Memory Template](#adding-a-new-memory-template)
5. [Pull Request Conventions](#pull-request-conventions)
6. [Code of Conduct](#code-of-conduct)

---

## Reporting Bugs vs Requesting Features

We use GitHub Issues to track bugs and feature requests. Please follow these guidelines:

### Reporting Bugs
If you find a bug, please check existing issues to see if it has already been reported. If not, open a new issue and include:
* **Description:** A clear description of the bug.
* **Steps to Reproduce:** Exactly what you did before the bug occurred.
* **Expected Behavior:** What you expected to happen.
* **Actual Behavior:** What actually happened (include logs or error messages from Claude Code if applicable to help debugging).
* **System Info:** Operating system, shell, and Claude Code version.

### Requesting Features
We love new ideas, especially those that solve real Claude Code workflows! When requesting a new feature:
* **The "Why":** Explain the problem you are trying to solve.
* **The "How":** Suggest how it might work (e.g., a new hook, a new slash command, or a new memory template).
* **Use Case:** Provide a concrete example of how this feature would be used in a typical session.

---

## Local Development and Testing

Because this project is fundamentally a set of bash scripts and markdown files designed for Claude Code, testing is largely manual.

### Testing Commands
If you're modifying or creating a slash command in the `commands/` directory:
1. Make your changes in the local repo.
2. Copy the modified command file to your global Claude commands directory:
   ```bash
   cp commands/<your-command>.md ~/.claude/commands/
   ```
3. Open a new `claude` session and test running your modified command, e.g., `/<your-command>`.

### Testing Hooks
If you are modifying scripts in the `hooks/` directory, you can test them directly in your shell to verify their output:
1. Navigate to a test project directory running Claude Code.
2. Replace its `.claude/hooks/` with your modified hook scripts.
3. Run the hook manually to see the context payload printed to standard output:
   ```bash
   bash .claude/hooks/session-start.sh
   bash .claude/hooks/session-end.sh
   ```
4. Verify that no errors or unexpected outputs are injected. Make sure `session-end.sh` is safely handling the git commits (or gracefully skipping them when appropriate).

---

## Adding a New Slash Command

Commands are human-triggered workflows made entirely of markdown formatting.
1. Create a new `<command-name>.md` file in the `commands/` directory.
2. Write the prompt logic inside. Keep the instructions for Claude explicit and deterministic.
3. Document your command's existence:
   * Add it to the "What's in the Box" table in `README.md`.
   * Add it to the `Layer 3: Slash Commands` section in `docs/architecture.md`.
   * Add it to the "The Four Commands" (or "The Five Commands", etc.) table in `playbook.md`.

---

## Adding a New Memory Template

Memory templates are starting points for common context needs.
1. Create a new `your-template.md` in the `memory-templates/` directory.
2. Include a brief header explaining the template's purpose and how the user or Claude should update it.
3. Add the new template to:
   * The `Memory Files` section of the `README.md`.
   * The `Which Files Do You Need?` section of `docs/customization.md`.
   * The documentation in `docs/architecture.md`.

---

## Pull Request Conventions

To make reviews easier and keep git history clean, please follow these conventions:

### Branch Naming
Use a standard prefix for your branches:
* `feat/` for new features (e.g., `feat/add-test-command`)
* `fix/` for bug fixes (e.g., `fix/session-start-timeout`)
* `docs/` for documentation changes (e.g., `docs/update-customization-guide`)
* `chore/` for maintenance tasks

### Commit Messages
We encourage the use of [Conventional Commits](https://www.conventionalcommits.org/). This means commit messages should look like:
* `feat: add new design doc template`
* `fix: prevent session-end from failing outside worktree`
* `docs: fix typo in playbook`

### PR Guidelines
* Keep PRs small and focused on a single change.
* Describe *why* you are making the change, not just *what* the change is.
* Link to any relevant GitHub issues (e.g., `Fixes #12`).
* Ensure all files updated (like `commands/` or `hooks/`) have synchronized updates in `README.md` or `docs/` if they introduce new behavior.

---

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please be kind, collaborative, and respectful. 

By participating in this project, you agree to abide by the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/), a universally accepted code of conduct for open source projects. Unacceptable behavior will not be tolerated.
