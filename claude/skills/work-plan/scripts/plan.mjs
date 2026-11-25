#!/usr/bin/env node
// The deterministic half of work-plan: the plan folder's state, its gates and
// its consistency checks. The skills judge; this script only counts, so a gate
// can't be talked past. File formats: ../references/plan-files.md.
//
//   plan.mjs init   <dir> --slug <s> --size <task|feature|project|tickets> --repo <name>=<path>... [--design <src>]
//   plan.mjs status <dir> [--json]      phases (pending / done / stale), open questions, next step
//   plan.mjs gate   <dir> <phase|publish>  exit 1, with reasons, if that step can't start yet
//   plan.mjs stamp  <dir> <phase>       record a phase as done against its current inputs
//   plan.mjs check  <dir>               tickets and wave table: waves, cycles, overlap, coverage
//   plan.mjs resize <dir> <size>        change the size, and so the phases; stamps are kept
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const ALL = ['recon', 'brief', 'contracts', 'split', 'review'];
const PHASES_BY_SIZE = {
  task: ['recon', 'brief', 'split', 'review'],
  feature: ALL,
  project: ALL,
  tickets: ['review'],
};
// What each phase reads. A phase goes stale when one of these changes after it
// was stamped, or when an earlier phase is re-stamped after it.
const INPUTS = {
  recon: ['input/', '@repos'],
  brief: ['input/', 'context/'],
  contracts: ['brief.md', 'decisions.md', 'context/'],
  split: ['brief.md', 'decisions.md', 'contracts.md', 'context/'],
  review: ['@tickets', 'README.md'],
};
const DONE_STATUSES = new Set(['applied', 'deferred']);

// ---------------------------------------------------------------- utilities
const die = (msg, code = 2) => { console.error(msg); process.exit(code); };
const read = (f) => (fs.existsSync(f) ? fs.readFileSync(f, 'utf8') : null);
const sha = (s) => createHash('sha256').update(s).digest('hex').slice(0, 16);
const num = (id) => String(parseInt(id, 10));

function readState(dir) {
  const s = read(path.join(dir, 'state.json'));
  if (s === null) die(`${dir}: no state.json (run init first)`);
  return JSON.parse(s);
}
const writeState = (dir, state) =>
  fs.writeFileSync(path.join(dir, 'state.json'), JSON.stringify(state, null, 2) + '\n');

function listFiles(root, rel) {
  const abs = path.join(root, rel);
  if (!fs.existsSync(abs)) return [];
  if (fs.statSync(abs).isFile()) return [rel];
  return fs.readdirSync(abs).sort().flatMap((e) => listFiles(root, path.join(rel, e)));
}
const ticketFiles = (dir) => fs.readdirSync(dir).filter((f) => /^\d+-.+\.md$/.test(f)).sort();

function inputsOf(dir, state, phase) {
  const out = {};
  for (const item of INPUTS[phase]) {
    if (item === '@repos') out['@repos'] = sha(JSON.stringify({ repos: state.repos, design: state.design }));
    else if (item === '@tickets') for (const f of ticketFiles(dir)) out[f] = sha(read(path.join(dir, f)));
    else {
      const files = listFiles(dir, item);
      if (!files.length) out[item] = 'missing';
      for (const f of files) out[f] = sha(fs.readFileSync(path.join(dir, f)));
    }
  }
  return out;
}

function phaseStatus(dir, state) {
  const result = [];
  let upstreamOk = true;
  let prevAt = '';
  for (const phase of state.phases) {
    const stamp = state.stamps?.[phase];
    let status = 'pending';
    let changed = [];
    if (stamp) {
      const now = inputsOf(dir, state, phase);
      const keys = new Set([...Object.keys(now), ...Object.keys(stamp.inputs)]);
      changed = [...keys].filter((k) => now[k] !== stamp.inputs[k]);
      status = upstreamOk && !changed.length && stamp.at >= prevAt ? 'done' : 'stale';
      prevAt = stamp.at;
    }
    if (status !== 'done') upstreamOk = false;
    result.push({ phase, status, at: stamp?.at ?? null, changed });
  }
  return result;
}

function parseQuestions(dir) {
  const text = read(path.join(dir, 'questions.md')) ?? '';
  const qs = [];
  for (const line of text.split('\n')) {
    const m = line.match(/^## (Q\d+) · (open|answered|applied|deferred) · (blocker|gap) · ([a-z]+)\s*$/);
    if (m) qs.push({ id: m[1], status: m[2], severity: m[3], phase: m[4] });
    else if (/^## Q\d+/.test(line)) qs.push({ id: line.slice(3), malformed: true });
  }
  return qs;
}

// Unresolved questions raised by any of the given phases.
function unresolved(dir, phases) {
  const qs = parseQuestions(dir);
  const bad = qs.filter((q) => q.malformed).map((q) => `questions.md: malformed heading "## ${q.id}"`);
  for (const q of qs) {
    if (!q.malformed && phases.includes(q.phase) && !DONE_STATUSES.has(q.status))
      bad.push(`${q.id} (${q.phase}, ${q.severity}) is ${q.status}`);
  }
  return bad;
}

// -------------------------------------------------------------------- check
const splitRow = (l) => l.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((c) => c.trim());

function parseWaveTable(text) {
  const lines = text.split('\n');
  const hi = lines.findIndex((l) => /^\|\s*Wave\s*\|/i.test(l));
  if (hi < 0) return null;
  const cols = splitRow(lines[hi]).map((c) => c.toLowerCase());
  const rows = [];
  for (let i = hi + 2; i < lines.length && lines[i].trim().startsWith('|'); i++) {
    const cells = splitRow(lines[i]);
    const get = (name) => (cols.includes(name) ? cells[cols.indexOf(name)] ?? '' : null);
    rows.push({
      line: i + 1,
      wave: get('wave'),
      ticket: get('ticket'),
      repo: get('repo'),
      blockedBy: get('blocked by') ?? '',
      changes: get('changes') ?? '',
    });
  }
  return { hasRepo: cols.includes('repo'), rows };
}

const parseIds = (s) =>
  !s || /^[—–-]?$/.test(s.trim()) ? [] : s.split(/[,\s]+/).filter(Boolean);

// A path in Changes stands for everything under it when it ends in a wildcard
// or a slash; the part before the first wildcard is what can overlap.
function normPath(p) {
  let s = p.replace(/^\.\//, '');
  const wild = s.search(/[*{?[]/);
  if (wild >= 0) s = s.slice(0, wild);
  s = s.replace(/\/+$/, '');
  return s;
}
const overlaps = (a, b) => a === b || a.startsWith(b + '/') || b.startsWith(a + '/') || a === '' || b === '';

function definedIds(dir, errors) {
  const ids = new Map(); // id -> { out, file }
  const add = (id, rest, file) => {
    if (ids.has(id)) errors.push(`${id} is defined twice (${ids.get(id).file}, ${file})`);
    ids.set(id, { out: /\[out\]/i.test(rest), file });
  };
  for (const file of ['brief.md', 'context/ui-inventory.md']) {
    for (const line of (read(path.join(dir, file)) ?? '').split('\n')) {
      const m = line.match(/^\s*[-*]\s+\*\*([REU]\d+)\*\*(.*)$/);
      if (m) add(m[1], m[2], file);
    }
  }
  for (const line of (read(path.join(dir, 'contracts.md')) ?? '').split('\n')) {
    const m = line.match(/^#{2,4}\s+(C\d+)\b(.*)$/);
    if (m) add(m[1], m[2], 'contracts.md');
  }
  return ids;
}

function check(dir) {
  const errors = [];
  const warnings = [];
  const state = fs.existsSync(path.join(dir, 'state.json')) ? readState(dir) : null;
  const readme = read(path.join(dir, 'README.md'));
  if (readme === null) return { errors: ['README.md (the wave table) is missing'], warnings };
  const table = parseWaveTable(readme);
  if (!table) return { errors: ['README.md has no wave table (a "| Wave |" header row)'], warnings };

  const multiRepo = (state?.repos?.length ?? 0) > 1;
  if (multiRepo && !table.hasRepo) errors.push('the plan spans several repos, so the wave table needs a Repo column');
  const repoNames = new Set((state?.repos ?? []).map((r) => r.name));

  // Rows and their ticket files.
  const files = ticketFiles(dir);
  const tickets = new Map(); // num id -> ticket
  for (const row of table.rows) {
    const m = (row.ticket ?? '').match(/^(\d+)\b/);
    if (!m) { errors.push(`README.md:${row.line}: Ticket cell doesn't start with a number`); continue; }
    const id = num(m[1]);
    if (tickets.has(id)) { errors.push(`ticket ${m[1]} has two rows in the wave table`); continue; }
    const file = files.find((f) => num(f) === id);
    const t = {
      label: m[1], id, row, file,
      wave: /^\d+$/.test(row.wave) ? parseInt(row.wave, 10) : NaN,
      blockers: parseIds(row.blockedBy),
      changes: [...row.changes.matchAll(/`([^`]+)`/g)].map((x) => x[1]),
      text: file ? read(path.join(dir, file)) : '',
    };
    if (Number.isNaN(t.wave)) errors.push(`ticket ${t.label}: wave "${row.wave}" isn't a number`);
    if (!file) errors.push(`ticket ${t.label} is in the wave table but has no ${m[1]}-*.md file`);
    if (!t.changes.length) errors.push(`ticket ${t.label} lists no Changes in the wave table`);
    tickets.set(id, t);
  }
  for (const f of files) if (!tickets.has(num(f))) errors.push(`${f} has no row in the wave table`);

  // Per-ticket lines: first line, Repo, Covers.
  for (const t of tickets.values()) {
    if (!t.file) continue;
    const lines = t.text.split('\n');
    const first = lines[0].match(/^Wave (\d+)((?: · [^·.]+)*)\./);
    if (!first) errors.push(`${t.file}: first line must start "Wave N." or "Wave N · blocked by …."`);
    else {
      const seg = first[2].split(' · ').map((s) => s.trim()).find((s) => s.startsWith('blocked by'));
      const firstBlockers = parseIds(seg ? seg.slice('blocked by'.length) : '').map(num).sort().join(',');
      if (parseInt(first[1], 10) !== t.wave) errors.push(`${t.file}: first line says wave ${first[1]}, the table says ${t.row.wave}`);
      if (firstBlockers !== t.blockers.map(num).sort().join(','))
        errors.push(`${t.file}: blockers on the first line differ from the table (${t.row.blockedBy || '—'})`);
    }
    const repoLine = lines.slice(0, 12).map((l) => l.match(/^Repo:\s*(\S+)/)).find(Boolean);
    t.repo = table.hasRepo ? t.row.repo : repoLine?.[1] ?? '';
    if (table.hasRepo) {
      if (!repoLine) errors.push(`${t.file}: no "Repo:" line`);
      else if (repoLine[1] !== t.row.repo) errors.push(`${t.file}: Repo: ${repoLine[1]}, the table says ${t.row.repo}`);
      if (repoNames.size && !repoNames.has(t.row.repo)) errors.push(`ticket ${t.label}: repo "${t.row.repo}" isn't in state.json`);
    }
    const covers = lines.slice(0, 12).map((l) => l.match(/^Covers:\s*(.*)$/)).find(Boolean);
    t.covers = covers ? covers[1].match(/\b[RCEU]\d+\b/g) ?? [] : null;
  }

  // Blockers, cycles and waves.
  for (const t of tickets.values())
    for (const b of t.blockers)
      if (!tickets.has(num(b))) errors.push(`ticket ${t.label} is blocked by ${b}, which isn't in the plan`);
  const expected = new Map();
  const visiting = new Set();
  let cycle = false;
  const waveOf = (id) => {
    if (expected.has(id)) return expected.get(id);
    if (visiting.has(id)) { cycle = true; return 0; }
    visiting.add(id);
    const t = tickets.get(id);
    const bs = t.blockers.map(num).filter((b) => tickets.has(b));
    const w = bs.length ? Math.max(...bs.map(waveOf)) + 1 : 1;
    visiting.delete(id);
    expected.set(id, w);
    return w;
  };
  for (const id of tickets.keys()) waveOf(id);
  if (cycle) errors.push('the blocked-by links have a cycle');
  else {
    for (const t of tickets.values())
      if (!Number.isNaN(t.wave) && expected.get(t.id) !== t.wave)
        errors.push(`ticket ${t.label} is in wave ${t.wave}, but its blockers put it in wave ${expected.get(t.id)}`);
    const last = Math.max(...expected.values());
    for (const t of tickets.values())
      if (t.blockers.length > 1 && expected.get(t.id) < last)
        warnings.push(`ticket ${t.label} has ${t.blockers.length} blockers but sits in wave ${expected.get(t.id)} of ${last}: fan-in should be rare and late`);
  }

  // No overlap inside a wave, per repo.
  const all = [...tickets.values()];
  for (let i = 0; i < all.length; i++)
    for (let j = i + 1; j < all.length; j++) {
      const a = all[i], b = all[j];
      if (a.wave !== b.wave || (a.repo ?? '') !== (b.repo ?? '')) continue;
      for (const pa of a.changes)
        for (const pb of b.changes)
          if (overlaps(normPath(pa), normPath(pb)))
            errors.push(`wave ${a.wave}: tickets ${a.label} and ${b.label} overlap (${pa} / ${pb})`);
    }

  // Coverage: every brief, inventory and contract item is owned by a ticket.
  const ids = definedIds(dir, errors);
  if (ids.size) {
    const covered = new Set();
    for (const t of tickets.values()) {
      if (!t.file) continue;
      if (t.covers === null) { errors.push(`${t.file}: no "Covers:" line`); continue; }
      for (const id of t.covers) {
        covered.add(id);
        if (!ids.has(id)) errors.push(`ticket ${t.label} covers ${id}, which isn't defined`);
        else if (ids.get(id).out) errors.push(`ticket ${t.label} covers ${id}, which is marked [out]`);
      }
    }
    for (const [id, d] of ids) if (!d.out && !covered.has(id)) errors.push(`${id} (${d.file}) is covered by no ticket`);
  }
  return { errors, warnings };
}

// ----------------------------------------------------------------- commands
function cmdInit(dir, opts) {
  if (fs.existsSync(path.join(dir, 'state.json'))) die(`${dir} already has a plan; resume it instead`, 1);
  const size = opts.size?.[0];
  if (!PHASES_BY_SIZE[size]) die(`--size must be one of ${Object.keys(PHASES_BY_SIZE).join(', ')}`);
  if (!opts.slug?.[0]) die('--slug is required');
  const repos = (opts.repo ?? []).map((r) => {
    const [name, ...p] = r.split('=');
    if (!name || !p.length) die(`--repo ${r}: expected <name>=<path>`);
    return { name, path: path.resolve(p.join('=')) };
  });
  if (!repos.length) die('at least one --repo <name>=<path> is required');
  for (const d of ['input/mockups', 'context']) fs.mkdirSync(path.join(dir, d), { recursive: true });
  for (const [f, title] of [['questions.md', 'Questions'], ['decisions.md', 'Decisions']])
    if (!fs.existsSync(path.join(dir, f))) fs.writeFileSync(path.join(dir, f), `# ${title}\n`);
  writeState(dir, {
    slug: opts.slug[0], size, created: new Date().toISOString(), repos,
    design: opts.design?.[0] ?? 'none', phases: PHASES_BY_SIZE[size], stamps: {},
  });
  console.log(`plan created: ${path.resolve(dir)} (${PHASES_BY_SIZE[size].join(' → ')})`);
}

function nextStep(statuses) {
  const n = statuses.find((s) => s.status !== 'done');
  return n ? n.phase : 'publish';
}

function cmdStatus(dir, opts) {
  const state = readState(dir);
  const statuses = phaseStatus(dir, state);
  const qs = parseQuestions(dir).filter((q) => !q.malformed);
  const open = qs.filter((q) => !DONE_STATUSES.has(q.status));
  const next = nextStep(statuses);
  if (opts.json) {
    console.log(JSON.stringify({ slug: state.slug, size: state.size, phases: statuses, open, next }, null, 2));
    return;
  }
  console.log(`${state.slug} · ${state.size} · repos: ${state.repos.map((r) => r.name).join(', ')}`);
  for (const s of statuses) {
    const why = s.status === 'stale' && s.changed.length ? `  changed: ${s.changed.join(', ')}` : '';
    console.log(`  ${s.phase.padEnd(10)} ${s.status.padEnd(8)}${s.at ?? ''}${why}`);
  }
  console.log(`  questions: ${open.length} unresolved${open.length ? ' (' + open.map((q) => `${q.id} ${q.status}`).join(', ') + ')' : ''}`);
  console.log(`next: ${next}`);
}

function gateReasons(dir, state, step) {
  const statuses = phaseStatus(dir, state);
  const idx = step === 'publish' ? state.phases.length : state.phases.indexOf(step);
  if (idx < 0) die(`${step} isn't a phase of this plan (${state.phases.join(', ')})`);
  const before = state.phases.slice(0, idx);
  const reasons = statuses.filter((s) => before.includes(s.phase) && s.status !== 'done').map((s) => `${s.phase} is ${s.status}`);
  reasons.push(...unresolved(dir, step === 'publish' ? state.phases : before));
  if (step === 'publish') reasons.push(...check(dir).errors.map((e) => `check: ${e}`));
  return reasons;
}

function cmdGate(dir, step) {
  const reasons = gateReasons(dir, readState(dir), step);
  if (reasons.length) { console.log(`gate ${step}: closed`); reasons.forEach((r) => console.log(`  - ${r}`)); process.exit(1); }
  console.log(`gate ${step}: open`);
}

function cmdStamp(dir, phase) {
  const state = readState(dir);
  if (!state.phases.includes(phase)) die(`${phase} isn't a phase of this plan (${state.phases.join(', ')})`);
  const reasons = gateReasons(dir, state, phase);
  reasons.push(...unresolved(dir, [phase]));
  if (['split', 'review'].includes(phase)) reasons.push(...check(dir).errors.map((e) => `check: ${e}`));
  if (reasons.length) { console.log(`can't stamp ${phase}:`); reasons.forEach((r) => console.log(`  - ${r}`)); process.exit(1); }
  state.stamps = { ...state.stamps, [phase]: { at: new Date().toISOString(), inputs: inputsOf(dir, state, phase) } };
  writeState(dir, state);
  console.log(`stamped ${phase}`);
}

function cmdResize(dir, size) {
  const state = readState(dir);
  if (!PHASES_BY_SIZE[size]) die(`size must be one of ${Object.keys(PHASES_BY_SIZE).join(', ')}`);
  state.size = size;
  state.phases = PHASES_BY_SIZE[size];
  writeState(dir, state);
  console.log(`${state.slug} is now a ${size}: ${state.phases.join(' → ')}`);
}

function cmdCheck(dir) {
  const { errors, warnings } = check(dir);
  errors.forEach((e) => console.log(`error: ${e}`));
  warnings.forEach((w) => console.log(`warn:  ${w}`));
  console.log(errors.length ? `check failed: ${errors.length} error(s)` : 'check passed');
  if (errors.length) process.exit(1);
}

// --------------------------------------------------------------------- main
const [cmd, dir, ...rest] = process.argv.slice(2);
if (!cmd || !dir) die('usage: plan.mjs <init|status|gate|stamp|check|resize> <plan dir> ...');
const opts = {};
const positional = [];
for (let i = 0; i < rest.length; i++) {
  if (rest[i] === '--json') opts.json = true;
  else if (rest[i].startsWith('--')) (opts[rest[i].slice(2)] ??= []).push(rest[++i]);
  else positional.push(rest[i]);
}
if (cmd !== 'init' && !fs.existsSync(dir)) die(`${dir} doesn't exist`);
switch (cmd) {
  case 'init': cmdInit(dir, opts); break;
  case 'status': cmdStatus(dir, opts); break;
  case 'gate': cmdGate(dir, positional[0] ?? die('gate needs a phase or "publish"')); break;
  case 'stamp': cmdStamp(dir, positional[0] ?? die('stamp needs a phase')); break;
  case 'check': cmdCheck(dir); break;
  case 'resize': cmdResize(dir, positional[0] ?? die('resize needs a size')); break;
  default: die(`unknown command ${cmd}`);
}
