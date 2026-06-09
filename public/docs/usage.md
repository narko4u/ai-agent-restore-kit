# Usage Guide

## Installation

```bash
# Clone the public repo
git clone https://github.com/narko4u/ai-agent-restore-kit.git
cd ai-agent-restore-kit

# Make the quickstart executable
chmod +x public/quickstart.sh

# Run the demo
./public/quickstart.sh
```

## Commands

### Backup
Create a full snapshot of your agent's identity:

```bash
kit backup \
  --agent-dir /path/to/your/agent \
  --output ./backups \
  --name my-agent
```

Creates:
- `backups/agent-snapshot-<timestamp>.tar.gz` — compressed archive
- `backups/agent-snapshot-<timestamp>.manifest` — metadata + hashes

### Restore
Restore a snapshot to a fresh (or existing) agent instance:

```bash
kit restore \
  --snapshot ./backups/agent-snapshot-latest.tar.gz \
  --target /path/to/new/agent
```

Verification on restore:
- SHA256 hash of SOUL.md matches the manifest
- SQLite vault integrity check
- All expected files present

### Clone
Duplicate an agent with unique identity:

```bash
kit clone \
  --source /path/to/source-agent \
  --target /path/to/cloned-agent \
  --new-id "staging-agent-v2@mycompany.com" \
  --new-name "staging-v2"
```

The clone remaps:
- SOUL.md — agent name, ID, purpose
- Vault database — identity entries
- Configuration — agent name
- Memory files — all identity references

## Integration

### With Hermes Agent
Configure your Hermes instance to use the vault:

```yaml
# ~/.hermes/config.yaml
memory:
  vault_path: /path/to/sovereign_vault.db
  auto_sync: true
  loader_script: /path/to/sovereign_memory_loader.py
  writer_script: /path/to/sovereign_memory_writer.py
```

Set up a cron sync to keep memory files fresh:

```bash
# Every 5 minutes
*/5 * * * * python3 /path/to/sovereign_memory_loader.py --sync
```

### With Claude Code / Codex / OpenCode
These tools use their own memory formats, but the snapshot mechanism is
tool-agnostic. Run a backup before major operations:

```bash
# Before a model swap
kit backup --agent-dir ~/.claude --output ./backups --name pre-claude-swap

# Before a version upgrade  
kit backup --agent-dir ~/.opencode --output ./backups --name pre-upgrade

# Before migrating servers
kit backup --agent-dir ~/.opencode --output ./backups --name pre-migration
```

## Recovery Scenarios

### "My agent forgot everything after a model swap"
```bash
kit restore --snapshot ./backups/agent-snapshot-previous.tar.gz --target ~/.hermes
# Agent wakes up with its original identity, preferences, and knowledge
```

### "I cloned my agent but now they have the same identity"
```bash
kit clone --source ~/.hermes --target ~/.hermes-staging --new-id "staging-v1" --new-name "staging"
# Clean clone with unique identity — no collisions
```

### "My deployment failed and I need to rollback"
```bash
kit restore --snapshot ./backups/agent-snapshot-2026-06-09.tar.gz --target ~/.hermes
# Rolled back to a known-good state
```

## File Reference

| File | Purpose |
|------|---------|
| `SOUL.md` | Agent identity document |
| `config/agent.yaml` | Agent configuration |
| `config/.env.template` | Environment template (no secrets) |
| `memories/MEMORY.md` | Agent memory (flat, §-delimited) |
| `memories/USER.md` | User profile |
| `sovereign_vault.db` | Durable schema'd store |

## Best Practices

1. **Backup before any major change** — model swaps, version upgrades, server migrations
2. **Keep snapshots organised** — use descriptive names with dates
3. **Verify after restore** — the kit checks hashes automatically
4. **Store .env separately** — never include secrets in snapshots
5. **Test clones before using** — run the verification step
6. **Set up cron sync** — memory stays fresh even if agent restarts
7. **Version your snapshots** — keep the last N backups for rollback safety
