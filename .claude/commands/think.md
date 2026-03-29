---
description: Structured multi-step reasoning for architecture decisions, bug analysis, or complex refactoring
argument-hint: <problem or decision to reason through>
---

# Deep Reasoning Mode

Use `sequential-thinking` MCP to decompose this problem into structured steps.

## Workflow
1. **Decompose:** Break the problem into 3-7 discrete reasoning steps
2. **Gather evidence:** For each step, read relevant code files (providers, entities, DAOs, screens)
3. **Apply constraints:** Check against the 5 critical rules and architecture patterns
4. **Evaluate tradeoffs:** Consider at least 2 approaches with pros/cons
5. **Decide:** Produce a clear recommendation with rationale
6. **Plan:** If code changes needed, outline exact files to modify and the change sequence

## When to Use This Mode
- Architecture decisions (new feature structure, provider design, DB schema changes)
- Bug diagnosis (trace through provider chain → repository → DAO → Drift query → UI rebuild)
- Refactoring planning (impact analysis across 19 features, 21 providers)
- Migration planning (DB schema version bumps, dependency upgrades)

## Masarify Architecture Context
- **Provider chain:** `database_provider` → `repository_providers` (9 repos) → 24 feature provider files
- **Clean layers:** `domain/` (pure Dart, 11 entities) → `data/` (9 repos + 13 DAOs) → `features/` (18 features, 32 screens)
- **DB:** Drift schema v14, 14 tables, 13 DAOs
- **State:** Riverpod 2.x with `StreamProvider` for reactive DB queries

## Problem: $ARGUMENTS
