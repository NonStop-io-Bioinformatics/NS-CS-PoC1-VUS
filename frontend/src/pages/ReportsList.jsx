import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api'
import { resultClass, fmtDate } from '../lib'

export default function ReportsList() {
  const [stats, setStats] = useState(null)
  const [reports, setReports] = useState(null)
  const [err, setErr] = useState(null)

  useEffect(() => {
    Promise.all([api.stats(), api.reports()])
      .then(([s, r]) => { setStats(s); setReports(r) })
      .catch((e) => setErr(e.message))
  }, [])

  if (err) return <div className="error">Failed to load: {err}</div>
  if (!reports) return <div className="loading">Loading reports…</div>

  return (
    <>
      <h1 className="page-title">Patient Reports</h1>

      {stats && (
        <div className="tiles">
          <Tile label="Reports" value={stats.total_reports} />
          <Tile label="Positive" value={stats.by_result?.Positive || 0} tone="red" />
          <Tile label="Uncertain" value={stats.by_result?.Uncertain || 0} tone="amber" />
          <Tile label="Negative" value={stats.by_result?.Negative || 0} tone="green" />
          <Tile label="Reported variants" value={stats.reported_variants} />
        </div>
      )}

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th>Report</th><th>Patient</th><th>MRN</th><th>Panel</th>
              <th>Result</th><th className="num">Variants</th><th>Ver</th><th>Reported</th>
            </tr>
          </thead>
          <tbody>
            {reports.map((r) => (
              <tr key={r.report_id}>
                <td><Link className="link mono" to={`/reports/${r.report_id}`}>{r.report_id}</Link></td>
                <td>{r.patient_name}</td>
                <td className="mono">{r.patient_mrn}</td>
                <td>{r.panel_name}</td>
                <td><span className={`badge ${resultClass(r.overall_result)}`}>{r.overall_result}</span></td>
                <td className="num">{r.variant_count}</td>
                <td className="mono">v{r.version}</td>
                <td className="mono">{fmtDate(r.reported_date)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}

function Tile({ label, value, tone }) {
  return (
    <div className={`tile ${tone ? 'tile-' + tone : ''}`}>
      <div className="tile-value">{value}</div>
      <div className="tile-label">{label}</div>
    </div>
  )
}
