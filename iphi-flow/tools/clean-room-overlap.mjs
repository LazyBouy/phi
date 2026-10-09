// clean-room-overlap.mjs — token-shingle overlap scan between changed Activepieces files
// and the n8n frontend source. Builds a set of normalised 30-token shingles from the AP files
// (small set), then streams the n8n corpus and reports every shared shingle with both locations.
// Usage: node clean-room-overlap.mjs <ap-file-list.txt> <n8n-root> [shingle=30] [baseline-file-list.txt]
// Shingles that already exist in the baseline files (the same AP files at the base commit) are
// excluded, so only overlap introduced by the change under audit is reported.
import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join, extname } from 'node:path'
import { createHash } from 'node:crypto'

const [listPath, n8nRoot, sizeArg, baselinePath] = process.argv.slice(2)
const SIZE = Number(sizeArg ?? 30)
const AP_EXT = new Set(['.ts', '.tsx', '.js', '.jsx', '.mjs', '.css', '.scss', '.json', '.md', '.html', '.svg', '.vue'])
const N8N_EXT = new Set(['.ts', '.js', '.vue', '.css', '.scss', '.json', '.svg', '.html', '.md'])
const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', 'coverage', '__snapshots__'])

function stripComments(text) {
  return text.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/(^|[^:'"`\\])\/\/[^\n]*/g, '$1').replace(/<!--[\s\S]*?-->/g, ' ')
}

function tokens(text) {
  return stripComments(text).match(/[A-Za-z_$][\w$-]*|\d+(?:\.\d+)?|[^\s\w]/g) ?? []
}

function shingles(toks) {
  const out = []
  for (let i = 0; i + SIZE <= toks.length; i++) {
    const key = createHash('sha1').update(toks.slice(i, i + SIZE).join('\u0001')).digest('base64')
    out.push({ key, at: i })
  }
  return out
}

const readList = (path) => readFileSync(path, 'utf8').split('\n').map(s => s.trim()).filter(f => f && AP_EXT.has(extname(f)))
const baseline = new Set()
if (baselinePath) {
  for (const file of readList(baselinePath)) {
    let text
    try { text = readFileSync(file, 'utf8') } catch { continue }
    for (const { key } of shingles(tokens(text))) baseline.add(key)
  }
}
const apFiles = readList(listPath)
const apIndex = new Map()
for (const file of apFiles) {
  let text
  try { text = readFileSync(file, 'utf8') } catch { continue }
  const toks = tokens(text)
  for (const { key, at } of shingles(toks)) {
    if (baseline.has(key)) continue
    if (!apIndex.has(key)) apIndex.set(key, { file, sample: toks.slice(at, at + SIZE).join(' ') })
  }
}

function* walk(dir) {
  let entries
  try { entries = readdirSync(dir) } catch { return }
  for (const name of entries) {
    if (SKIP_DIRS.has(name)) continue
    const full = join(dir, name)
    let st
    try { st = statSync(full) } catch { continue }
    if (st.isDirectory()) yield* walk(full)
    else if (N8N_EXT.has(extname(name)) && st.size < 2_000_000) yield full
  }
}

const hits = new Map()
let scanned = 0
for (const file of walk(n8nRoot)) {
  scanned++
  const toks = tokens(readFileSync(file, 'utf8'))
  for (const { key } of shingles(toks)) {
    const ap = apIndex.get(key)
    if (!ap) continue
    const id = `${ap.file} <-> ${file}`
    if (!hits.has(id)) hits.set(id, { count: 0, sample: ap.sample })
    hits.get(id).count++
  }
}

console.log(`ap files: ${apFiles.length}, new ap shingles: ${apIndex.size}, baseline shingles excluded: ${baseline.size}, n8n files scanned: ${scanned}, shingle size: ${SIZE}`)
if (hits.size === 0) {
  console.log('overlap: none')
  process.exit(0)
}
for (const [id, { count, sample }] of hits) {
  console.log(`OVERLAP ${count} shingle(s): ${id}`)
  console.log(`  sample: ${sample.slice(0, 200)}`)
}
process.exit(1)
