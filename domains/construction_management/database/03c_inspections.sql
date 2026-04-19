-- ═══════════════════════════════════════════════════════════════
-- 03c: Yoxlamalar (800) + Aktlar (400) + Vətəndaş şikayətləri (300)
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. YOXLAMALAR (800) ───
DO $$
DECLARE
  i INT;
  counter INT := 0;
  p RECORD;
  insp_id INT;
  insp_date DATE;
  insp_type TEXT;
  quality_v NUMERIC;
  issues_v INT;
  resolved_v INT;
  followup_v BOOLEAN;
  report_templates TEXT[] := ARRAY[
    'İşlər qrafikə uyğun icra edilir. Kiçik nöqsanlar aradan qaldırıldı.',
    'Tikinti materialları standartlara uyğun gəlir. İş prosesi davamlıdır.',
    'Təhlükəsizlik tələbləri tam yerinə yetirilir. Briqada tam komplektdir.',
    'Bir neçə nöqsan aşkar edildi, podratçıya təcili aradan qaldırılması göstərişi verilib.',
    'İş keyfiyyəti yüksəkdir, müəyyən edilmiş qrafikdən öncə bitəcək.',
    'Materialların keyfiyyətində problem aşkar edildi. Sertifikatlar yoxlanılır.',
    'İşçilərə təhlükəsizlik təliminin keçilməsi tövsiyə olunur.',
    'Bütün sənədlər qaydasında, icra normaldır.',
    'Cüzi geсikmə var, amma bitmə tarixinə təsir göstərməyəcək.',
    'Qüsursuz iş. Tövsiyə olunur bu briqada gələcək layihələrdə də istifadə edilsin.'
  ];
  insp_types_arr TEXT[] := ARRAY['scheduled','scheduled','scheduled','unscheduled','complaint','acceptance','final'];
BEGIN
  -- Aktiv və tamamlanmış layihələrə yoxlama
  FOR p IN 
    SELECT id, status, actual_start, actual_end, 
           COALESCE(actual_start, start_date) AS start_d
    FROM construction.projects 
    WHERE status IN ('completed','in_progress')
    ORDER BY id
  LOOP
    -- Hər layihə üçün 5-12 yoxlama
    FOR i IN 1..(5 + (RANDOM() * 7)::INT) LOOP
      counter := counter + 1;
      EXIT WHEN counter > 800;
      
      -- İnspektor (CHIEF_INSP və ya INSPECTOR)
      SELECT id INTO insp_id FROM hr.employees 
        WHERE position_id IN (SELECT id FROM hr.positions WHERE code IN ('CHIEF_INSP','INSPECTOR'))
        ORDER BY RANDOM() LIMIT 1;
      
      -- Yoxlama növü
      insp_type := insp_types_arr[1 + (RANDOM() * (array_length(insp_types_arr,1)-1))::INT];
      
      -- Tarix (start-dan end-ə qədər)
      insp_date := p.start_d + (RANDOM() * 
        GREATEST(COALESCE(p.actual_end, CURRENT_DATE), p.start_d + 30) - p.start_d)::INT;
      
      -- Keyfiyyət balı
      quality_v := ROUND((5.5 + RANDOM() * 4.5)::NUMERIC, 1);  -- 5.5-10
      
      -- Nöqsanlar (keyfiyyətdən asılı)
      IF quality_v >= 9 THEN
        issues_v := (RANDOM() * 2)::INT;        -- 0-2
      ELSIF quality_v >= 7 THEN
        issues_v := 1 + (RANDOM() * 4)::INT;    -- 1-5
      ELSE
        issues_v := 3 + (RANDOM() * 7)::INT;    -- 3-10
      END IF;
      
      resolved_v := (issues_v * (0.6 + RANDOM() * 0.4))::INT;
      followup_v := (issues_v > resolved_v);
      
      INSERT INTO construction.inspections (
        project_id, inspector_id, inspection_type, inspection_date,
        quality_score, issues_found, issues_resolved, 
        requires_followup, followup_date, report_text
      ) VALUES (
        p.id, insp_id, insp_type, insp_date,
        quality_v, issues_v, resolved_v,
        followup_v,
        CASE WHEN followup_v THEN insp_date + 14 ELSE NULL END,
        report_templates[1 + (RANDOM() * (array_length(report_templates,1)-1))::INT]
      );
    END LOOP;
    
    EXIT WHEN counter > 800;
  END LOOP;
  
  RAISE NOTICE '✅ % yoxlama yaradıldı', counter;
END $$;

-- ─── 2. AKTLAR (400) ───
DO $$
DECLARE
  p RECORD;
  counter INT := 0;
  i INT;
  act_count INT;
  act_type_v TEXT;
  act_date_v DATE;
  act_amount NUMERIC;
  act_types TEXT[] := ARRAY['intermediate','intermediate','intermediate','preliminary','final','correction'];
BEGIN
  FOR p IN 
    SELECT id, status, actual_cost, actual_start, actual_end,
           COALESCE(actual_start, start_date) AS start_d
    FROM construction.projects 
    WHERE actual_cost > 0 
      AND status IN ('completed','in_progress')
      AND COALESCE(actual_start, start_date) IS NOT NULL
    ORDER BY id
  LOOP
    -- Layihə ölçüsünə görə akt sayı
    act_count := CASE 
      WHEN p.actual_cost > 1000000 THEN 4 + (RANDOM() * 3)::INT  -- 4-7 akt
      WHEN p.actual_cost > 200000  THEN 2 + (RANDOM() * 2)::INT  -- 2-4 akt
      ELSE 1 + (RANDOM() * 2)::INT                                -- 1-3 akt
    END;
    
    FOR i IN 1..act_count LOOP
      counter := counter + 1;
      EXIT WHEN counter > 400;
      
      -- Akt növü (sonuncu final/correction)
      IF i = act_count AND p.status = 'completed' THEN
        act_type_v := 'final';
      ELSIF i = 1 THEN
        act_type_v := 'preliminary';
      ELSE
        act_type_v := act_types[1 + (RANDOM() * (array_length(act_types,1)-1))::INT];
      END IF;
      
      act_date_v := p.start_d + (RANDOM() * 180)::INT;
      act_amount := ROUND((p.actual_cost / act_count::NUMERIC)::NUMERIC, 2);
      
      INSERT INTO construction.acts (
        project_id, act_number, act_type, act_date, amount,
        signed_by_contractor, signed_by_manager, signed_by_inspector,
        is_paid, notes
      ) VALUES (
        p.id,
        'ACT-' || TO_CHAR(act_date_v, 'YYYY') || '-' || LPAD(counter::TEXT, 5, '0'),
        act_type_v,
        act_date_v,
        act_amount,
        TRUE,  -- contractor signed
        RANDOM() > 0.1,  -- 90% manager signed
        RANDOM() > 0.2,  -- 80% inspector signed
        p.status = 'completed' OR RANDOM() > 0.3,  -- paid
        CASE act_type_v 
          WHEN 'final' THEN 'Yekun təhvil-təslim aktı'
          WHEN 'preliminary' THEN 'İlkin işlər üzrə akt'
          WHEN 'correction' THEN 'Nöqsanların aradan qaldırılması aktı'
          ELSE 'Aralıq mərhələnin qəbul aktı'
        END
      );
    END LOOP;
    
    EXIT WHEN counter > 400;
  END LOOP;
  
  RAISE NOTICE '✅ % akt yaradıldı', counter;
END $$;

-- ─── 3. VƏTƏNDAŞ ŞİKAYƏTLƏRI (300) ───
DO $$
DECLARE
  i INT;
  sch_id INT;
  prj_id INT;
  comp_date DATE;
  channel_v TEXT;
  category_v TEXT;
  urgency_v TEXT;
  status_v TEXT;
  resolution_v DATE;
  resolution_days_v INT;
  text_v TEXT;
  response_v TEXT;
  channels TEXT[] := ARRAY['asan','asan','phone','phone','email','letter','website','website'];
  categories TEXT[] := ARRAY[
    'heating','roof','safety','corruption','quality','timeline',
    'materials','contractor','hygiene','accessibility'
  ];
  urgencies TEXT[] := ARRAY['low','low','normal','normal','normal','high','high','critical'];
  complaint_templates TEXT[] := ARRAY[
    'İstilik sistemi düzgün işləmir, sinif otaqları soyuqdur.',
    'Məktəbin damında sızıntı var, yağışlı havada sinif otaqlarına su axır.',
    'Təhlükəsizlik qaydaları pozulur, inşaat sahəsi uşaqlara açıqdır.',
    'Podratçı keyfiyyətli iş görmür, materiallar standartdan aşağıdır.',
    'Tikinti işləri çox uzanır, dərs prosesinə mane olur.',
    'İşçilər təhlükəsizlik geyimi olmadan işləyir.',
    'Keyfiyyətli material istifadə olunmur.',
    'Məktəb həyətində təhlükəli çuxurlar var.',
    'Tikintidən yaranan toz və səs-küy şagirdlərə mənfi təsir edir.',
    'Yeni tikilmiş pəncərələr bağlanmır, soyuqda qalırıq.',
    'Sanitariya qovşaqları antisanitar vəziyyətdədir.',
    'Əlillər üçün giriş pandusu yoxdur.'
  ];
  response_templates TEXT[] := ARRAY[
    'Şikayətiniz nəzərə alınıb. Layihə menecerinə göndərildi.',
    'Podratçıya müraciət olunub, nöqsan təcili aradan qaldırılacaq.',
    'Ərizəniz ətraflı yoxlanıldı, müvafiq tədbirlər görüldü.',
    'Çatışmazlıq tamamilə aradan qaldırıldı.',
    'Bu məsələ növbəti yoxlamada əlavə nəzarətdə saxlanılır.'
  ];
BEGIN
  FOR i IN 1..300 LOOP
    -- Bəzən layihə var, bəzən yoxdur
    IF RANDOM() > 0.3 THEN  -- 70% layihəyə bağlı
      SELECT id, school_id INTO prj_id, sch_id 
        FROM construction.projects ORDER BY RANDOM() LIMIT 1;
    ELSE
      prj_id := NULL;
      SELECT id INTO sch_id FROM infra.schools ORDER BY RANDOM() LIMIT 1;
    END IF;
    
    comp_date := CURRENT_DATE - (RANDOM() * 365 * 2)::INT;
    channel_v := channels[1 + (RANDOM() * (array_length(channels,1)-1))::INT];
    category_v := categories[1 + (RANDOM() * (array_length(categories,1)-1))::INT];
    urgency_v := urgencies[1 + (RANDOM() * (array_length(urgencies,1)-1))::INT];
    
    -- Status (paylanma: çox resolved, bir az investigating)
    IF RANDOM() < 0.6 THEN
      status_v := 'resolved';
      resolution_days_v := 5 + (RANDOM() * 25)::INT;
      resolution_v := comp_date + resolution_days_v;
    ELSIF RANDOM() < 0.8 THEN
      status_v := 'closed';
      resolution_days_v := 10 + (RANDOM() * 30)::INT;
      resolution_v := comp_date + resolution_days_v;
    ELSIF RANDOM() < 0.92 THEN
      status_v := 'investigating';
      resolution_v := NULL;
      resolution_days_v := NULL;
    ELSE
      status_v := 'new';
      resolution_v := NULL;
      resolution_days_v := NULL;
    END IF;
    
    text_v := complaint_templates[1 + (RANDOM() * (array_length(complaint_templates,1)-1))::INT];
    
    response_v := CASE 
      WHEN status_v IN ('resolved','closed') THEN 
        response_templates[1 + (RANDOM() * (array_length(response_templates,1)-1))::INT]
      ELSE NULL
    END;
    
    INSERT INTO construction.citizen_complaints (
      school_id, project_id, complaint_date, channel, category,
      urgency, status, resolution_date, resolution_days,
      text, response_text
    ) VALUES (
      sch_id, prj_id, comp_date, channel_v, category_v,
      urgency_v, status_v, resolution_v, resolution_days_v,
      text_v, response_v
    );
  END LOOP;
  
  RAISE NOTICE '✅ 300 vətəndaş şikayəti yaradıldı';
END $$;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ YOXLAMA STATİSTİKASI ═══'
SELECT 'Yoxlamalar: '   || COUNT(*) FROM construction.inspections
UNION ALL
SELECT 'Aktlar: '       || COUNT(*) FROM construction.acts
UNION ALL
SELECT 'Şikayətlər: '   || COUNT(*) FROM construction.citizen_complaints;

\echo ''
\echo '═══ Yoxlama növü ═══'
SELECT 
  inspection_type AS "Növ", 
  COUNT(*) AS "Sayı",
  ROUND(AVG(quality_score), 1) AS "Orta keyfiyyət"
FROM construction.inspections
GROUP BY inspection_type
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ Akt növü ═══'
SELECT 
  act_type AS "Növ",
  COUNT(*) AS "Sayı",
  COUNT(*) FILTER (WHERE is_paid) AS "Ödənilib",
  ROUND(SUM(amount)/1000000, 2) AS "Cəmi (mln AZN)"
FROM construction.acts
GROUP BY act_type
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ Şikayət statusu ═══'
SELECT 
  status AS "Status",
  COUNT(*) AS "Sayı",
  ROUND(AVG(resolution_days), 1) AS "Orta həll (gün)"
FROM construction.citizen_complaints
GROUP BY status
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ Şikayət kateqoriyası ═══'
SELECT 
  category AS "Kateqoriya",
  COUNT(*) AS "Sayı"
FROM construction.citizen_complaints
GROUP BY category
ORDER BY COUNT(*) DESC
LIMIT 8;

\echo ''
\echo '═══ Şikayət kanalı ═══'
SELECT 
  channel AS "Kanal",
  COUNT(*) AS "Sayı"
FROM construction.citizen_complaints
GROUP BY channel
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ YEKUN BAZA STATİSTİKASI ═══'
SELECT 'Rayonlar: '           || COUNT(*) FROM geo.regions
UNION ALL
SELECT 'Məktəblər: '          || COUNT(*) FROM infra.schools
UNION ALL
SELECT 'İşçilər: '            || COUNT(*) FROM hr.employees
UNION ALL
SELECT 'Podratçılar: '        || COUNT(*) FROM hr.contractors
UNION ALL
SELECT 'Materiallar: '        || COUNT(*) FROM inventory.materials
UNION ALL
SELECT 'Anbarlar: '           || COUNT(*) FROM inventory.warehouses
UNION ALL
SELECT 'Büdcələr: '           || COUNT(*) FROM finance.budgets
UNION ALL
SELECT 'Layihələr: '          || COUNT(*) FROM construction.projects
UNION ALL
SELECT 'Xərclər: '            || COUNT(*) FROM finance.expenses
UNION ALL
SELECT 'Material hərəkəti: '  || COUNT(*) FROM inventory.material_transactions
UNION ALL
SELECT 'İnvoyslər: '          || COUNT(*) FROM finance.invoices
UNION ALL
SELECT 'Ödənişlər: '          || COUNT(*) FROM finance.payments
UNION ALL
SELECT 'Yoxlamalar: '         || COUNT(*) FROM construction.inspections
UNION ALL
SELECT 'Aktlar: '             || COUNT(*) FROM construction.acts
UNION ALL
SELECT 'Şikayətlər: '         || COUNT(*) FROM construction.citizen_complaints;
