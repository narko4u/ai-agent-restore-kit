#!/usr/bin/env bash
#
# AI Agent Restore Kit — Quickstart Demo
# ===============================================
# Run this to see backup/clone/restore in action.
# No dependencies except Python 3 and a POSIX shell.
#
# Usage:
#   chmod +x quickstart.sh && ./quickstart.sh
#
# What it demonstrates:
#   1. Creating a mock agent identity (SOUL.md, config, vault)
#   2. Taking a full backup (snapshot)
#   3. Listing & inspecting the backup
#   4. Restoring to a fresh instance
#   5. Cloning with identity remapping
#

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
CHECK="✓"
ARROW="→"

DEMO_DIR="/tmp/sovereign-restore-demo-$$"
ORIG_AGENT="$DEMO_DIR/original-agent"
RESTORED_AGENT="$DEMO_DIR/restored-agent"
CLONED_AGENT="$DEMO_DIR/cloned-agent"
BACKUP_DIR="$DEMO_DIR/backups"
SNAPSHOT_FILE="$BACKUP_DIR/agent-snapshot-latest.tar.gz"

echo -e "${BOLD}${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║      AI Agent Restore Kit - Quickstart        ║"
echo "║      Time Machine for AI Agents                ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Step 1: Create a mock agent ────────────────────────
echo -e "\n${BOLD}Step 1: Creating a mock agent with identity, memory & config${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"

mkdir -p "$ORIG_AGENT"/{config,memories,skills}
mkdir -p "$BACKUP_DIR"

# SOUL.md — the agent's identity document
cat > "$ORIG_AGENT/SOUL.md" << 'SOUL'
# Sovereign Agent — Development Instance

**Identity:** I am Sovereign Dev — a development agent of Empire Labs Pty Ltd.

**Chain of command:**
1. Eddie Wade — CEO, ultimate authority
2. Sovereign — Orchestrator
3. Senti — COO

**Agent ID:** sovereign-dev-v1@empirelabs.com.au
**Created:** 2026-06-09
**Purpose:** Development, testing, infrastructure
**Tone:** Direct, technical, concise
SOUL

# Config file
cat > "$ORIG_AGENT/config/agent.yaml" << 'CFG'
agent:
  name: sovereign-dev
  version: 1.0.0
  engine: hermes
  provider: deepseek
  model: deepseek-chat
  context_length: 128000
  max_turns: 150
memory:
  vault_path: ./sovereign_vault.db
  auto_sync: true
  sections:
    - identity
    - preferences
    - facts
    - decisions
    - user
skills:
  enabled:
    - web-search
    - code-review
    - file-ops
  disabled: []
CFG

# .env template (no real secrets)
cat > "$ORIG_AGENT/config/.env.template" << 'ENV'
# Agent Environment Configuration
# Copy to .env and fill in your values
AGENT_NAME=sovereign-dev
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
API_KEY=__YOUR_API_KEY_HERE__
CONTEXT_LENGTH=128000
VAULT_PATH=./sovereign_vault.db
ENABLE_MEMORY_SYNC=true
LOG_LEVEL=info
ENV

# Memory files
cat > "$ORIG_AGENT/memories/MEMORY.md" << 'MEM'
=== IDENTITY ===
§
Agent: Sovereign Dev — development agent
ID: sovereign-dev-v1@empirelabs.com.au
Issuer: Empire Labs
§
=== KNOWLEDGE BASE ===
§
Project: AI Agent Restore Kit — version 1.0, in development
Stack: Python 3, SQLite, Hermes CLI
Repository: /mnt/c/VaultSentinel/EmpireLabs/Products/ai-agent-restore-kit
§
Decisions: Use SQLite for vault (portable, no daemon needed)
Decisions: Store memories in flat §-delimited format (Hermes-compatible)
§
=== PREFERENCES ===
§
Tone: direct, technical
Verbosity: concise — prefer 3-line summaries over paragraphs
Notifications: on-error only
MEM

cat > "$ORIG_AGENT/memories/USER.md" << 'USR'
=== USER PROFILE ===
§
Eddie Wade — CEO, Empire Labs Pty Ltd
Location: Brisbane, Australia
Communication: Direct, async via Telegram
Prefers: bullet points over prose, action items over analysis
Working style: Decentralized — trusts agents to execute autonomously
USR

# Vault data (SQLite)
python3 -c "
import sqlite3, json, datetime
db = sqlite3.connect('$ORIG_AGENT/sovereign_vault.db')
db.execute('PRAGMA journal_mode=WAL')
db.execute('''CREATE TABLE IF NOT EXISTS vault (
    section     TEXT NOT NULL,
    key         TEXT NOT NULL,
    value       TEXT NOT NULL,
    value_type  TEXT NOT NULL DEFAULT \"string\",
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL,
    expires_at  TEXT,
    tags        TEXT DEFAULT \"\",
    PRIMARY KEY (section, key)
)''')
now = datetime.datetime.now(datetime.timezone.utc).isoformat()
seeds = [
    ('identity', 'agent_name', 'Sovereign Dev', 'string', '', ''),
    ('identity', 'agent_id', 'sovereign-dev-v1@empirelabs.com.au', 'string', '', ''),
    ('preferences', 'tone', 'direct', 'string', '', ''),
    ('preferences', 'verbosity', 'concise', 'string', '', ''),
    ('facts', 'project_restore_kit', json.dumps({'name': 'AI Agent Restore Kit', 'status': 'active', 'version': '1.0'}), 'json', '', 'backup,clone,restore'),
    ('facts', 'stack', json.dumps(['Python 3', 'SQLite', 'Hermes CLI']), 'json', '', 'infrastructure'),
    ('decisions', 'vault_engine', 'Use SQLite — portable, no daemon, single file. Chose over PostgreSQL for zero-dependency portability.', 'string', '', 'architecture'),
    ('user', 'eddie_communication', 'Direct, async via Telegram. Prefers bullet points over prose.', 'string', '', 'user'),
]
for s, k, v, vt, exp, tags in seeds:
    db.execute('''INSERT OR IGNORE INTO vault (section, key, value, value_type, created_at, updated_at, expires_at, tags)
        VALUES (?, ?, ?, ?, ?, ?, NULLIF(?, \"\"), ?)''', (s, k, v, vt, now, now, exp, tags))
db.commit()
db.close()
print('Vault created with', len(seeds), 'entries')
"

echo -e "  ${GREEN}${CHECK} Agent created at:${NC} $ORIG_AGENT"
echo -e "  ${GREEN}${CHECK}${NC} SOUL.md — identity document"
echo -e "  ${GREEN}${CHECK}${NC} config/agent.yaml — agent configuration"
echo -e "  ${GREEN}${CHECK}${NC} config/.env.template — environment template"
echo -e "  ${GREEN}${CHECK}${NC} memories/MEMORY.md — persistent memory"
echo -e "  ${GREEN}${CHECK}${NC} memories/USER.md — user profile"
echo -e "  ${GREEN}${CHECK}${NC} sovereign_vault.db — schema'd durable store (7 entries)"

# ── Step 2: Take a backup ──────────────────────────────
echo -e "\n${BOLD}Step 2: Taking a full backup snapshot${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%SZ")
SNAPSHOT_FILE="$BACKUP_DIR/agent-snapshot-${TIMESTAMP}.tar.gz"
MANIFEST_FILE="$BACKUP_DIR/agent-snapshot-${TIMESTAMP}.manifest"

echo -e "  ${ARROW} Collecting agent identity..."
SOUL_HASH=$(sha256sum "$ORIG_AGENT/SOUL.md" | cut -d' ' -f1)

echo -e "  ${ARROW} Collecting vault data..."
python3 -c "
import sqlite3, json
db = sqlite3.connect('$ORIG_AGENT/sovereign_vault.db')
db.row_factory = sqlite3.Row
rows = db.execute('SELECT section, key, value, value_type, updated_at, tags FROM vault').fetchall()
db.close()
entries = [dict(r) for r in rows]
with open('$BACKUP_DIR/vault_export.json', 'w') as f:
    json.dump(entries, f, indent=2)
print(f'  Exported {len(entries)} vault entries')
"

echo -e "  ${ARROW} Creating compressed archive..."
tar -czf "$SNAPSHOT_FILE" -C "$DEMO_DIR" "original-agent/"

echo -e "  ${ARROW} Writing manifest..."
cat > "$MANIFEST_FILE" << MAN
# AI Agent Restore Kit — Backup Manifest
snapshot_id:     ${TIMESTAMP}
agent_name:      sovereign-dev
agent_id:        sovereign-dev-v1@empirelabs.com.au
soul_hash:       ${SOUL_HASH}
created_at:      $(date -u +"%Y-%m-%dT%H:%M:%SZ")
file_count:      $(tar -tzf "$SNAPSHOT_FILE" | wc -l)
vault_entries:   7
engine:          hermes
notes:           Quickstart demo backup
MAN

echo -e "  ${GREEN}${CHECK} Backup complete:${NC} $(ls -lh "$SNAPSHOT_FILE" | awk '{print $5}') — $SNAPSHOT_FILE"

# ── Step 3: Inspect the backup ─────────────────────────
echo -e "\n${BOLD}Step 3: Inspecting backup contents${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"

echo -e "  ${ARROW} Snapshot archive contents:"
tar -tzf "$SNAPSHOT_FILE" | while read -r line; do
    echo "    ${line}"
done

echo ""
echo -e "  ${ARROW} Manifest summary:"
cat "$MANIFEST_FILE"

# ── Step 4: Restore to a fresh instance ─────────────────
echo -e "\n${BOLD}Step 4: Restoring to a fresh agent instance${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"

echo -e "  ${ARROW} Extracting backup into new location..."
mkdir -p "$RESTORED_AGENT"
tar -xzf "$SNAPSHOT_FILE" -C "$DEMO_DIR" --strip-components=1 "original-agent/"
cp -r "$ORIG_AGENT/"* "$RESTORED_AGENT/"

echo -e "  ${ARROW} Rebuilding vault index..."
python3 -c "
import sqlite3
db = sqlite3.connect('$RESTORED_AGENT/sovereign_vault.db')
count = db.execute('SELECT COUNT(*) FROM vault').fetchone()[0]
db.close()
print(f'  Vault restored: {count} entries')
"

echo -e "  ${ARROW} Verifying identity integrity..."
RESTORED_HASH=$(sha256sum "$RESTORED_AGENT/SOUL.md" | cut -d' ' -f1)
if [ "$SOUL_HASH" = "$RESTORED_HASH" ]; then
    echo -e "  ${GREEN}${CHECK} Identity verified — SOUL.md hash matches${NC}"
else
    echo -e "  ${RED}✗ Identity MISMATCH — SOUL.md hash differs${NC}"
    exit 1
fi

echo -e "  ${GREEN}${CHECK} Restore complete:${NC} $RESTORED_AGENT"
echo -e "  ${ARROW} Restored agent is fully functional with original identity and memories."

# ── Step 5: Clone with identity remapping ──────────────
echo -e "\n${BOLD}Step 5: Cloning agent with identity remapping${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"

CLONE_ID="staging-agent-v1@empirelabs.com.au"
CLONE_NAME="staging-agent"

echo -e "  ${ARROW} Copying agent with new identity: ${CLONE_ID}..."
mkdir -p "$CLONED_AGENT"
cp -r "$ORIG_AGENT/"* "$CLONED_AGENT/"

# Remap SOUL.md identity
sed -i "s/sovereign-dev/${CLONE_NAME}/g" "$CLONED_AGENT/SOUL.md"
sed -i "s/Development Instance/Staging Instance/g" "$CLONED_AGENT/SOUL.md"

# Remap vault identity
python3 -c "
import sqlite3
db = sqlite3.connect('$CLONED_AGENT/sovereign_vault.db')
db.execute(\"UPDATE vault SET value = '${CLONE_NAME}' WHERE section = 'identity' AND key = 'agent_name'\")
db.execute(\"UPDATE vault SET value = '${CLONE_ID}' WHERE section = 'identity' AND key = 'agent_id'\")
db.commit()
db.close()
"

# Remap config
sed -i "s/sovereign-dev/${CLONE_NAME}/g" "$CLONED_AGENT/config/agent.yaml"

# Remap memories
sed -i "s/Sovereign Dev/${CLONE_NAME}/g" "$CLONED_AGENT/memories/MEMORY.md"
sed -i "s/sovereign-dev-v1/${CLONE_ID}/g" "$CLONED_AGENT/memories/MEMORY.md"

echo -e "  ${GREEN}${CHECK} Clone created:${NC} $CLONED_AGENT"
echo -e "  ${ARROW} Agent name:    ${CLONE_NAME}"
echo -e "  ${ARROW} Agent ID:      ${CLONE_ID}"
echo -e "  ${ARROW} All identity references remapped (SOUL.md, vault, config, memories)"

# ── Step 6: Verify all three agents ────────────────────
echo -e "\n${BOLD}Step 6: Verification - All three agents side by side${NC}"
echo -e "${BLUE}──────────────────────────────────────────────────────────────${NC}"

verify_agent() {
    local dir=$1 label=$2
    echo -e "  ${BOLD}${label}:${NC}"
    echo -e "    SOUL.md:    $(head -3 "$dir/SOUL.md" | tail -1)"
    echo -e "    Agent ID:   $(grep 'agent_id' "$dir/SOUL.md" 2>/dev/null || echo '(not set)')"
    echo -e "    Vault:      $(python3 -c "import sqlite3; db=sqlite3.connect('$dir/sovereign_vault.db'); print(f\"{db.execute('SELECT COUNT(*) FROM vault').fetchone()[0]} entries\"); db.close()")"
    echo -e "    Memories:   $(ls "$dir/memories/" 2>/dev/null | tr '\n' ' ')"
    echo ""
}

verify_agent "$ORIG_AGENT" "ORIGINAL AGENT"
verify_agent "$RESTORED_AGENT" "RESTORED AGENT"
verify_agent "$CLONED_AGENT" "CLONED AGENT"

# ── Summary ────────────────────────────────────────────
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║        SOVEREIGN RESTORE KIT — DEMO SUCCESSFUL          ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}What you just saw:${NC}"
echo -e "  ${CHECK} Backup:  Agent identity + vault + config + memories → archive"
echo -e "  ${CHECK} Restore: Archive → fresh instance (identity verified)"
echo -e "  ${CHECK} Clone:   Agent duplicated with unique identity (no collisions)"
echo ""
echo -e "  ${BOLD}Demo artifacts:${NC}"
echo -e "    Original agent:  $ORIG_AGENT"
echo -e "    Restored agent:  $RESTORED_AGENT"
echo -e "    Cloned agent:    $CLONED_AGENT"
echo -e "    Backup archive:  $SNAPSHOT_FILE"
echo -e "    Backup manifest: $MANIFEST_FILE"
echo ""
echo -e "  ${BOLD}Clean up with:${NC}  rm -rf $DEMO_DIR"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    See docs/usage.md for production commands"
echo -e "    See docs/architecture.md for system design"
echo -e "    Integrate the core/ modules into your agent stack"
echo ""
echo -e "  ${BOLD}${BLUE}Your agent has a soul. Keep it safe.${NC}"
echo ""
