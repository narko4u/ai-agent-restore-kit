# Architecture

## Overview

The Sovereign Restore Kit externalizes an AI agent's identity from ephemeral
context into a durable, portable, schema'd store. This breaks the dependency
between the agent's "soul" and the runtime that hosts it.

## Core Principle

```
┌─────────────────────────────────────────────────┐
│                  Agent Runtime                   │
│   (Hermes, Claude Code, Codex, OpenCode...)      │
└──────────────────┬──────────────────────────────┘
                   │ interacts with
                   ▼
┌─────────────────────────────────────────────────┐
│              Sovereign Restore Kit               │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐ │
│  │  Vault   │  │ Memory   │  │   Identity    │ │
│  │ (SQLite) │  │ (Files)  │  │   (SOUL.md)   │ │
│  └──────────┘  └──────────┘  └───────────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │           Backup / Restore Engine            ││
│  │  → snapshot (tar.gz)                         ││
│  │  → restore (extract + verify)                ││
│  │  → clone (duplicate + remap identity)        ││
│  └──────────────────────────────────────────────┘│
└──────────────────────────────────────────────────┘
```

## Components

### 1. SQLite Vault (`sovereign_vault.db`)
The durable store. An SQLite database with a single `vault` table:

| Column | Type | Purpose |
|--------|------|---------|
| `section` | TEXT PK | Category group (identity, preferences, facts, decisions, user) |
| `key` | TEXT PK | Entry name |
| `value` | TEXT | Stored data (string, JSON, or serialized) |
| `value_type` | TEXT | Type marker: string, json, int, bool |
| `created_at` | TEXT | ISO-8601 creation timestamp |
| `updated_at` | TEXT | ISO-8601 last-modified timestamp |
| `expires_at` | TEXT | Optional TTL for ephemeral entries |
| `tags` | TEXT | Comma-separated tags for filtering |

Why SQLite:
- Single file — portable across systems
- No daemon — zero dependencies
- ACID compliant — safe against crashes
- SQL queryable — easy to introspect and debug
- WAL mode — concurrent readers don't block

### 2. Memory Files (`MEMORY.md`, `USER.md`)
Flat §-delimited markdown files that the agent reads on startup. These are
a cache of the vault designed for fast parsing — the agent loads them once
and has all key facts in context without SQL queries.

The memory loader (`sovereign_memory_loader.py`) syncs vault → memory files.
The memory writer (`sovereign_memory_writer.py`) writes vault ← memory files.

### 3. Identity Document (`SOUL.md`)
The agent's "constitution" — defines who it is, who it reports to, its
operating boundaries, and its behavioural rules. This is the first thing
restored because it defines the agent's core identity.

### 4. Configuration (`agent.yaml`, `.env.template`)
Environment-agnostic configuration files that define provider, model,
context length, logging, and other operational parameters.

### 5. Snapshot Engine
The core backup/restore mechanism:

```
snapshot → collect (SOUL.md + config + memory + vault exports)
         → compress (tar.gz)
         → manifest (SHA256 hashes + metadata)

restore → extract (tar.gz)
        → verify (hash comparison)
        → rebuild (SQLite integrity check)

clone   → snapshot + restore
        → identity remap (search & replace SOUL.md + vault entries)
        → verify (no identity collisions)
```

## Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Agent      │     │  Memory      │     │  SQLite      │
│  Starts     │────>│  Loader      │────>│  Vault       │
└─────────────┘     │  (reads      │     │  (writes)    │
                    │   MEMORY.md) │     └──────┬───────┘
                    └──────┬───────┘            │
                           │                    │
                    ┌──────▼───────┐    ┌───────▼──────┐
                    │  Memory      │    │  Snapshot    │
                    │  Writer      │<───│  Engine      │
                    │  (syncs to   │    │  (backup/    │
                    │   vault)     │    │   restore)   │
                    └──────────────┘    └──────────────┘
```

## Security Model

- **No secrets in snapshots** — .env files are excluded; templates only
- **No credentials in memory** — vault stores facts, not passwords
- **SHA256 verification** — integrity check on restore
- **Identity remapping** — clones get unique IDs, no collision risk
- **Read-only fallback** — if vault is missing, agent runs on static defaults
