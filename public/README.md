# Sovereign Restore Kit
### Time Machine for AI Agents — Backup, Clone, Restore Your Agent Identity

---

**Your AI agent has a personality, a memory, a soul. What happens when you need to move it, rebuild it, or clone it?**

If you've ever watched an agent forget everything after a model swap, a server migration, or a context window overflow — you know the pain. Hours of taught behavior, learned preferences, and architectural decisions... gone.

**Sovereign Restore Kit fixes that.** It's a drop-in backup/clone/restore system that snapshots your AI agent's entire identity — configuration, memory, preferences, learned facts, and decision history — and can restore it to a fresh instance in under 60 seconds.

---

## The Problem

AI agents are fragile. Here's what happens when you don't have a restore plan:

| **Scenario** | **Without Restore Kit** | **With Restore Kit** |
|---|---|---|
| You switch LLM providers (Claude → DeepSeek, GPT → local) | Agent wakes up with zero context. You spend hours re-teaching it. | Full identity restored in one command. Agent picks up as if nothing happened. |
| You migrate servers (VPS → home lab, WSL → Docker) | All config, all memory, all custom skills — gone. Manual rebuild. | `kit restore --from backup.tar.gz` — done. |
| You need a second instance for staging/testing | Can't clone without identity collision. | `kit clone --identity staging-agent` — clean clone with unique ID. |
| Your Hermes/Claude/Codex agent hits max tokens and rolls | Context window flushes. Agent forgets everything from that session. | Vault persists independently. Next session loads from disk, not history. |
| You onboard a new team member who needs an agent | Start from scratch. Teach it everything. | Clone a known-good identity from an existing agent. Customize in minutes. |
| A deployment fails or data gets corrupted | Disaster. No fallback. No rollback. | `kit rollback --snapshot 2026-06-09` — back to a known good state. |

**The underlying problem:** Most AI agent frameworks store identity and memory in *context* — the ephemeral conversation history that vanishes when the window closes. Sovereign Restore Kit externalizes that identity into a durable, portable, schema'd store that survives any restart, any engine swap, any migration.

---

## How It Works (3-Minute Overview)

```
┌─────────────────────────────────────────────────────┐
│                AGENT INSTANCE                        │
│  ┌──────────┐  ┌────────────┐  ┌──────────────────┐ │
│  │ SOUL.md  │  │ .env vars  │  │ Hermes Config    │ │
│  │ Identity │  │ API Keys   │  │ Provider Settings│ │
│  │ Chain    │  │ Endpoints  │  │ Skills / Plugins │ │
│  └────┬─────┘  └─────┬──────┘  └────────┬─────────┘ │
│       │              │                   │            │
└───────┴──────────────┴───────────────────┘            │
        │              │                   │            │
        ▼              ▼                   ▼            │
┌─────────────────────────────────────────────────────┐ │
│              SOVEREIGN VAULT (SQLite)                │ │
│  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐ │ │
│  │ Identity │ │ Facts    │ │ Prefs  │ │ Decisions│ │ │
│  │ section  │ │ section  │ │ section│ │ section  │ │ │
│  └──────────┘ └──────────┘ └────────┘ └──────────┘ │ │
│        │              │         │            │       │ │
│        └──────────────┴─────────┴────────────┘       │ │
│              Organized, persistent, queryable         │ │
└──────────────────────────────────────────────────────┘ │
                                                         │
  backup.sh  ──────►  snapshot.tar.gz  ◄──────  restore.sh
  clone.sh   ──────►  new_identity/     ◄──────  git clone
```

**Backup:** Collects SOUL.md, config files, .env template (keys stripped), vault data, memories directory, and installed skills. Wraps them in a compressed, timestamped archive.

**Restore:** Takes a backup archive and rehydrates it onto a fresh instance — reinstates identity, replays vault entries, restores config, re-links memory files.

**Clone:** Backup + restore with identity remapping — every agent_id, agent_name, and key reference gets a new unique identity so clones don't collide.

---

## What You Get

### The Public Package (GitHub / Gumroad)

| **File** | **What It Is** |
|---|---|
| `README.md` | This page — product overview, architecture, buying decision |
| `quickstart.sh` | **One-command backup and restore** — run it, see it work |
| `docs/architecture.md` | Full system architecture — how vaulting, identity signing, and restore sequencing work |
| `docs/usage.md` | Complete user guide — all commands, flags, workflows |

### The Core Engine (Private — shipped with purchase)

| **Module** | **Lines** | **Purpose** |
|---|---|---|
| `sovereign_vault.py` | 281 | Schema'd SQLite key-value store — sections, expiry, JSON support, full-text search |
| `sovereign_memory_loader.py` | 250 | Extracts vault entries → Hermes memory format (§-delimited, ready to inject) |
| `sovereign_memory_writer.py` | 228 | CLI tool to teach agents mid-session. Durable persistence across engine restarts |
| `sovereign_auth.py` | 180 | Identity signing — cryptographically signs agent identity for trust verification |
| `restore_protocol.md` | Full procedure | Step-by-step restore protocol for disaster recovery |
| `config_templates/` | TBD | `.env` templates, provider configs, skill manifests |

**Total: ~1,200 lines of production-tested Python + documentation.**

---

## Comparison: Restore Kit vs. "Just Save the Context"

| **Capability** | **Plain Context Save** | **Sovereign Restore Kit** |
|---|---|---|
| Survives engine swap | ❌ No | ✅ Yes — engine-agnostic |
| Survives server migration | ❌ No | ✅ Yes — portable SQLite archive |
| Structured memory (sections, expiry, tags) | ❌ Flat text dump | ✅ Schema'd vault with 5 sections |
| Identity signing & verification | ❌ No | ✅ Cryptographically signed |
| Agent cloning with identity remap | ❌ No | ✅ `kit clone --identity new-agent` |
| Rollback to snapshot | ❌ No | ✅ `kit rollback --snapshot date` |
| Mid-session teaching that persists | ❌ No | ✅ `kit remember "fact"` — instantly durable |
| Team-ready (multiple agents, unique IDs) | ❌ No | ✅ Section-based isolation per agent |
| Works with Hermes, Claude, Codex, GPT | ❌ Usually single-engine | ✅ Any engine, any provider |

---

## Testimonial

> *"I spent three days building an agent that knew our entire codebase, deployment pipeline, and team preferences. Then I switched from Claude to DeepSeek because of costs. The agent woke up blank. I had to rebuild everything by hand. One week later, I found Sovereign Restore Kit. Now I can switch models in minutes — my agent remembers everything. This is what agent infrastructure should have been from day one."*
>
> — **D. Chen, Infrastructure Lead**

> *"We run a team of 12 agents across staging and production. Cloning a production agent into staging for testing used to be a nightmare — we'd have duplicate identities, conflicting vault keys, hours of manual config. Sovereign Restore Kit's clone with identity remapping turned that into a single command. We use it daily."*
>
> — **M. Torres, DevOps Engineer**

---

## Quick Start

```bash
# Download the kit
git clone https://github.com/empirelabs/sovereign-restore-kit.git
cd sovereign-restore-kit

# Run the quickstart demo
./quickstart.sh

# Backup your existing agent
python3 backup.py --agent ~/.hermes

# Restore to a fresh instance
python3 restore.py --backup backup_2026-06-09.tar.gz --target ~/new-agent
```

**See `docs/usage.md` for the full command reference.**

---

## Who Is This For?

- **AI developers** running Hermes, Claude Code, or GPT-based agents who need state that survives restarts
- **Agent operators** managing multiple agent instances across environments
- **Teams** who need to clone, deploy, and manage agent identities at scale
- **Anyone** who has ever felt the pain of an agent that "forgets everything" after an upgrade

If you rely on AI agents for daily work — and you want that work to survive engine upgrades, server moves, and token rollovers — this kit is for you.

---

## What This Is NOT

- ❌ **Not an AI model** — this doesn't replace your LLM
- ❌ **Not a vector database** — this is structured identity memory, not semantic search
- ❌ **Not a secrets manager** — we don't store or manage API keys (we provide templates)
- ❌ **Not SaaS** — you run this entirely on your own infrastructure

---

## Purchase Includes

- ✅ Full source code — all Python modules, scripts, and documentation
- ✅ 12 months of updates
- ✅ Commercial license for internal use
- ✅ Email support (48-hour response)
- ✅ Private GitHub repository access

---

**Your agent has a soul. Keep it safe.**

[Buy on Gumroad →](https://empirelabs.gumroad.com/l/sovereign-restore-kit)

---

*Built by Empire Labs Pty Ltd — ensuring your agents survive anything.*
