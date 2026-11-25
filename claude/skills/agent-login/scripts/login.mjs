#!/usr/bin/env node
// Signs Claude's browser in to a web app with credentials from the environment,
// so they reach the login form without passing through Claude's context.
// Run under `op run --env-file <app>.env --`, which injects them from 1Password.
//
// Env: AGENT_LOGIN_URL, AGENT_LOGIN_USERNAME, AGENT_LOGIN_PASSWORD,
// optional AGENT_LOGIN_CDP (default http://127.0.0.1:9333).
// Never prints the credentials; prints where the browser ended up.

const STEP_TIMEOUT_MS = 20_000
const MAX_STEPS = 6

const { AGENT_LOGIN_URL: loginUrl, AGENT_LOGIN_USERNAME: username, AGENT_LOGIN_PASSWORD: password } =
  process.env
const cdpUrl = process.env.AGENT_LOGIN_CDP ?? 'http://127.0.0.1:9333'

function fail(message) {
  console.error(`agent-login: ${message}`)
  process.exit(1)
}

for (const [name, value] of Object.entries({ AGENT_LOGIN_URL: loginUrl, AGENT_LOGIN_USERNAME: username, AGENT_LOGIN_PASSWORD: password })) {
  if (!value) fail(`${name} is not set; run under op run --env-file <app>.env`)
  if (value.startsWith('op://')) fail(`${name} is an unresolved op:// reference; run under op run`)
}

async function openTarget() {
  let res
  try {
    res = await fetch(`${cdpUrl}/json/new?about:blank`, { method: 'PUT' })
  } catch {
    fail(`no browser at ${cdpUrl}; make one chrome-devtools call first so the MCP launches it`)
  }
  if (!res.ok) fail(`browser at ${cdpUrl} refused a new tab (${res.status})`)
  return res.json()
}

function connect(wsUrl) {
  const ws = new WebSocket(wsUrl)
  const pending = new Map()
  let nextId = 0
  ws.addEventListener('message', ({ data }) => {
    const msg = JSON.parse(data)
    const waiter = pending.get(msg.id)
    if (!waiter) return
    pending.delete(msg.id)
    msg.error ? waiter.reject(new Error(msg.error.message)) : waiter.resolve(msg.result)
  })
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = ++nextId
      pending.set(id, { resolve, reject })
      ws.send(JSON.stringify({ id, method, params }))
    })
  return new Promise((resolve, reject) => {
    ws.addEventListener('open', () => resolve({ send, close: () => ws.close() }))
    ws.addEventListener('error', () => reject(new Error(`cannot connect to ${wsUrl}`)))
  })
}

// Runs in the page. Finds the visible username and password fields; `focus`
// names the one to focus and clear before typing into it.
function pageState(focus) {
  const visible = (el) => el && el.offsetParent !== null && !el.disabled && !el.readOnly
  const pick = (selector) => [...document.querySelectorAll(selector)].find(visible) ?? null
  const user = pick(
    'input[type=email], input[autocomplete=username], input[name=identifier], input[name=email], input[name=username], input[name=login]',
  )
  const pass = pick('input[type=password]')
  const target = focus === 'user' ? user : focus === 'pass' ? pass : null
  if (target) {
    target.focus()
    target.select()
  }
  const alert = pick('[role=alert], [aria-live=assertive]')
  return {
    url: location.href,
    path: location.pathname,
    user: user ? (user.value ? 'filled' : 'empty') : 'none',
    pass: pass ? (pass.value ? 'filled' : 'empty') : 'none',
    alert: alert?.textContent?.trim().slice(0, 200) ?? '',
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

async function main() {
  const target = await openTarget()
  const page = await connect(target.webSocketDebuggerUrl)
  const evaluate = async (focus) => {
    const { result, exceptionDetails } = await page.send('Runtime.evaluate', {
      expression: `(${pageState})(${JSON.stringify(focus ?? null)})`,
      returnByValue: true,
    })
    if (exceptionDetails) throw new Error(exceptionDetails.text)
    return result.value
  }
  const type = async (focus, text) => {
    await evaluate(focus)
    await page.send('Input.insertText', { text })
  }
  const pressEnter = async () => {
    const key = { key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 }
    await page.send('Input.dispatchKeyEvent', { type: 'keyDown', text: '\r', ...key })
    await page.send('Input.dispatchKeyEvent', { type: 'keyUp', ...key })
  }
  const loginPath = new URL(loginUrl).pathname

  try {
    await page.send('Page.navigate', { url: loginUrl })
    for (let step = 0; step < MAX_STEPS; step++) {
      const deadline = Date.now() + STEP_TIMEOUT_MS
      let state
      for (;;) {
        await sleep(500)
        state = await evaluate().catch(() => null)
        if (!state) continue
        const signedIn = state.user === 'none' && state.pass === 'none' && !state.path.startsWith(loginPath)
        const actionable = state.user === 'empty' || state.pass === 'empty'
        if (signedIn) {
          console.log(`agent-login: signed in, browser is at ${state.url}`)
          return
        }
        if (actionable || Date.now() > deadline) break
      }
      if (state.pass === 'empty') {
        if (state.user === 'empty') await type('user', username)
        await type('pass', password)
      } else if (state.user === 'empty') {
        await type('user', username)
      } else {
        fail(
          `still on the login page at ${state.url}` +
            (state.alert ? `; the page says: "${state.alert}"` : '; it may need a step this script does not do (code, captcha, SSO)'),
        )
      }
      await pressEnter()
    }
    fail('gave up after too many form steps')
  } finally {
    page.close()
    await fetch(`${cdpUrl}/json/close/${target.id}`).catch(() => {})
  }
}

main().catch((error) => fail(error.message))
