---
name: agent-login
description: Sign Claude's chrome-devtools browser in to a web app with a username and password kept in 1Password, without the credentials ever entering the conversation. Use when a browser task hits a login page or needs a signed-in session, e.g. "check this page while logged in", "take a screenshot of the dashboard".
---

# Agent login

Signs the `chrome-devtools` MCP's browser in to an app. `op run` resolves the
app's 1Password references into the environment of `scripts/login.mjs` only;
the script types them into the login form over the browser's debugging port
(`127.0.0.1:9333`). The session lands in the MCP's profile and lasts as long
as the app's own session does, so sign in once and reuse it.

## Steps

1. **Check whether you're already signed in.** Open the page you need with
   `chrome-devtools`. If it isn't a login page, there's nothing to do. Any
   `chrome-devtools` call also makes sure the browser is running, which the
   script needs.
2. **Find the app's env file** in `~/.config/agent-login/`, named after the app
   (`<app>.env`). It holds `op://` references, not secrets, so reading it is
   fine. If there's none for this app, stop and tell me what to create: the
   file path and the three lines from `example.env`, with the app's login URL
   filled in.
3. **Sign in:**

   ```sh
   op run --env-file ~/.config/agent-login/<app>.env -- node ~/.claude/skills/agent-login/scripts/login.mjs
   ```

   The first `op` call in a while may wait on a 1Password approval on my
   screen; give it a minute.
4. **Carry on in the same browser** with `chrome-devtools`. The script closes
   its own tab; open the page you need again.

## When it fails

Report the script's message as it is and stop. It says where the browser
ended up and what the page showed, e.g. a wrong-password alert, or a step it
doesn't do: an emailed code, a captcha, SSO. Don't retry with other
credentials or work around it in the form yourself.

## Never

- Read a secret yourself: no `op read`, `op item get`, `op inject`, `printenv`
  or `echo` of a resolved value.
- Type a password through `chrome-devtools` (`fill`, `type_text`,
  `fill_form`). Only `login.mjs` puts credentials into a page.
- Copy a resolved value into a file, a command line or the conversation.
