# Repository Snapshot → AST-Driven Intelligence Database

## Overview

This project builds a **repository intelligence database**.

The **database is the final source of truth**.  
The repository filesystem itself is **not used directly during analysis**.

The workflow intentionally has **two phases**:

- **PHASE 1 — PowerShell Snapshot**
- **PHASE 2 — Language-specific AST parsing and DB construction**

---

## Phase 1 — PowerShell Snapshot

### What the PowerShell Script Does

A **single PowerShell command** is run from the root of a repository.

That command produces **one text file**.

The PowerShell script:

- Walks the entire repository
- Captures the complete file structure
- Identifies which programming languages exist
- Records basic declared tools and dependencies (based on files present)
- Writes the full contents of every file inline

PowerShell **does not**:

- Analyze code semantics
- Build a database
- Perform AST parsing

PowerShell’s only job is to create a **deterministic, ordered snapshot** of the repository as **plain text**.

---

## The Output Text File (Important)

The output file is structured and ordered so it can be parsed easily by another program.

It contains clear section markers in this exact order:

### 1. REPO_ROOT
- The absolute path of the repository root when exported

### 2. FILE_STRUCTURE
- One line per file
- Each line is the repo-relative path

### 3. LANGUAGES
- One language per line
- Derived from file extensions only

### 4. REQUIRED_TOOLS
- Best-effort list inferred from files present  
- Example: Python, NodeJS, PowerShell

### 5. REQUIRED_DEPENDENCIES
- Best-effort list inferred from files present  
- Example: pip, npm, poetry

### 6. FILE_CONTENTS
- Every file is written inline
- Each file begins with a delimiter:

