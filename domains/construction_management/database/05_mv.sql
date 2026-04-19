-- ═══════════════════════════════════════════════════════════════
-- 05: Materialized View-lar (12 ədəd)
-- App.R dashboard üçün sürətli data
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. mv_kpi — Əsas KPI (hər dəfə lazımdır!) ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_kpi CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_kpi AS
SELECT * FROM reporting.v_kpi_dashboard;

-- ─── 2. mv_regional_overview — Rayon (xəritə üçün) ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_regional_overview CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_regional_overview AS
SELECT * FROM reporting.v_regional_overview;
CREATE INDEX ON reporting.mv_regional_overview(region_id);

-- ─── 3. mv_project_status — Layihələr (ən çox istifadə) ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_project_status CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_project_status AS
SELECT * FROM reporting.v_project_status;
CREATE INDEX ON reporting.mv_project_status(project_id);
CREATE INDEX ON reporting.mv_project_status(status);

-- ─── 4. mv_budget_tracking ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_budget_tracking CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_budget_tracking AS
SELECT * FROM reporting.v_budget_tracking;

-- ─── 5. mv_contractor_performance ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_contractor_performance CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_contractor_performance AS
SELECT * FROM reporting.v_contractor_performance;
CREATE INDEX ON reporting.mv_contractor_performance(contractor_id);

-- ─── 6. mv_material_flow (əsas analitik) ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_material_flow CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_material_flow AS
SELECT * FROM reporting.v_material_flow;
CREATE INDEX ON reporting.mv_material_flow(material_id);

-- ─── 7. mv_deadline_monitoring ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_deadline_monitoring CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_deadline_monitoring AS
SELECT * FROM reporting.v_deadline_monitoring;

-- ─── 8. mv_inspection_summary ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_inspection_summary CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_inspection_summary AS
SELECT * FROM reporting.v_inspection_summary;

-- ─── 9. mv_complaint_analysis ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_complaint_analysis CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_complaint_analysis AS
SELECT * FROM reporting.v_complaint_analysis;

-- ─── 10. mv_monthly_spending ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_monthly_spending CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_monthly_spending AS
SELECT * FROM reporting.v_monthly_spending;

-- ─── 11. mv_top_projects ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_top_projects CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_top_projects AS
SELECT * FROM reporting.v_top_projects_by_budget;

-- ─── 12. mv_yearly_summary ───
DROP MATERIALIZED VIEW IF EXISTS reporting.mv_yearly_summary CASCADE;
CREATE MATERIALIZED VIEW reporting.mv_yearly_summary AS
SELECT * FROM reporting.v_yearly_summary;

-- ─── REFRESH FUNKSIYA ───
CREATE OR REPLACE FUNCTION reporting.refresh_all_mv()
RETURNS TEXT AS $$
BEGIN
  REFRESH MATERIALIZED VIEW reporting.mv_kpi;
  REFRESH MATERIALIZED VIEW reporting.mv_regional_overview;
  REFRESH MATERIALIZED VIEW reporting.mv_project_status;
  REFRESH MATERIALIZED VIEW reporting.mv_budget_tracking;
  REFRESH MATERIALIZED VIEW reporting.mv_contractor_performance;
  REFRESH MATERIALIZED VIEW reporting.mv_material_flow;
  REFRESH MATERIALIZED VIEW reporting.mv_deadline_monitoring;
  REFRESH MATERIALIZED VIEW reporting.mv_inspection_summary;
  REFRESH MATERIALIZED VIEW reporting.mv_complaint_analysis;
  REFRESH MATERIALIZED VIEW reporting.mv_monthly_spending;
  REFRESH MATERIALIZED VIEW reporting.mv_top_projects;
  REFRESH MATERIALIZED VIEW reporting.mv_yearly_summary;
  RETURN '✅ 12 materialized view yeniləndi';
END;
$$ LANGUAGE plpgsql;

-- ─── ANALYZE (optimizasiya) ───
ANALYZE geo.regions;
ANALYZE infra.schools;
ANALYZE construction.projects;
ANALYZE finance.expenses;
ANALYZE inventory.material_transactions;
ANALYZE construction.inspections;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ MATERIALIZED VIEW-LAR ═══'
SELECT 
  matviewname AS view_name,
  pg_size_pretty(pg_relation_size(('reporting.' || matviewname)::regclass)) AS size
FROM pg_matviews 
WHERE schemaname = 'reporting'
ORDER BY matviewname;

\echo ''
\echo '═══ SÜRƏT TESTİ ═══'
\timing on
SELECT * FROM reporting.mv_kpi;
SELECT COUNT(*) FROM reporting.mv_project_status;
SELECT COUNT(*) FROM reporting.mv_regional_overview;
\timing off

\echo ''
\echo '═══ KPI ═══'
SELECT 
  total_regions,
  total_schools,
  total_projects,
  active_projects,
  completed_projects,
  total_planned_mln,
  total_spent_mln,
  pending_complaints,
  avg_quality
FROM reporting.mv_kpi;
