#!/usr/bin/env bash
# SessionEnd hook: kill dev-server processes spawned by this Claude session.
#
# Bash-tool children inherit CLAUDE_CODE_SESSION_ID from the environment even
# after being detached/reparented to init via run_in_background, so we can
# scope the kill to exactly this session's descendants without touching any
# other concurrently running Claude session's dev servers.
set -uo pipefail

LOG=/home/mattijs/.claude/dev-server-reaper.log
DEV_SERVER_PATTERN='astro .*\bdev\b|vite( |$)|next dev|nuxt dev|webpack-dev-server|ng serve|flask run|uvicorn .*--reload|rails server|php artisan serve|php -S |django.*runserver|run dev\b|run start\b'

payload=$(cat)
session_id=$(printf '%s' "$payload" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*:"([^"]*)"/\1/')
[ -n "$session_id" ] || exit 0

for procdir in /proc/[0-9]*; do
	pid=${procdir#/proc/}
	[ -r "$procdir/environ" ] || continue
	env_sid=$(tr '\0' '\n' <"$procdir/environ" 2>/dev/null | grep '^CLAUDE_CODE_SESSION_ID=' | cut -d= -f2-)
	[ "$env_sid" = "$session_id" ] || continue
	cmd=$(tr '\0' ' ' <"$procdir/cmdline" 2>/dev/null)
	[[ "$cmd" =~ $DEV_SERVER_PATTERN ]] || continue
	printf '%s  session %s  killing pid %s: %s\n' "$(date -Is)" "$session_id" "$pid" "$cmd" >>"$LOG"
	kill -TERM "$pid" 2>/dev/null
done
exit 0
