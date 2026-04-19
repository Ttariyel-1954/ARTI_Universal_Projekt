-- ═══════════════════════════════════════════════════════════════
-- 04: Reporting View-lar (15+)
-- Dashboard və AI analizi üçün
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- 1. v_kpi_dashboard — Əsas KPI
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_kpi_dashboard AS
SELECT
  (SELECT COUNT(*) FROM geo.regions WHERE is_active)           AS total_regions,
  (SELECT COUNT(*) FROM infra.schools WHERE is_active)         AS total_schools,
  (SELECT COUNT(*) FROM construction.projects)                 AS total_projects,
  (SELECT COUNT(*) FROM construction.projects 
   WHERE status = 'in_progress')                               AS active_projects,
  (SELECT COUNT(*) FROM construction.projects 
   WHERE status = 'completed')                                 AS completed_projects,
  (SELECT ROUND(SUM(planned_budget)/1000000, 1) 
   FROM construction.projects)                                 AS total_planned_mln,
  (SELECT ROUND(SUM(actual_cost)/1000000, 1) 
   FROM construction.projects)                                 AS total_spent_mln,
  (SELECT ROUND(AVG(progress_percent), 1) 
   FROM construction.projects WHERE status = 'in_progress')    AS avg_progress,
  (SELECT COUNT(*) FROM hr.employees WHERE is_active)          AS total_employees,
  (SELECT COUNT(*) FROM hr.contractors WHERE NOT is_blacklisted) AS total_contractors,
  (SELECT COUNT(*) FROM construction.citizen_complaints 
   WHERE status IN ('new','investigating'))                    AS pending_complaints,
  (SELECT ROUND(AVG(quality_score), 1) 
   FROM construction.inspections)                              AS avg_quality;

-- ═══════════════════════════════════════════════════════════════
-- 2. v_regional_overview — Rayon üzrə
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_regional_overview AS
SELECT
  r.id                                        AS region_id,
  r.code,
  r.name_az                                   AS region_name,
  r.population,
  r.center_lat                                AS lat,
  r.center_lng                                AS lng,
  COUNT(DISTINCT s.id)                        AS school_count,
  COUNT(DISTINCT p.id)                        AS project_count,
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'in_progress')  AS active_projects,
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'completed')    AS completed_projects,
  COALESCE(ROUND(SUM(p.planned_budget)/1000000, 2), 0)          AS planned_mln,
  COALESCE(ROUND(SUM(p.actual_cost)/1000000, 2), 0)             AS spent_mln,
  COALESCE(ROUND(AVG(p.progress_percent)), 0)                   AS avg_progress
FROM geo.regions r
LEFT JOIN infra.schools s ON s.region_id = r.id
LEFT JOIN construction.projects p ON p.region_id = r.id
GROUP BY r.id, r.code, r.name_az, r.population, r.center_lat, r.center_lng;

-- ═══════════════════════════════════════════════════════════════
-- 3. v_project_status — Layihə statusları tam mənzərə
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_project_status AS
SELECT
  p.id                                AS project_id,
  p.project_code,
  p.name                              AS project_name,
  pt.name_az                          AS project_type,
  pt.icon,
  r.name_az                           AS region_name,
  s.name                              AS school_name,
  c.name                              AS contractor_name,
  e.full_name                         AS manager_name,
  p.status,
  p.priority,
  p.progress_percent,
  p.start_date,
  p.end_date,
  p.actual_start,
  p.actual_end,
  p.planned_budget,
  p.actual_cost,
  ROUND(p.actual_cost - p.planned_budget, 2)  AS cost_variance,
  CASE 
    WHEN p.planned_budget > 0 
    THEN ROUND(100.0 * (p.actual_cost - p.planned_budget) / p.planned_budget, 1)
    ELSE 0
  END                                 AS cost_variance_pct,
  CASE
    WHEN p.status = 'completed' AND p.actual_end > p.end_date THEN 'Gecikmə ilə bitib'
    WHEN p.status = 'completed' AND p.actual_end <= p.end_date THEN 'Vaxtında bitib'
    WHEN p.status = 'in_progress' AND CURRENT_DATE > p.end_date THEN 'Gecikir'
    WHEN p.status = 'in_progress' THEN 'Planda davam edir'
    WHEN p.status = 'planned' THEN 'Planlaşdırılıb'
    WHEN p.status = 'approved' THEN 'Təsdiqlənib'
    WHEN p.status = 'on_hold' THEN 'Dayandırılıb'
    ELSE 'Ləğv edilib'
  END                                 AS status_label
FROM construction.projects p
LEFT JOIN construction.project_types pt ON p.type_id = pt.id
LEFT JOIN geo.regions r ON p.region_id = r.id
LEFT JOIN infra.schools s ON p.school_id = s.id
LEFT JOIN hr.contractors c ON p.contractor_id = c.id
LEFT JOIN hr.employees e ON p.manager_id = e.id;

-- ═══════════════════════════════════════════════════════════════
-- 4. v_budget_tracking — Büdcə izləmə
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_budget_tracking AS
SELECT
  b.fiscal_year,
  COALESCE(r.name_az, 'Ümumi')          AS region,
  b.category,
  b.source,
  b.allocated_amount,
  b.spent_amount,
  ROUND(b.allocated_amount - b.spent_amount, 2)  AS remaining,
  CASE 
    WHEN b.allocated_amount > 0 
    THEN ROUND(100.0 * b.spent_amount / b.allocated_amount, 1)
    ELSE 0
  END                                    AS execution_pct,
  CASE
    WHEN b.allocated_amount = 0 THEN 'Boş'
    WHEN b.spent_amount / b.allocated_amount < 0.25 THEN 'Aşağı icra'
    WHEN b.spent_amount / b.allocated_amount < 0.75 THEN 'Orta icra'
    WHEN b.spent_amount / b.allocated_amount < 0.95 THEN 'Yaxşı icra'
    ELSE 'Tam icra'
  END                                    AS execution_level
FROM finance.budgets b
LEFT JOIN geo.regions r ON b.region_id = r.id;

-- ═══════════════════════════════════════════════════════════════
-- 5. v_contractor_performance — Podratçı performansı
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_contractor_performance AS
SELECT
  c.id                                    AS contractor_id,
  c.name                                  AS contractor_name,
  c.tin,
  c.category,
  c.rating,
  c.is_blacklisted,
  COUNT(DISTINCT p.id)                    AS total_projects,
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'completed') AS completed,
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'in_progress') AS active,
  COALESCE(ROUND(SUM(p.actual_cost)/1000, 0), 0) AS total_revenue_k,
  COALESCE(ROUND(AVG(ins.quality_score), 1), 0)  AS avg_quality,
  COUNT(DISTINCT ins.id)                  AS inspection_count,
  COUNT(DISTINCT comp.id)                 AS complaint_count
FROM hr.contractors c
LEFT JOIN construction.projects p ON p.contractor_id = c.id
LEFT JOIN construction.inspections ins ON ins.project_id = p.id
LEFT JOIN construction.citizen_complaints comp ON comp.project_id = p.id
GROUP BY c.id, c.name, c.tin, c.category, c.rating, c.is_blacklisted;

-- ═══════════════════════════════════════════════════════════════
-- 6. v_material_flow — Material hərəkəti
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_material_flow AS
SELECT
  m.id                                  AS material_id,
  m.code,
  m.name_az                             AS material_name,
  mc.name_az                            AS category,
  mc.icon,
  m.unit,
  m.standard_price,
  COALESCE(SUM(st.quantity), 0)         AS total_stock,
  COUNT(DISTINCT st.warehouse_id)       AS warehouses_with_stock,
  COALESCE(SUM(mt.quantity) FILTER (WHERE mt.transaction_type = 'in'), 0)  AS total_in,
  COALESCE(SUM(mt.quantity) FILTER (WHERE mt.transaction_type = 'out'), 0) AS total_out,
  COALESCE(SUM(mt.total_amount) FILTER (WHERE mt.transaction_type = 'out'), 0) AS total_out_value,
  m.min_stock_level,
  CASE 
    WHEN COALESCE(SUM(st.quantity), 0) < m.min_stock_level THEN '⚠️ Az'
    WHEN COALESCE(SUM(st.quantity), 0) < m.min_stock_level * 2 THEN '🟡 Orta'
    ELSE '✅ Yaxşı'
  END                                   AS stock_status
FROM inventory.materials m
LEFT JOIN inventory.material_categories mc ON m.category_id = mc.id
LEFT JOIN inventory.stock_levels st ON st.material_id = m.id
LEFT JOIN inventory.material_transactions mt ON mt.material_id = m.id
GROUP BY m.id, m.code, m.name_az, mc.name_az, mc.icon, m.unit, m.standard_price, m.min_stock_level;

-- ═══════════════════════════════════════════════════════════════
-- 7. v_deadline_monitoring — Deadline izləmə
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_deadline_monitoring AS
SELECT
  p.id                                  AS project_id,
  p.project_code,
  p.name                                AS project_name,
  r.name_az                             AS region,
  p.status,
  p.progress_percent,
  p.end_date                            AS planned_end,
  p.actual_end,
  CURRENT_DATE - p.end_date             AS days_overdue,
  p.end_date - CURRENT_DATE             AS days_remaining,
  CASE
    WHEN p.status = 'completed' AND p.actual_end > p.end_date THEN 'Gecikmişdi'
    WHEN p.status = 'completed' THEN 'Vaxtında'
    WHEN p.status IN ('planned','approved') THEN 'Başlamayıb'
    WHEN CURRENT_DATE > p.end_date THEN 'GECİKİR!'
    WHEN p.end_date - CURRENT_DATE <= 30 THEN 'Deadline yaxın'
    ELSE 'Normal'
  END                                   AS deadline_status,
  p.planned_budget,
  p.actual_cost
FROM construction.projects p
LEFT JOIN geo.regions r ON p.region_id = r.id;

-- ═══════════════════════════════════════════════════════════════
-- 8. v_inspection_summary — Yoxlama yekunu
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_inspection_summary AS
SELECT
  ins.id                                AS inspection_id,
  ins.inspection_date,
  ins.inspection_type,
  p.project_code,
  p.name                                AS project_name,
  r.name_az                             AS region,
  e.full_name                           AS inspector_name,
  ins.quality_score,
  ins.issues_found,
  ins.issues_resolved,
  ins.issues_found - ins.issues_resolved  AS unresolved,
  ins.requires_followup,
  CASE 
    WHEN ins.quality_score >= 9 THEN '⭐ Əla'
    WHEN ins.quality_score >= 7 THEN '✅ Yaxşı'
    WHEN ins.quality_score >= 5 THEN '🟡 Orta'
    ELSE '❌ Pis'
  END                                   AS quality_label
FROM construction.inspections ins
LEFT JOIN construction.projects p ON ins.project_id = p.id
LEFT JOIN geo.regions r ON p.region_id = r.id
LEFT JOIN hr.employees e ON ins.inspector_id = e.id;

-- ═══════════════════════════════════════════════════════════════
-- 9. v_complaint_analysis — Şikayət analizi
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_complaint_analysis AS
SELECT
  cc.id                                 AS complaint_id,
  cc.complaint_date,
  cc.channel,
  cc.category,
  cc.urgency,
  cc.status,
  cc.resolution_days,
  r.name_az                             AS region,
  s.name                                AS school_name,
  p.project_code,
  LEFT(cc.text, 80)                     AS complaint_preview,
  CASE 
    WHEN cc.status = 'resolved' AND cc.resolution_days <= 7  THEN '⭐ Sürətli'
    WHEN cc.status = 'resolved' AND cc.resolution_days <= 30 THEN '✅ Normal'
    WHEN cc.status = 'resolved'                              THEN '🟡 Yavaş'
    WHEN cc.status = 'investigating' THEN '🔍 İnceleme'
    WHEN cc.status = 'new'           THEN '🆕 Yeni'
    ELSE '📁 Bağlı'
  END                                   AS resolution_label
FROM construction.citizen_complaints cc
LEFT JOIN infra.schools s ON cc.school_id = s.id
LEFT JOIN geo.regions r ON s.region_id = r.id
LEFT JOIN construction.projects p ON cc.project_id = p.id;

-- ═══════════════════════════════════════════════════════════════
-- 10. v_monthly_spending — Aylıq xərc dinamikası
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_monthly_spending AS
SELECT
  EXTRACT(YEAR FROM expense_date)::INT    AS year,
  EXTRACT(MONTH FROM expense_date)::INT   AS month,
  TO_CHAR(expense_date, 'YYYY-MM')        AS year_month,
  category,
  COUNT(*)                                AS transaction_count,
  ROUND(SUM(amount), 2)                   AS total_amount,
  ROUND(AVG(amount), 2)                   AS avg_amount
FROM finance.expenses
GROUP BY EXTRACT(YEAR FROM expense_date), EXTRACT(MONTH FROM expense_date), 
         TO_CHAR(expense_date, 'YYYY-MM'), category
ORDER BY year, month, category;

-- ═══════════════════════════════════════════════════════════════
-- 11. v_top_projects_by_budget — Ən böyük layihələr
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_top_projects_by_budget AS
SELECT
  p.id                          AS project_id,
  p.project_code,
  p.name,
  pt.name_az                    AS type_name,
  pt.icon,
  r.name_az                     AS region,
  s.name                        AS school_name,
  p.status,
  p.progress_percent,
  p.planned_budget,
  p.actual_cost,
  ROUND(p.planned_budget / 1000, 0) AS budget_k_azn,
  ROW_NUMBER() OVER (ORDER BY p.planned_budget DESC) AS rank
FROM construction.projects p
LEFT JOIN construction.project_types pt ON p.type_id = pt.id
LEFT JOIN geo.regions r ON p.region_id = r.id
LEFT JOIN infra.schools s ON p.school_id = s.id
ORDER BY p.planned_budget DESC;

-- ═══════════════════════════════════════════════════════════════
-- 12. v_employee_workload — İşçi iş yükü
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_employee_workload AS
SELECT
  e.id                              AS employee_id,
  e.full_name,
  pos.name_az                       AS position_name,
  d.name_az                         AS department_name,
  r.name_az                         AS region,
  e.monthly_salary,
  COUNT(DISTINCT p.id)              AS managed_projects,
  COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'in_progress') AS active_projects,
  COUNT(DISTINCT ins.id)            AS inspections_done,
  COUNT(DISTINCT exp.id)            AS expenses_approved
FROM hr.employees e
LEFT JOIN hr.positions pos ON e.position_id = pos.id
LEFT JOIN hr.departments d ON e.department_id = d.id
LEFT JOIN geo.regions r ON e.region_id = r.id
LEFT JOIN construction.projects p ON p.manager_id = e.id
LEFT JOIN construction.inspections ins ON ins.inspector_id = e.id
LEFT JOIN finance.expenses exp ON exp.approved_by = e.id
WHERE e.is_active = TRUE
GROUP BY e.id, e.full_name, pos.name_az, d.name_az, r.name_az, e.monthly_salary;

-- ═══════════════════════════════════════════════════════════════
-- 13. v_school_repair_history — Məktəb təmir tarixçəsi
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_school_repair_history AS
SELECT
  s.id                              AS school_id,
  s.code,
  s.name                            AS school_name,
  r.name_az                         AS region,
  s.condition,
  s.built_year,
  s.student_count,
  s.last_major_repair,
  COUNT(p.id)                       AS total_projects,
  COUNT(p.id) FILTER (WHERE p.status = 'completed') AS completed_projects,
  COALESCE(ROUND(SUM(p.planned_budget)/1000, 0), 0) AS total_budget_k,
  COALESCE(ROUND(SUM(p.actual_cost)/1000, 0), 0)    AS total_spent_k,
  MAX(p.actual_end)                 AS last_project_end
FROM infra.schools s
LEFT JOIN geo.regions r ON s.region_id = r.id
LEFT JOIN construction.projects p ON p.school_id = s.id
GROUP BY s.id, s.code, s.name, r.name_az, s.condition, s.built_year, 
         s.student_count, s.last_major_repair;

-- ═══════════════════════════════════════════════════════════════
-- 14. v_warehouse_summary — Anbar yekunu
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_warehouse_summary AS
SELECT
  w.id                              AS warehouse_id,
  w.code,
  w.name                            AS warehouse_name,
  r.name_az                         AS region,
  w.area_m2,
  w.is_central,
  e.full_name                       AS manager_name,
  COUNT(DISTINCT sl.material_id)    AS materials_stocked,
  ROUND(SUM(sl.quantity), 2)        AS total_quantity,
  ROUND(SUM(sl.quantity * m.standard_price), 2) AS total_value
FROM inventory.warehouses w
LEFT JOIN geo.regions r ON w.region_id = r.id
LEFT JOIN hr.employees e ON w.manager_id = e.id
LEFT JOIN inventory.stock_levels sl ON sl.warehouse_id = w.id
LEFT JOIN inventory.materials m ON sl.material_id = m.id
GROUP BY w.id, w.code, w.name, r.name_az, w.area_m2, w.is_central, e.full_name;

-- ═══════════════════════════════════════════════════════════════
-- 15. v_yearly_summary — İllik statistika (trend analizi üçün)
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW reporting.v_yearly_summary AS
SELECT
  EXTRACT(YEAR FROM p.start_date)::INT    AS year,
  COUNT(*)                                AS projects_started,
  COUNT(*) FILTER (WHERE p.status = 'completed') AS projects_completed,
  ROUND(SUM(p.planned_budget)/1000000, 2) AS total_planned_mln,
  ROUND(SUM(p.actual_cost)/1000000, 2)    AS total_spent_mln,
  ROUND(AVG(p.progress_percent))          AS avg_progress,
  COUNT(DISTINCT p.region_id)             AS regions_involved,
  COUNT(DISTINCT p.contractor_id)         AS contractors_involved
FROM construction.projects p
WHERE p.start_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM p.start_date)
ORDER BY year;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ YARADILAN VIEW-LAR ═══'
SELECT viewname FROM pg_views WHERE schemaname = 'reporting' ORDER BY viewname;

\echo ''
\echo '═══ KPI DASHBOARD ═══'
SELECT * FROM reporting.v_kpi_dashboard;

\echo ''
\echo '═══ TOP 5 RAYON ═══'
SELECT region_name, school_count, project_count, planned_mln
FROM reporting.v_regional_overview
WHERE project_count > 0
ORDER BY project_count DESC
LIMIT 5;

\echo ''
\echo '═══ TOP 3 PODRATÇI ═══'
SELECT contractor_name, total_projects, avg_quality
FROM reporting.v_contractor_performance
WHERE total_projects > 0
ORDER BY total_projects DESC
LIMIT 3;

\echo ''
\echo '═══ ƏN BÖYÜK 3 LAYİHƏ ═══'
SELECT project_code, LEFT(name, 50) AS project, budget_k_azn, status
FROM reporting.v_top_projects_by_budget
LIMIT 3;

\echo ''
\echo '═══ YEKUN ═══'
SELECT 'View-lar sayı: ' || COUNT(*) FROM pg_views WHERE schemaname = 'reporting';
