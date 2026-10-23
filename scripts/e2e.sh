#!/bin/sh
# Types real keystrokes into a Chrome textarea with a fresh LangFix per run, then prints what landed
# on screen. Chrome is used because TextEdit's autocorrect and auto-capitalisation rewrite the result.
# Needs Accessibility for the app that runs this terminal.
# usage: [TYPE_KEYS_LAYOUT=Thai] scripts/e2e.sh <keys as on a US keyboard, ⌫ for Delete> <ms-between-keys> [runs]
set -eu
cd "$(dirname "$0")/.."
keys=$1 gap=$2 runs=${3:-1}
swift build -c release --product LangFix >/dev/null 2>&1
swift build -c release --product type-keys >/dev/null
installed_was_running=$(pgrep -f '/Applications/LangFix.app' >/dev/null && echo yes || echo no)
trap 'pkill -x LangFix; [ "$installed_was_running" = yes ] && open -g /Applications/LangFix.app' EXIT
# Chrome can stop answering Apple Events; never let that hang the run.
chrome() { perl -e 'alarm 15; exec @ARGV' osascript -e "tell application \"Google Chrome\" to $1"; }
page='data:text/html,<title>-</title><textarea autofocus oninput="document.title=JSON.stringify(this.value)"></textarea>'
i=0
while [ "$i" -lt "$runs" ]; do
    pkill -x LangFix 2>/dev/null || true
    defaults delete LangFix ignoredWords 2>/dev/null || true
    .build/release/LangFix 2>/dev/null &
    sleep 2
    open -a "Google Chrome" "$page"
    sleep 2.5
    .build/release/type-keys "Google Chrome" "$keys" "$gap" || true
    sleep 0.8
    chrome 'get title of active tab of front window'
    chrome 'close active tab of front window' >/dev/null
    i=$((i + 1))
done
