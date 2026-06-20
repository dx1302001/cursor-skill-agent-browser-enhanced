---
name: agent-browser-enhanced
description: >-
  Extends vercel-labs/agent-browser with three workflows: send long multiline
  prompts without losing line breaks, detect when a browser/LLM task is complete,
  and capture full reply content from chat UIs. Use when automating ChatGPT,
  Claude, Gemini, or any web form with agent-browser, long prompts, multiline text,
  task completion, or full response extraction.
---

# agent-browser Enhanced

Built on [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser). Install base CLI first:

```bash
npm install -g agent-browser
agent-browser install
agent-browser doctor
```

Load upstream core skill when needed: `agent-browser skills get core`

## Core loop (unchanged)

```bash
agent-browser open <url>
agent-browser snapshot -i
agent-browser click @eN
# after any DOM change → snapshot -i again
```

---

## Capability 1: Long text / multiline prompts (no dropped lines)

**Problem**: `fill` and `keyboard type` may collapse or mishandle `\n` in rich editors and chat textareas.

**Decision tree**:

| Editor type | Method | Why |
|-------------|--------|-----|
| Plain `<textarea>` / `<input>` | `fill @eN` with literal newlines in quoted string | Fast, preserves `\n` in standard fields |
| Contenteditable / ProseMirror / Lexical | **clipboard paste** or `keyboard inserttext` | Avoids per-keystroke newline bugs |
| Very long prompt (>8KB) | **file → clipboard → paste** | Avoids shell escaping limits |

### Method A: Clipboard paste (recommended for chat UIs)

```powershell
# Windows: write prompt file, load to clipboard, paste into focused field
$prompt = Get-Content -Raw ".\prompt.txt"
$prompt | Set-Clipboard
agent-browser snapshot -i
agent-browser click @e_TEXTAREA_REF
agent-browser clipboard paste
```

```bash
# macOS
pbcopy < prompt.txt
agent-browser click @e_TEXTAREA_REF
agent-browser clipboard paste
```

### Method B: inserttext (no key events)

```bash
agent-browser click @e_EDITOR_REF
agent-browser keyboard inserttext "$(cat prompt.txt)"
```

Use when paste is blocked but direct insertion works.

### Method C: JS set value (fallback)

```bash
agent-browser eval --fn "(() => {
  const el = document.querySelector('textarea') || document.querySelector('[contenteditable=true]');
  const text = \`PASTE_ESCAPED_CONTENT_HERE\`;
  if (el.tagName === 'TEXTAREA') { el.value = text; el.dispatchEvent(new Event('input', {bubbles:true})); }
  else { el.innerText = text; el.dispatchEvent(new Event('input', {bubbles:true})); }
  return el.value?.length || el.innerText?.length;
})()"
```

Prefer file + clipboard over embedding huge strings in `eval`.

### Rules

1. **Never** split a long prompt across multiple `type` calls — race conditions and lost newlines.
2. Normalize line endings to `\n` before paste (`$text -replace "\r\n","\n"`).
3. After paste, `snapshot -i` and verify char count or preview text.
4. Use helper: `scripts/send-long-prompt.ps1` (see [reference.md](reference.md)).

---

## Capability 2: Determine task completion

**Problem**: Agent submits a prompt but does not know when generation finished.

### Layered completion signals

Use **all applicable** layers; stop when stable:

#### Layer 1: UI state (fast)

```bash
# Stop button / spinner gone
agent-browser wait --fn "!document.querySelector('[aria-label*=Stop], [data-testid*=stop], .streaming')"
agent-browser wait --text "Regenerate"    # site-specific: appears when done
agent-browser wait --load networkidle
```

#### Layer 2: Text stability (reliable for LLM replies)

Poll until response text unchanged for N seconds:

```bash
# Pseudocode — use scripts/wait-task-complete.ps1
# 1. snapshot or get text on response selector
# 2. wait 2s
# 3. get text again
# 4. if equal → done; else repeat (max 120s)
```

#### Layer 3: Snapshot diff (page settled)

```bash
agent-browser diff snapshot --baseline before.txt
# empty diff + no loading indicators → settled
```

#### Layer 4: Network idle (supplementary)

```bash
agent-browser wait --load networkidle
```

Not sufficient alone for streaming LLMs.

### Completion checklist

```
- [ ] No stop-button / streaming indicator in snapshot
- [ ] Response text stable ≥2s (two identical reads)
- [ ] No "Loading…" in body (wait --fn)
- [ ] Send button re-enabled (optional site-specific check)
```

### Timeout policy

| Phase | Default max |
|-------|-------------|
| Page load | 30s |
| LLM generation | 120–300s (model dependent) |
| Post-complete settle | 5s |

On timeout: `screenshot timeout.png`, save last text, report partial content.

---

## Capability 3: Get complete reply content

**Problem**: Partial DOM read, collapsed threads, or lazy-loaded messages truncate output.

### Step 1: Expand viewport

```bash
agent-browser scrollintoview @e_LAST_MESSAGE
agent-browser scroll down 2000
agent-browser scroll up 500
```

Repeat until no new content loads.

### Step 2: Extract full text

**By ref (preferred after snapshot)**:

```bash
agent-browser snapshot -i
agent-browser get text @e_ASSISTANT_MESSAGE
```

**By selector**:

```bash
agent-browser get text "[data-message-author-role=assistant]"
agent-browser get text ".markdown, .prose, [class*=message-content]"
```

**Full thread via JS** (when multiple bubbles):

```bash
agent-browser eval --fn "(() => {
  const nodes = [...document.querySelectorAll('[data-message-author-role=assistant], .assistant, .bot-message')];
  return nodes.map(n => n.innerText).join('\n\n---\n\n');
})()"
```

### Step 3: Verify completeness

1. Compare length vs visible snapshot preview.
2. Check last line not cut mid-sentence (heuristic: ends with `.` `。` `!` `?` or code-block close).
3. If site uses "Continue generating", click and re-extract.

### Step 4: Persist output

```bash
agent-browser get text @e_REPLY > reply.txt
agent-browser screenshot reply.png
```

Use helper: `scripts/get-full-response.ps1`

### For `agent-browser chat` command

```bash
agent-browser -q chat "your instruction"     # quiet: AI text only
agent-browser --json chat "instruction"      # structured for agents
```

Requires `AI_GATEWAY_API_KEY`. For third-party web UIs, use browser automation above, not `chat`.

---

## End-to-end: LLM web UI workflow

```bash
# 1. Open
agent-browser open https://TARGET_CHAT_URL
agent-browser snapshot -i

# 2. Long prompt (clipboard)
# ... send-long-prompt.ps1 ...

# 3. Submit
agent-browser click @e_SEND_BUTTON
# or agent-browser press Enter

# 4. Wait complete
# ... wait-task-complete.ps1 ...

# 5. Full reply
# ... get-full-response.ps1 ...

# 6. Cleanup
agent-browser close
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Newlines become spaces | Use clipboard paste or inserttext, not type |
| Ref stale after click | Re-run `snapshot -i` |
| Empty get text | scrollintoview first; try eval on parent container |
| Reply still growing | Increase stability wait; check for Stop button |
| Shell truncates prompt | Use prompt.txt file, never inline huge strings |

## Additional resources

- Command details and scripts: [reference.md](reference.md)
- Upstream: https://github.com/vercel-labs/agent-browser
