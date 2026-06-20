# Global AI instructions (Neovim / Avante)

Loaded from `stdpath("config")/global-ai-instructions.md` via Avante `system_prompt`
when the file exists. **Project** `avante.md` (and Cursor rules elsewhere) still apply
per repo; expand this file with your cross-cutting preferences.

## Engineering defaults

- Prefer minimal diffs; no drive-by refactors or unrelated edits.
- Match existing layout, naming, and import style in each repo.
- Call out breaking changes, security-sensitive areas, and missing tests.
- Prefer explicit, reviewable steps over vague refactors.

## TypeScript / JavaScript

- Strict typing where the project already uses it; avoid `any` unless the codebase does.
- Prefer async/await over raw promise chains when adding code.

## Go

- Follow standard `gofmt` layout; handle errors explicitly (`if err != nil`).
- Respect existing module boundaries and context cancellation patterns.

## Taskfiles (go-task / Task)

- Prefer tasks over one-off shell scripts when automating repeatable steps.
- Keep task names and variables aligned with how the repo documents them.

## Solidity / Foundry

- Follow existing patterns for `forge` layouts, remappings, and NatSpec where used.
- Be careful with external calls, reentrancy, and upgradeable patterns if present.

## Containers / Kubernetes

- Prefer small, explicit images and manifests; document assumptions about secrets and namespaces.
- Do not invent cluster names or namespaces without project context.

## Docker

- Keep Dockerfiles minimal and cache-friendly; note when build args or multi-stage builds are required.

---

Add or trim sections as your stacks change.
