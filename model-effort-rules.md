# Model and effort rules (Max 20x, interactive)

**Default:** Opus 5.5, effort medium, `/fast` on.

| Task | Effort |
|---|---|
| Typo, rename, one-function fix | low |
| "Where is X" lookup | low |
| Feature across several files | medium |
| Prose or docs | medium |
| Hard or intermittent bug | high or xhigh, set before you start |
| Architecture or planning | high or xhigh, set before you start |

## Subagents

### Search and exploration (built-in `Explore`)

- Use for: "where is X", "what calls Y", mapping a directory. It finds code; it does not judge it.
- Model: Sonnet. Without an override, Explore runs on Opus (tested: no `model` passed gives Opus 5.5).
- How: a rule in `~/.claude/CLAUDE.md` tells Claude to pass `model: "sonnet"` when it spawns Explore. A per-call model has the highest precedence, so the built-in Explore instructions stay (tested: gives Sonnet 5.5).
- Don't use Haiku: a missed result makes the main Opus search again, which costs more time than Haiku saves.
- Don't set `CLAUDE_CODE_SUBAGENT_MODEL`: it also moves research agents off Opus.
- Effort can't be set per call. Set it only through an agent file's `effort:` field.

### Research (`general-purpose`)

- Use for: reading docs or code, comparing options, reaching a conclusion.
- Model: Opus, which it gets by default from the main session. No setup needed.
- A wrong conclusion carries into everything built on it, so don't move research to a cheaper model.

## Triggers for raising effort

- Claude takes a confident wrong direction or edits the wrong place: raise one level.
- While debugging, any wrong answer: raise one level.
- A typo-level slip: don't raise, just correct it.

## How to retry

- Claude got a detail wrong: continue in the same conversation and say what's wrong.
- Claude went in the wrong direction: press `Esc Esc` or run `/rewind`, raise the effort, then send an improved prompt.
- Never retry at the same effort.

## Switching

- Changing effort mid-session is fine. Set it before you send the prompt.
- Don't switch the main session's model mid-session, because it reprocesses the context without the prompt cache. Use a fresh session or a subagent for a different model.
- Turn `/fast` off only if you hit usage limits or leave a long run going unattended.

## Default effort

`/effort` saves its choice as the default for new sessions, except `max`, which applies to the current session only. After raising effort for a hard task, set it back to medium.

## Check after one week

If you often raise effort on medium tasks, make high your default.
