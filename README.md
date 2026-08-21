# MultiClaude

Run multiple isolated [Claude Code](https://claude.com/claude-code) profiles side by side — e.g. a `work` and a `personal` one — each with its own login, conversation history, settings, and plugins.

## Why

Claude Code keeps all of its state (credentials, history, settings, plugins, memory) in a config directory that defaults to `~/.claude`. Pointing the `CLAUDE_CONFIG_DIR` environment variable elsewhere gives you a completely separate, independently-authenticated instance. This script automates creating a small wrapper command for each profile you want.

## Requirements

- `claude` (Claude Code) installed and on your `PATH`
- `bash`

No other dependencies — this is a plain shell script, not tied to any particular OS or package manager.

## Usage

```bash
./multiclaude-setup.sh
```

You'll be walked through naming each profile:

```
Welcome to MultiClaude!
Let's set up a few isolated Claude Code profiles.

Name your first claude: work
Add another claude? (y/n) y
Name your claude: personal
Add another claude? (y/n) n

Created /home/you/.local/bin/work (config dir: /home/you/.work)
Created /home/you/.local/bin/personal (config dir: /home/you/.personal)

Done! Set up 2 claude(s): work personal

Next: log in to each one separately (they don't share credentials):
  work
  personal
```

For each name you give it, the script creates:

- a wrapper command at `~/.local/bin/<name>` that sets `CLAUDE_CONFIG_DIR=~/.<name>` and execs `claude`
- the `~/.<name>` config directory

If `~/.local/bin` isn't already on your `PATH`, the script will tell you and print the line to add to your shell rc file.

### After setup

Log in to each profile separately — they don't share credentials:

```bash
work
personal
```

From then on, just run `work` or `personal` instead of `claude` to use that profile.

## Options

Set `MULTICLAUDE_BIN_DIR` to change where wrapper scripts are installed (default: `~/.local/bin`):

```bash
MULTICLAUDE_BIN_DIR=/usr/local/bin ./multiclaude-setup.sh
```

## Editor integration

Tools that launch Claude Code as an agent (e.g. Zed's ACP integration) can use the same trick directly — just set the `CLAUDE_CONFIG_DIR` environment variable per agent config, pointing at the matching `~/.<name>` directory, instead of going through the wrapper script.

### Zed on Arch Linux

Zed talks to Claude Code over [ACP](https://agentclientprotocol.com) via a separate binary, [`claude-agent-acp`](https://www.npmjs.com/package/@agentclientprotocol/claude-agent-acp). It's built on the same SDK as the `claude` CLI, so it honors `CLAUDE_CONFIG_DIR` the same way.

1. Install it:

   ```bash
   npm install -g @agentclientprotocol/claude-agent-acp
   ```

2. Find where it landed:

   ```bash
   which claude-agent-acp
   # or, if it's not on PATH:
   echo "$(npm root -g)/../bin/claude-agent-acp"
   ```

3. Log in to each profile from the terminal first (`work`, `personal`, ...) — `claude-agent-acp` doesn't drive an interactive login itself, so credentials need to already exist in each `~/.<name>` directory.

4. Add one `agent_servers` entry per profile to Zed's `settings.json` (`~/.config/zed/settings.json`), pointing `command` at the path from step 2 and `env.CLAUDE_CONFIG_DIR` at the matching config directory:

   ```json
   "agent_servers": {
     "Claude Work": {
       "type": "custom",
       "command": "/home/you/.npm-global/bin/claude-agent-acp",
       "args": [],
       "env": {
         "CLAUDE_CONFIG_DIR": "/home/you/.work"
       }
     },
     "Claude Personal": {
       "type": "custom",
       "command": "/home/you/.npm-global/bin/claude-agent-acp",
       "args": [],
       "env": {
         "CLAUDE_CONFIG_DIR": "/home/you/.personal"
       }
     }
   }
   ```

Each entry shows up as its own option in Zed's Agent panel. Selecting one spawns `claude-agent-acp` with that entry's `env`, so it only ever sees the credentials, history, and settings from its own config directory.
