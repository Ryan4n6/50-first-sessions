# Ship This Branch

You are done with this branch. Close out EVERYTHING properly before finishing.

This is a checklist. Do every step. Do not skip steps. Do not abbreviate steps under time pressure.

## Step 1: Verify Tests

Run the project's test suite. Check CLAUDE.md or README for the test command. Common patterns:
- `python -m pytest tests/ -v --tb=short`
- `npm test`
- `cargo test`

Report the exact count. Do NOT proceed if tests fail.

## Step 2: Identify All Linked Issues

Check which issues this branch addresses:
- Parse branch name for issue numbers
- Check recent commits for `#NNN` references
- Run `gh pr list` to see if a PR already exists

List every issue that will be affected.

## Step 3: Close Out Each Issue

For EACH linked issue, do ALL of the following:

### 3a. Check Acceptance Criteria
- Read the issue body
- For each `- [ ]` checkbox: verify whether the work was done
- If done: note it for the edit
- If descoped: prepare an explanation of why

### 3b. Edit the Issue Body
Use `gh issue edit {number} --body` to check off completed criteria.
If any criteria were descoped, add a note explaining why.

### 3c. Post Closing Comment
Every closing comment MUST include:
- **What shipped**: List the concrete changes
- **Commit SHAs**: Reference the actual commits
- **Test count**: "X/X tests pass"
- **What was descoped** (if anything): What didn't make it and why
- **Lessons learned**: What surprised you, what broke, what would you do differently

For P0/P1 issues, ALSO include:
- What was tested and how
- What's deferred to a future phase
- Link to design doc if one exists

### 3d. Code Review
If a code review happened (cross-model review, manual, or automated), post the results as a PR comment via `gh pr comment`. Include: reviewer/model used, findings (real vs false positive), verdict.

If no review happened on a PR with 100+ lines changed, flag this to the user.

## Step 4: Labels

Add labels to the PR and all linked issues. At minimum:
- Issue type: `bug`, `feature`, `refactor`, `tech-debt`, `docs`
- Priority if not already set: `P0`, `P1`, `P2`, `P3`

## Step 5: Update Memory Files

If `.claude/memory/` exists in the repo:

Update `known-issues.md`:
- Move closed issues to "Recently Shipped" section
- Add lessons learned
- Update "What's Next" with new priorities

Update `next-session-pickup.md`:
- Record what shipped
- Note any follow-up work needed

Commit memory files:
```bash
git add .claude/memory/
git commit -m "memory: session close-out for [branch-name]" --no-verify
```

## Step 6: Push and Create PR

```bash
git push -u origin [branch-name]
```

Create PR with proper body:
```bash
gh pr create --title "[type]: [description]" --body "..."
```

PR body must include:
- Summary of changes (bullet points)
- `Closes #NNN` for each linked issue
- Test plan (what was tested, what needs manual verification)

## Step 7: Report to User

Tell the user:
- PR URL
- Which issues will be closed
- Any follow-up work needed
- Lessons learned from this branch

## NEVER Do These Things

- Never delete the worktree or branch you're running inside of
- Never close an issue with unchecked acceptance criteria and no explanation
- Never post a one-sentence closing comment on a P0/P1 issue
- Never merge without labels on the PR
- Never skip the lessons learned — every branch teaches something
