# CCMeter <img src="demo.png" width="450" />

A macOS menu bar app that shows your Claude Code usage in close to real-time.

> **Requirements**: macOS 14+, Xcode (not just Command Line Tools), must be logged in via `claude login`

## Install

```bash
git clone https://github.com/t9nzin/ccmeter.git
cd ccmeter
./build.sh
open CCMeter.app
```

## Usage

Click the menu bar icon to see:
- **Session (5h)** - rolling 5-hour usage
- **Weekly** - rolling 7-day usage

## How it works

CCMeter reads your Claude Code OAuth token from the macOS Keychain (stored by `claude login`) and polls the Anthropic usage API. No credentials are stored by CCMeter itself.

Polling frequency adjusts based on usage:
- **< 50%**: every 5 minutes
- **50–74%**: every 60 seconds
- **75–89%**: every 45 seconds
- **≥ 90%**: every 30 seconds

The menu bar icon shows the Claude logo, which fills up circularly to reflect your current session (5h) utilization.

## Notes

This app reads your Claude Code OAuth token from the macOS Keychain. Review the source before running.
