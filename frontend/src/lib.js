// Presentation helpers shared across pages.

export function resultClass(result) {
  return {
    Positive: 'badge-red',
    Negative: 'badge-green',
    Uncertain: 'badge-amber',
  }[result] || 'badge-gray'
}

export function classificationClass(c) {
  return {
    Pathogenic: 'badge-red',
    'Likely pathogenic': 'badge-orange',
    VUS: 'badge-gray',
    'Likely benign': 'badge-teal',
    Benign: 'badge-green',
  }[c] || 'badge-gray'
}

export function fmtDate(d) {
  return d ? String(d).slice(0, 10) : '—'
}

export function fmtAF(af) {
  if (af === null || af === undefined) return '—'
  const n = Number(af)
  if (Number.isNaN(n)) return String(af)
  if (n === 0) return '0 (absent)'
  return n.toExponential(2)
}
