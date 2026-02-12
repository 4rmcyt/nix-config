Create a git commit following these steps:

1. Run `git status` and `git diff --staged` to review changes
2. If nothing is staged, ask what to stage
3. Determine commit type from the changes:
   - feat: new feature
   - fix: bug fix
   - refactor: code restructuring
   - style: formatting only
   - chore: maintenance, dependencies
4. Determine scope from the primary module/directory changed
5. Write concise description (imperative mood, no period, under 72 chars)
6. Format: `type(scope): description`
7. Run `nix fmt` if Nix files changed
8. Create the commit
