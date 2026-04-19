-- ═══════════════════════════════════════════════════════════════
-- 02c: HR — İşçilər (300) + Podratçılar (50) + Briqadalar (15)
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. ŞÖBƏLƏR (6) ───
INSERT INTO hr.departments (code, name_az) VALUES
('MGMT',  'İdarəetmə və rəhbərlik'),
('CONST', 'Tikinti və texniki şöbə'),
('PROJ',  'Layihə idarəetməsi'),
('FIN',   'Maliyyə və mühasibat'),
('HR',    'Kadrlar şöbəsi'),
('AUDIT', 'Daxili audit və nəzarət'),
('IT',    'İnformasiya texnologiyaları'),
('LEGAL', 'Hüquq məsələləri');

-- ─── 2. VƏZİFƏLƏR (15) ───
INSERT INTO hr.positions (code, name_az, category, salary_min, salary_max) VALUES
-- Management
('DIRECTOR',       'Baş direktor',                 'management',   3500, 6000),
('DEPUTY_DIR',     'Baş direktorun müavini',       'management',   2800, 4500),
('DEPT_HEAD',      'Şöbə müdiri',                  'management',   2200, 3500),
-- Engineering
('CHIEF_ENGINEER', 'Baş mühəndis',                 'engineering',  2500, 4000),
('SENIOR_ENG',     'Böyük mühəndis',               'engineering',  1800, 2800),
('ENGINEER',       'Mühəndis',                     'engineering',  1200, 2000),
('ARCHITECT',      'Memar',                        'engineering',  1500, 2500),
-- Construction
('PROJECT_MGR',    'Layihə meneceri',              'construction', 1500, 2500),
('FOREMAN',        'Prorab',                       'construction', 1200, 1800),
('CONSTRUCTOR',    'İnşaatçı',                     'construction', 800, 1400),
-- Inspection
('CHIEF_INSP',     'Baş inspektor',                'inspection',   1800, 2800),
('INSPECTOR',      'İnspektor',                    'inspection',   1000, 1600),
-- Finance
('CHIEF_ACC',      'Baş mühasib',                  'finance',      2000, 3000),
('ACCOUNTANT',     'Mühasib',                      'finance',      1000, 1600),
-- Admin
('ADMIN',          'Administrator',                'admin',        800, 1200);

-- ─── 3. 300 İŞÇİ (real Azərbaycan adları ilə) ───
DO $$
DECLARE
  first_names_m TEXT[] := ARRAY[
    'Elşən','Rəşad','Vüqar','Kamal','Səbuhi','Rövşən','Elvin','Cavid','Orxan','Ramil',
    'Samir','Tural','Rufat','Fərhad','Rəhim','Murad','Tofiq','Vəli','Zaur','Elnur',
    'İlqar','Nəriman','Ruslan','Akif','Emil','Nicat','Vüsal','Kənan','Faiq','Fərid',
    'Bəhruz','Elşad','Rəşid','Elçin','Əli','Mehdi','Tahir','Sabir','Nadir','Həsən',
    'Əliyar','Səttar','Arif','Namiq','Mahmud','Teymur','Nağı','Fazil','Ədalət','Cəlal'
  ];
  first_names_f TEXT[] := ARRAY[
    'Nərgiz','Aynur','Kəmalə','Sevinc','Nailə','Ülkər','Lalə','Zöhrə','Təranə','Səadət',
    'Sevda','Zəminə','Nərminə','Aygün','Gülnaz','Nigar','Ramilə','Rəna','Fatimə','Aybəniz',
    'Mehriban','Sevil','Tahirə','Gülşən','Rəxşanə','Səbinə','Afət','Lamiyə','Tahira','Elnarə'
  ];
  last_names TEXT[] := ARRAY[
    'Əliyev','Məmmədov','Həsənov','Hüseynov','Quliyev','İsmayılov','Rəhimov','Əhmədov','Bağırov','Qasımov',
    'Nəbiyev','Cəfərov','Süleymanov','Abdullayev','Rzayev','Nəsirov','Qurbanov','Abbasov','Əfəndiyev','Mirzəyev',
    'Hacıyev','Babayev','Həmidov','Rüstəmov','Əmirov','Şirinov','Orucov','Nəcəfov','Həbibov','Vəliyev'
  ];
  regions_codes TEXT[] := ARRAY[
    'BA','GA','SM','NX','ML','SK','AG','BR','QB','LK','XC','GY','TV','AB','ZQ','MS','ABS',
    'BAY','BAG','BAN','BAR','BAS','BAX','BAZ','BAP','BAS2','BAY2','BAN2','BAB'
  ];
  positions_codes TEXT[] := ARRAY[
    'DIRECTOR','DEPUTY_DIR','DEPT_HEAD',
    'CHIEF_ENGINEER','SENIOR_ENG','ENGINEER','ENGINEER','ENGINEER','ENGINEER',
    'ARCHITECT','ARCHITECT',
    'PROJECT_MGR','PROJECT_MGR','PROJECT_MGR',
    'FOREMAN','FOREMAN','FOREMAN','FOREMAN',
    'CONSTRUCTOR','CONSTRUCTOR','CONSTRUCTOR','CONSTRUCTOR','CONSTRUCTOR','CONSTRUCTOR','CONSTRUCTOR',
    'CHIEF_INSP','INSPECTOR','INSPECTOR','INSPECTOR',
    'CHIEF_ACC','ACCOUNTANT','ACCOUNTANT',
    'ADMIN','ADMIN'
  ];
  dept_codes TEXT[] := ARRAY['MGMT','CONST','CONST','PROJ','PROJ','FIN','HR','AUDIT','IT','LEGAL'];
  
  is_male BOOLEAN;
  fname TEXT;
  lname TEXT;
  father_name TEXT;
  pos_code TEXT;
  pos_id INT;
  dept_id INT;
  region_id INT;
  salary_min_v NUMERIC;
  salary_max_v NUMERIC;
  salary_v NUMERIC;
  i INT;
BEGIN
  FOR i IN 1..300 LOOP
    is_male := (RANDOM() > 0.35);  -- 65% male, 35% female
    
    IF is_male THEN
      fname := first_names_m[1 + (RANDOM() * (array_length(first_names_m, 1) - 1))::INT];
      father_name := first_names_m[1 + (RANDOM() * (array_length(first_names_m, 1) - 1))::INT];
      lname := last_names[1 + (RANDOM() * (array_length(last_names, 1) - 1))::INT];
    ELSE
      fname := first_names_f[1 + (RANDOM() * (array_length(first_names_f, 1) - 1))::INT];
      father_name := first_names_m[1 + (RANDOM() * (array_length(first_names_m, 1) - 1))::INT];
      lname := last_names[1 + (RANDOM() * (array_length(last_names, 1) - 1))::INT] || 'a';  -- qadın soyadı
    END IF;
    
    -- Vəzifə və şöbə
    pos_code := positions_codes[1 + (RANDOM() * (array_length(positions_codes, 1) - 1))::INT];
    SELECT id INTO pos_id FROM hr.positions WHERE code = pos_code LIMIT 1;
    SELECT salary_min, salary_max INTO salary_min_v, salary_max_v FROM hr.positions WHERE id = pos_id;
    
    SELECT id INTO dept_id FROM hr.departments 
      WHERE code = dept_codes[1 + (RANDOM() * (array_length(dept_codes, 1) - 1))::INT] LIMIT 1;
    
    SELECT id INTO region_id FROM geo.regions 
      WHERE code = regions_codes[1 + (RANDOM() * (array_length(regions_codes, 1) - 1))::INT] LIMIT 1;
    
    -- Maaş hesabla
    salary_v := salary_min_v + (RANDOM() * (salary_max_v - salary_min_v));
    
    -- Insert
    INSERT INTO hr.employees (
      full_name, position_id, department_id, region_id,
      birth_date, gender, phone, email, hire_date,
      monthly_salary, qualification_level, is_active
    ) VALUES (
      lname || ' ' || fname || ' ' || father_name || CASE WHEN is_male THEN ' oğlu' ELSE ' qızı' END,
      pos_id,
      dept_id,
      region_id,
      DATE '1960-01-01' + (RANDOM() * 365 * 40)::INT,  -- 1960-2000 doğum
      CASE WHEN is_male THEN 'M' ELSE 'F' END,
      '+99450' || LPAD((1000000 + i)::TEXT, 7, '0'),
      LOWER(fname) || '.' || LOWER(lname) || i::TEXT || '@arti.az',
      DATE '2010-01-01' + (RANDOM() * 365 * 15)::INT,  -- 2010-2025 işə qəbul
      ROUND(salary_v, 0),
      1 + (RANDOM() * 4)::INT,  -- 1-5
      (RANDOM() > 0.05)  -- 95% aktiv
    );
  END LOOP;
  
  RAISE NOTICE '✅ 300 işçi yaradıldı';
END $$;

-- ─── 4. 50 PODRATÇI ŞİRKƏT ───
DO $$
DECLARE
  company_prefixes TEXT[] := ARRAY[
    'Azər','Milli','Bakı','Gəncə','İnşaat','Memar','Dizayn','Mega','Prime','Top',
    'Extra','Super','Star','Elite','Future','Modern','Smart','Best','Perfect','Royal'
  ];
  company_types TEXT[] := ARRAY[
    'tikinti','inşaat','memarlıq','konstruksiya','renovasiya','təmir','layihə','quraşdırma'
  ];
  company_forms TEXT[] := ARRAY['MMC','ASC','FK','İP'];
  categories TEXT[] := ARRAY['general','electrical','plumbing','hvac','roofing','finishing','specialized'];
  
  i INT;
  prefix TEXT;
  ctype TEXT;
  cform TEXT;
  full_name TEXT;
  cat TEXT;
BEGIN
  FOR i IN 1..50 LOOP
    prefix := company_prefixes[1 + (RANDOM() * (array_length(company_prefixes, 1) - 1))::INT];
    ctype := company_types[1 + (RANDOM() * (array_length(company_types, 1) - 1))::INT];
    cform := company_forms[1 + (RANDOM() * (array_length(company_forms, 1) - 1))::INT];
    cat := categories[1 + (RANDOM() * (array_length(categories, 1) - 1))::INT];
    
    full_name := prefix || ctype || ' ' || cform;
    
    INSERT INTO hr.contractors (
      name, tin, category, registration_date, address, phone, email,
      director_name, employee_count, rating, completed_projects,
      total_revenue, is_blacklisted
    ) VALUES (
      full_name || ' #' || i,
      LPAD((1000000000 + i * 137)::TEXT, 10, '0'),  -- Fake VÖEN
      cat,
      DATE '2005-01-01' + (RANDOM() * 365 * 20)::INT,
      'Bakı, ' || prefix || ' küçəsi ' || (1 + RANDOM() * 100)::INT,
      '+99412' || LPAD((5000000 + i)::TEXT, 7, '0'),
      LOWER(REPLACE(prefix, 'ə', 'e')) || i::TEXT || '@' || LOWER(cform) || '.az',
      'Direktor ' || i || ' oğlu',
      10 + (RANDOM() * 200)::INT,
      4.0 + RANDOM() * 6.0,  -- 4.0-10.0
      (RANDOM() * 30)::INT,
      ROUND((100000 + RANDOM() * 5000000)::NUMERIC, 0),
      (RANDOM() > 0.9)  -- 10% blacklist
    );
  END LOOP;
  
  RAISE NOTICE '✅ 50 podratçı şirkət yaradıldı';
END $$;

-- ─── 5. 15 BRİQADA ───
DO $$
DECLARE
  team_types TEXT[] := ARRAY['masonry','electrical','plumbing','roofing','finishing','general'];
  team_names TEXT[] := ARRAY[
    'Alpha briqada','Beta briqada','Gamma briqada','Delta briqada','Epsilon briqada',
    'Zeta briqada','Eta briqada','Theta briqada','Iota briqada','Kappa briqada',
    'Lambda briqada','Mu briqada','Nu briqada','Xi briqada','Omikron briqada'
  ];
  i INT;
  leader_id INT;
BEGIN
  FOR i IN 1..15 LOOP
    -- Prorab və ya mühəndis olan işçini lider seç
    SELECT e.id INTO leader_id 
    FROM hr.employees e
    JOIN hr.positions p ON e.position_id = p.id
    WHERE p.code IN ('FOREMAN', 'ENGINEER', 'SENIOR_ENG')
      AND e.is_active = TRUE
    ORDER BY RANDOM()
    LIMIT 1;
    
    INSERT INTO hr.teams (name, team_type, leader_id, member_count, is_active)
    VALUES (
      team_names[i],
      team_types[1 + (RANDOM() * (array_length(team_types, 1) - 1))::INT],
      leader_id,
      5 + (RANDOM() * 10)::INT,  -- 5-15 nəfər
      TRUE
    );
  END LOOP;
  
  RAISE NOTICE '✅ 15 briqada yaradıldı';
END $$;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ HR STATİSTİKASI ═══'
SELECT 'Şöbələr: '   || COUNT(*) FROM hr.departments
UNION ALL
SELECT 'Vəzifələr: ' || COUNT(*) FROM hr.positions
UNION ALL
SELECT 'İşçilər: '   || COUNT(*) FROM hr.employees
UNION ALL
SELECT 'Podratçılar: ' || COUNT(*) FROM hr.contractors
UNION ALL
SELECT 'Briqadalar: ' || COUNT(*) FROM hr.teams;

\echo ''
\echo '═══ Vəzifə üzrə işçi sayı (top 10) ═══'
SELECT p.name_az AS "Vəzifə", COUNT(e.id) AS "Sayı", ROUND(AVG(e.monthly_salary)) AS "Orta maaş"
FROM hr.positions p
LEFT JOIN hr.employees e ON e.position_id = p.id
GROUP BY p.id, p.name_az
ORDER BY COUNT(e.id) DESC
LIMIT 10;

\echo ''
\echo '═══ Cins paylanması ═══'
SELECT 
  CASE gender WHEN 'M' THEN 'Kişi' ELSE 'Qadın' END AS "Cins",
  COUNT(*) AS "Sayı"
FROM hr.employees
GROUP BY gender;

\echo ''
\echo '═══ Podratçı reytinqi ═══'
SELECT category AS "Kateqoriya", COUNT(*) AS "Sayı", ROUND(AVG(rating), 1) AS "Orta rating"
FROM hr.contractors
GROUP BY category
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ Nümunə işçilər ═══'
SELECT full_name, gender, TO_CHAR(monthly_salary, 'FM999,999') AS maaş
FROM hr.employees 
ORDER BY monthly_salary DESC 
LIMIT 5;
