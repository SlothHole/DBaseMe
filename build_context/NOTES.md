# Project Notes — Repository Snapshot → AST Database

## Intent

This project is designed to build a **repository intelligence database** using a two-phase approach:

1. PowerShell produces a deterministic, linear TXT snapshot of a repository.
2. A separate program (likely Python) parses that TXT, performs AST parsing, and builds the database.

The database is the authoritative artifact.
The repository filesystem and the TXT snapshot are inputs, not sources of truth.

---

## Why a TXT Snapshot Is Used

The TXT snapshot exists to:

- Avoid repeated filesystem traversal
- Remove assumptions about runtime environment
- Provide a single, self-contained input artifact
- Make analysis reproducible and deterministic
- Simplify tooling by reducing inputs to one file

The snapshot is intentionally **mechanical**, not semantic.

---

## What the PowerShell Side Does

PowerShell:
- Walks the entire repository
- Records the repo-relative file structure
- Identifies which programming languages exist (by extension)
- Infers required tools and dependencies from files present
- Embeds the full contents of every file inline

PowerShell does **not**:
- Parse ASTs
- Infer code semantics
- Execute or evaluate code
- Build a database

---

## What the Analysis Side Does

The analysis program:
- Parses the TXT snapshot
- Reconstructs file boundaries in memory
- Dispatches each file to a language-specific AST parser
- Extracts symbols, calls, imports, and metadata
- Writes structured data into a database

All semantic meaning comes from AST parsing.

---

## Design Constraints

- No filesystem access during analysis
- No Git or VCS assumptions
- No runtime execution of source code
- No inferred data beyond AST output
- Deterministic behavior for identical inputs

If information is not present in the TXT or AST output, it does not exist.

---

## Scope Boundaries

In scope:
- Static analysis
- Multi-language AST parsing
- Deterministic database construction

Out of scope (unless explicitly added later):
- Runtime analysis
- Build execution
- Dependency resolution beyond imports
- Automatic rescanning

---

## Expected Evolution

Future extensions may include:
- Incremental updates
- Schema migrations
- Additional language parsers

These are not assumed and must be added explicitly.
