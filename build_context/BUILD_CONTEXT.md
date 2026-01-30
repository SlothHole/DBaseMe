This project builds a repository intelligence database.

The database is the final source of truth.
The repository filesystem itself is not used directly during analysis.

The workflow intentionally has two phases:

PHASE 1 — PowerShell Snapshot
PHASE 2 — Language-specific AST parsing and DB construction

---

PHASE 1: WHAT THE POWERSHELL SCRIPT DOES

A single PowerShell command is run from the root of a repository.

That command produces ONE text file.

The PowerShell script:
- Walks the entire repository
- Captures the complete file structure
- Identifies which programming languages exist
- Records basic declared tools and dependencies (based on files present)
- Writes the full contents of every file inline

PowerShell does NOT analyze code semantics.
PowerShell does NOT build a database.
PowerShell does NOT perform AST parsing.

PowerShell’s only job is to create a deterministic, ordered snapshot of the repository as plain text.

---

THE OUTPUT TEXT FILE (IMPORTANT)

The output file is structured and ordered so it can be parsed easily by another program.

It contains clear section markers in this exact order:

1. REPO_ROOT
   - The absolute path of the repository root when exported

2. FILE_STRUCTURE
   - One line per file
   - Each line is the repo-relative path

3. LANGUAGES
   - One language per line
   - Derived from file extensions only

4. REQUIRED_TOOLS
   - Best-effort list inferred from files present
   - Example: Python, NodeJS, PowerShell

5. REQUIRED_DEPENDENCIES
   - Best-effort list inferred from files present
   - Example: pip, npm, poetry

6. FILE_CONTENTS
   - Every file is written inline
   - Each file begins with a delimiter:
     ----- FILE: <relative/path> -----
   - The content that follows is the exact file text

This file is complete and self-contained.
No additional filesystem access is required.

---

PHASE 2: WHAT IS BEING BUILT

A program (likely Python) will consume the TXT file.

That program will:
- Parse the sections
- Reconstruct file boundaries in memory
- Dispatch each file to an appropriate AST parser based on language
- Extract semantic data such as:
  - symbols (functions, classes, etc.)
  - calls
  - imports / dependencies
  - structural metadata

That extracted AST data will be written into a database.

The database becomes the authoritative representation of the repository.

The TXT file is a transport artifact only.
It is not queried directly once the DB exists.

---

WHY THIS DESIGN IS USED

This design exists to:
- Avoid repeated filesystem traversal
- Make analysis deterministic
- Simplify tooling (one input file)
- Make it easier to reason about and reproduce results
- Decouple extraction from analysis

All semantic intelligence comes from AST parsing, not from the TXT itself.

---

HOW CODEX SHOULD HELP

When helping with this project, Codex should:
- Reason about how to parse the TXT format
- Help design AST extraction per language
- Help design the database schema
- Help with data flow and structure

Codex should assume:
- The TXT format is fixed and intentional
- The database is the goal
- No filesystem access is available during analysis

Codex should not assume:
- Git history
- Runtime execution
- External tools being present
- That missing information can be inferred

If information is not in the TXT or AST output, it does not exist.
