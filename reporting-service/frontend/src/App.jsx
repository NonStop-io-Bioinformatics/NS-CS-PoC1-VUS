import { Routes, Route, Link } from 'react-router-dom'
import ReportsList from './pages/ReportsList'
import ReportDetail from './pages/ReportDetail'

export default function App() {
  return (
    <div className="app">
      <header className="topbar">
        <Link to="/" className="brand">
          <span className="logo">🧬</span> Genomic Report Viewer
        </Link>
        <span className="env">NonStop · Claude Science PoC</span>
      </header>
      <main className="content">
        <Routes>
          <Route path="/" element={<ReportsList />} />
          <Route path="/reports/:reportId" element={<ReportDetail />} />
        </Routes>
      </main>
    </div>
  )
}
