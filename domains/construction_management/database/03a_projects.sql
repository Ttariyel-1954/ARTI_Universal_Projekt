-- ═══════════════════════════════════════════════════════════════
-- 03a: LAYİHƏLƏR — 120 real tikinti-təmir layihəsi
-- 2023-2026 dövrü, 77 rayon üzrə paylanma
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. LAYİHƏ NÖVLƏRI (5) ───
INSERT INTO construction.project_types (code, name_az, typical_duration_days, requires_inspection, icon) VALUES
('CURRENT_REPAIR',   'Cari təmir',                        60,   TRUE, '🔧'),
('CAPITAL_REPAIR',   'Kapital təmir',                    240,  TRUE, '🏗️'),
('NEW_CONSTRUCTION', 'Yeni tikinti',                      540, TRUE, '🏛️'),
('RECONSTRUCTION',   'Yenidənqurma',                      365, TRUE, '🏠'),
('EMERGENCY_REPAIR', 'Təcili təmir',                      30,  TRUE, '🚨');

-- ─── 2. 120 LAYİHƏ ───
DO $$
DECLARE
  -- Məktəb-rayon massivi
  school_list CURSOR FOR 
    SELECT s.id AS school_id, s.region_id, s.name AS school_name, 
           s.condition, s.built_year, s.total_area_m2
    FROM infra.schools s
    ORDER BY RANDOM();
  
  -- Podratçılar
  contractor_ids INT[];
  manager_ids INT[];
  
  -- Layihə dəyişənləri
  proj_counter INT := 0;
  school_rec RECORD;
  type_id_v INT;
  type_code TEXT;
  priority_v SMALLINT;
  status_v TEXT;
  start_date_v DATE;
  end_date_v DATE;
  actual_start_v DATE;
  actual_end_v DATE;
  budget_v NUMERIC;
  actual_cost_v NUMERIC;
  progress_v SMALLINT;
  contractor_v INT;
  manager_v INT;
  building_id_v INT;
  year_v INT;
  project_name TEXT;
  
  -- Layihə adı şablonları
  repair_templates TEXT[] := ARRAY[
    'dam örtüyünün təmiri',
    'fasad təmiri və rəngləmə',
    'daxili təmir işləri',
    'elektrik sistemi yenilənməsi',
    'santexnika sisteminin dəyişdirilməsi',
    'istilik sistemi quraşdırılması',
    'pəncərələrin dəyişdirilməsi',
    'döşəmə əsaslı təmiri',
    'idman zalı bərpası',
    'yeməkxana təmiri',
    'kitabxana bərpası',
    'kompüter otağının təchizatı',
    'həyət abadlaşdırılması',
    'qoruyucu divarın tikintisi',
    'giriş qapılarının təmiri'
  ];
  
  -- Status paylanması (realistik: çox completed, bir hissəsi in_progress)
  statuses TEXT[] := ARRAY[
    'completed','completed','completed','completed','completed','completed',  -- 50% completed
    'in_progress','in_progress','in_progress',                                -- 25% in_progress
    'approved','approved',                                                    -- 17% approved
    'planned',                                                                -- 8% planned
    'on_hold'                                                                 -- çox az on_hold
  ];
  
BEGIN
  -- Podratçı və meneceri əvvəlcədən topla
  SELECT ARRAY_AGG(id) INTO contractor_ids FROM hr.contractors WHERE is_blacklisted = FALSE;
  SELECT ARRAY_AGG(id) INTO manager_ids FROM hr.employees 
    WHERE position_id IN (SELECT id FROM hr.positions WHERE code IN ('PROJECT_MGR','SENIOR_ENG','FOREMAN'));
  
  -- Hər məktəbə 1-3 layihə (random)
  FOR school_rec IN school_list LOOP
    -- Çox pis vəziyyətli məktəblərdə daha çox layihə
    FOR i IN 1..CASE 
                  WHEN school_rec.condition = 'poor' THEN 2
                  WHEN school_rec.condition = 'critical' THEN 3
                  WHEN school_rec.condition = 'satisfactory' THEN 2
                  ELSE 1
                END LOOP
      
      EXIT WHEN proj_counter >= 120;
      proj_counter := proj_counter + 1;
      
      -- Layihə növü (vəziyyətə uyğun)
      type_code := CASE 
        WHEN school_rec.condition = 'critical' THEN 'CAPITAL_REPAIR'
        WHEN school_rec.condition = 'poor' AND RANDOM() > 0.5 THEN 'CAPITAL_REPAIR'
        WHEN school_rec.built_year < 1970 AND RANDOM() > 0.6 THEN 'RECONSTRUCTION'
        WHEN RANDOM() > 0.85 THEN 'NEW_CONSTRUCTION'
        WHEN RANDOM() > 0.95 THEN 'EMERGENCY_REPAIR'
        ELSE 'CURRENT_REPAIR'
      END;
      
      SELECT id INTO type_id_v FROM construction.project_types WHERE code = type_code;
      
      -- Priority (1-5)
      priority_v := CASE 
        WHEN school_rec.condition = 'critical' THEN 1
        WHEN school_rec.condition = 'poor' THEN 2
        WHEN type_code = 'EMERGENCY_REPAIR' THEN 1
        ELSE 2 + (RANDOM() * 3)::INT
      END;
      
      -- Status (paylanma)
      status_v := statuses[1 + (RANDOM() * (array_length(statuses,1)-1))::INT];
      
      -- Tarixlər (2023-2026 aralıq)
      year_v := 2023 + (RANDOM() * 3)::INT;
      start_date_v := MAKE_DATE(year_v, 1 + (RANDOM() * 11)::INT, 1 + (RANDOM() * 27)::INT);
      
      -- Sonuncu tarix (layihə növünə görə)
      end_date_v := start_date_v + CASE type_code
        WHEN 'CURRENT_REPAIR' THEN (45 + (RANDOM() * 60))::INT
        WHEN 'CAPITAL_REPAIR' THEN (180 + (RANDOM() * 180))::INT
        WHEN 'NEW_CONSTRUCTION' THEN (420 + (RANDOM() * 240))::INT
        WHEN 'RECONSTRUCTION' THEN (300 + (RANDOM() * 180))::INT
        WHEN 'EMERGENCY_REPAIR' THEN (15 + (RANDOM() * 30))::INT
      END;
      
      -- Faktiki tarixlər (statusa uyğun)
      IF status_v IN ('completed','in_progress') THEN
        actual_start_v := start_date_v + (RANDOM() * 20 - 10)::INT;  -- ±10 gün
        IF status_v = 'completed' THEN
          actual_end_v := end_date_v + (RANDOM() * 40 - 10)::INT;   -- bəzən gec, bəzən vaxtında
          progress_v := 100;
        ELSE
          actual_end_v := NULL;
          progress_v := 20 + (RANDOM() * 70)::INT;  -- 20-90%
        END IF;
      ELSE
        actual_start_v := NULL;
        actual_end_v := NULL;
        progress_v := 0;
      END IF;
      
      -- Büdcə (layihə növünə və məktəb ölçüsünə görə)
      budget_v := CASE type_code
        WHEN 'CURRENT_REPAIR'    THEN 15000 + (school_rec.total_area_m2 * 8) + RANDOM() * 30000
        WHEN 'CAPITAL_REPAIR'    THEN 80000 + (school_rec.total_area_m2 * 45) + RANDOM() * 150000
        WHEN 'NEW_CONSTRUCTION'  THEN 500000 + (school_rec.total_area_m2 * 800) + RANDOM() * 500000
        WHEN 'RECONSTRUCTION'    THEN 250000 + (school_rec.total_area_m2 * 180) + RANDOM() * 300000
        WHEN 'EMERGENCY_REPAIR'  THEN 5000 + (school_rec.total_area_m2 * 5) + RANDOM() * 20000
      END;
      budget_v := ROUND(budget_v, 0);
      
      -- Faktiki xərc (statusa uyğun, ±10% variance)
      IF status_v = 'completed' THEN
        actual_cost_v := budget_v * (0.9 + RANDOM() * 0.25);  -- 90%-115%
      ELSIF status_v = 'in_progress' THEN
        actual_cost_v := budget_v * (progress_v::NUMERIC / 100) * (0.95 + RANDOM() * 0.15);
      ELSE
        actual_cost_v := 0;
      END IF;
      actual_cost_v := ROUND(actual_cost_v, 0);
      
      -- Bina tapaq
      SELECT id INTO building_id_v FROM infra.buildings 
        WHERE school_id = school_rec.school_id 
        ORDER BY RANDOM() LIMIT 1;
      
      -- Contractor və manager
      contractor_v := contractor_ids[1 + (RANDOM() * (array_length(contractor_ids,1)-1))::INT];
      manager_v := manager_ids[1 + (RANDOM() * (array_length(manager_ids,1)-1))::INT];
      
      -- Layihə adı
      project_name := CASE type_code
        WHEN 'CURRENT_REPAIR' THEN 
          REPLACE(REPLACE(school_rec.school_name, ' tam orta məktəb', ''), ' gimnaziya', '') || 
          '-nin ' || repair_templates[1 + (RANDOM() * (array_length(repair_templates,1)-1))::INT]
        WHEN 'CAPITAL_REPAIR' THEN 
          school_rec.school_name || '-in kapital təmiri'
        WHEN 'NEW_CONSTRUCTION' THEN 
          school_rec.school_name || ' üçün yeni korpusun tikintisi'
        WHEN 'RECONSTRUCTION' THEN 
          school_rec.school_name || '-in yenidən qurulması'
        WHEN 'EMERGENCY_REPAIR' THEN 
          school_rec.school_name || '-də təcili təmir işləri'
      END;
      
      -- INSERT
      INSERT INTO construction.projects (
        project_code, name, type_id, region_id, school_id, building_id,
        manager_id, contractor_id,
        status, priority,
        start_date, end_date, actual_start, actual_end,
        planned_budget, actual_cost, progress_percent,
        description, approval_doc_ref, approved_by, approved_date,
        created_at
      ) VALUES (
        'PRJ-' || year_v || '-' || LPAD(proj_counter::TEXT, 4, '0'),
        project_name,
        type_id_v,
        school_rec.region_id,
        school_rec.school_id,
        building_id_v,
        manager_v,
        contractor_v,
        status_v,
        priority_v,
        start_date_v,
        end_date_v,
        actual_start_v,
        actual_end_v,
        budget_v,
        actual_cost_v,
        progress_v,
        CASE type_code
          WHEN 'CURRENT_REPAIR' THEN 'Məktəbin cari istismar vəziyyətini saxlamaq məqsədilə planlaşdırılmış təmir işləri.'
          WHEN 'CAPITAL_REPAIR' THEN 'Binanın əsaslı yenilənməsi — konstruktiv elementlərin və kommunikasiyaların dəyişdirilməsi.'
          WHEN 'NEW_CONSTRUCTION' THEN 'Yeni korpus və ya məktəb binasının inşası.'
          WHEN 'RECONSTRUCTION' THEN 'Binanın planının və funksional təyinatının dəyişdirilməsi.'
          WHEN 'EMERGENCY_REPAIR' THEN 'Bina istismarına təhlükə yaradan nöqsanların təcili aradan qaldırılması.'
        END,
        'S-' || year_v || '/' || (100 + proj_counter)::TEXT,
        'Təhsil Naziri müavini — Rəşadov E.M.',
        start_date_v - (5 + RANDOM() * 20)::INT,
        NOW() - (RANDOM() * 365 * 3)::INT * INTERVAL '1 day'
      );
    END LOOP;
    
    EXIT WHEN proj_counter >= 120;
  END LOOP;
  
  RAISE NOTICE '✅ % layihə yaradıldı', proj_counter;
END $$;

-- ─── 3. LAYİHƏ MƏRHƏLƏLƏRI ───
-- Hər layihə üçün 3-5 mərhələ
DO $$
DECLARE
  p RECORD;
  phases_names TEXT[] := ARRAY[
    'Dizayn və layihələndirmə',
    'Hazırlıq işləri',
    'Tikinti/təmir işləri',
    'Daxili işləmə',
    'Yoxlama və təhvil'
  ];
  phase_count INT;
  i INT;
  phase_start DATE;
  phase_end DATE;
  phase_status TEXT;
  phase_completion SMALLINT;
BEGIN
  FOR p IN SELECT id, status, start_date, end_date, actual_start, progress_percent 
           FROM construction.projects LOOP
    
    phase_count := 3 + (RANDOM() * 2)::INT;  -- 3-5 mərhələ
    
    FOR i IN 1..phase_count LOOP
      -- Mərhələnin başlangıc və bitiş tarixi
      IF p.start_date IS NOT NULL AND p.end_date IS NOT NULL THEN
        phase_start := p.start_date + ((i-1) * (p.end_date - p.start_date) / phase_count)::INT;
        phase_end   := p.start_date + (i * (p.end_date - p.start_date) / phase_count)::INT;
      ELSE
        phase_start := NULL;
        phase_end := NULL;
      END IF;
      
      -- Status və tərəqqi
      IF p.status = 'completed' THEN
        phase_status := 'completed';
        phase_completion := 100;
      ELSIF p.status = 'in_progress' THEN
        -- Layihə tərəqqisinə əsasən hesabla
        IF (i * 100 / phase_count) <= p.progress_percent THEN
          phase_status := 'completed';
          phase_completion := 100;
        ELSIF ((i-1) * 100 / phase_count) < p.progress_percent THEN
          phase_status := 'in_progress';
          phase_completion := 50 + (RANDOM() * 40)::INT;
        ELSE
          phase_status := 'pending';
          phase_completion := 0;
        END IF;
      ELSE
        phase_status := 'pending';
        phase_completion := 0;
      END IF;
      
      INSERT INTO construction.project_phases (
        project_id, phase_number, name, start_date, end_date, status, completion_pct
      ) VALUES (
        p.id, i, phases_names[i], phase_start, phase_end, phase_status, phase_completion
      );
    END LOOP;
  END LOOP;
  
  RAISE NOTICE '✅ Bütün layihələr üçün mərhələlər yaradıldı';
END $$;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ LAYİHƏ STATİSTİKASI ═══'
SELECT 'Layihə növləri: ' || COUNT(*) FROM construction.project_types
UNION ALL
SELECT 'Layihələr: '     || COUNT(*) FROM construction.projects
UNION ALL
SELECT 'Mərhələlər: '    || COUNT(*) FROM construction.project_phases;

\echo ''
\echo '═══ Status üzrə layihələr ═══'
SELECT 
  status AS "Status",
  COUNT(*) AS "Sayı",
  ROUND(SUM(planned_budget)/1000000, 1) AS "Büdcə (mln AZN)",
  ROUND(AVG(progress_percent), 0) AS "Orta %"
FROM construction.projects
GROUP BY status
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ Növ üzrə layihələr ═══'
SELECT 
  pt.icon || ' ' || pt.name_az AS "Növ",
  COUNT(p.id) AS "Sayı",
  ROUND(AVG(p.planned_budget)/1000, 0) AS "Orta büdcə (K AZN)"
FROM construction.project_types pt
LEFT JOIN construction.projects p ON p.type_id = pt.id
GROUP BY pt.id, pt.icon, pt.name_az
ORDER BY COUNT(p.id) DESC;

\echo ''
\echo '═══ İl üzrə layihələr ═══'
SELECT 
  EXTRACT(YEAR FROM start_date)::INT AS "İl",
  COUNT(*) AS "Layihə",
  ROUND(SUM(planned_budget)/1000000, 1) AS "Büdcə (mln AZN)"
FROM construction.projects
WHERE start_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM start_date)
ORDER BY 1;

\echo ''
\echo '═══ Ən böyük 5 layihə ═══'
SELECT 
  project_code AS "Kod",
  LEFT(name, 60) AS "Ad",
  status AS "Status",
  ROUND(planned_budget/1000) AS "Büdcə (K AZN)"
FROM construction.projects
ORDER BY planned_budget DESC
LIMIT 5;

\echo ''
\echo '═══ Rayon üzrə top 10 ═══'
SELECT 
  r.name_az AS "Rayon",
  COUNT(p.id) AS "Layihə",
  ROUND(SUM(p.planned_budget)/1000000, 1) AS "Büdcə (mln AZN)"
FROM geo.regions r
JOIN construction.projects p ON p.region_id = r.id
GROUP BY r.id, r.name_az
ORDER BY COUNT(p.id) DESC
LIMIT 10;
