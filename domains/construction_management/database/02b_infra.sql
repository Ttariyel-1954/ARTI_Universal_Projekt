-- ═══════════════════════════════════════════════════════════════
-- 02b: İnfrastruktur — 100 məktəb + binalar + vəziyyət
-- ═══════════════════════════════════════════════════════════════

-- ─── Məktəb tipləri ───
INSERT INTO infra.school_types (code, name_az, level) VALUES
('PRIMARY',    'Ümumi orta təhsil I pillə',   'primary'),
('SECONDARY',  'Tam orta məktəb',              'secondary'),
('HIGH',       'Tam orta məktəb',              'high'),
('LYCEUM',     'Lisey',                        'high'),
('GYMNASIUM',  'Gimnaziya',                    'high'),
('MIXED',      'Ümumtəhsil məktəbi',           'mixed'),
('SPECIAL',    'İxtisaslaşdırılmış məktəb',   'special');

-- ═══════════════════════════════════════════════════════════════
-- MƏKTƏBLƏR: Bakı = 30, iri şəhərlər = 4-5, rayonlar = 1-2
-- ═══════════════════════════════════════════════════════════════

-- ─── BAKİ (30 məktəb, 12 rayona bölünür) ───
INSERT INTO infra.schools (code, name, region_id, type_id, address, student_count, teacher_count, total_area_m2, built_year, condition, has_heating, has_canteen, has_gym, has_library, has_computer_lab, director_name, phone, lat, lng) VALUES
('SCH-BA-001', '145 saylı tam orta məktəb',     (SELECT id FROM geo.regions WHERE code='BAY'),  2, 'Binəqədi, Y.Səfərov küç. 15',   1250, 78, 4500.00, 1978, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Əliyev Rəşad Məmmədəli oğlu',    '+994125432100', 40.456000, 49.820000),
('SCH-BA-002', '23 saylı gimnaziya',             (SELECT id FROM geo.regions WHERE code='BAN'),  5, 'Nəsimi, Nizami küç. 45',        890,  62, 3200.00, 1985, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Həsənova Nərgiz Vidadi qızı',    '+994125432101', 40.399000, 49.845000),
('SCH-BA-003', '8 saylı lisey',                   (SELECT id FROM geo.regions WHERE code='BAR'),  4, 'Nərimanov, A.Salamzadə 12',     1540, 95, 5800.00, 1968, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE,  'Quliyev Elçin Akif oğlu',        '+994125432102', 40.410000, 49.880000),
('SCH-BA-004', '17 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAS'),  3, 'Səbail, H.Zərdabi 78',           1120, 72, 4200.00, 1972, 'poor',       TRUE, TRUE, TRUE, TRUE, FALSE, 'Rəhimova Səadət Tofiq qızı',     '+994125432103', 40.367000, 49.830000),
('SCH-BA-005', '52 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAX'),  3, 'Xətai, Əhməd Rəcəbli 14',        1680, 102, 6200.00, 1990, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE,  'Məmmədov Rafael Səttar oğlu',    '+994125432104', 40.376000, 49.913000),
('SCH-BA-006', '132 saylı gimnaziya',             (SELECT id FROM geo.regions WHERE code='BAZ'),  5, 'Xəzər, Şüvəlan şosesi 7',        720,  48, 2800.00, 2005, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE,  'Abbasov Tural Eldar oğlu',       '+994125432105', 40.366000, 50.076000),
('SCH-BA-007', '69 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAS2'), 3, 'Suraxanı, Q.Qaraev 3',           1340, 85, 4800.00, 1975, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Hüseynov İlqar Sabir oğlu',      '+994125432106', 40.417000, 50.015000),
('SCH-BA-008', '18 saylı lisey',                  (SELECT id FROM geo.regions WHERE code='BAY2'), 4, 'Yasamal, H.Cavid prospekti 42',  1890, 115, 7200.00, 1965, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Əhmədov Zaur Həsən oğlu',        '+994125432107', 40.388000, 49.827000),
('SCH-BA-009', '97 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAN2'), 3, 'Nizami, R.Axundov küç. 22',      1430, 89, 5100.00, 1980, 'satisfactory', TRUE, TRUE, TRUE, TRUE, FALSE, 'Əliyeva Kəmalə Ələkbər qızı',    '+994125432108', 40.398000, 49.943000),
('SCH-BA-010', '215 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAG'),  3, 'Qaradağ, Hövsan qəsəbəsi',       980,  67, 3800.00, 1988, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Nəbiyev Samir Əliağa oğlu',      '+994125432109', 40.423000, 49.637000),
('SCH-BA-011', '245 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAP'),  3, 'Pirallahı, Mərkəzi küç. 5',      450,  32, 1800.00, 2010, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE,  'Cəfərov Rüstəm Nizami oğlu',     '+994125432110', 40.570000, 50.289000),
('SCH-BA-012', '189 saylı gimnaziya',             (SELECT id FROM geo.regions WHERE code='BAB'),  5, 'Sabunçu, Bakıxanov 18',          1620, 98, 6000.00, 1993, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Süleymanova Aynur Rövşən qızı',  '+994125432111', 40.437000, 49.957000),
('SCH-BA-013', '34 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAN'),  3, 'Nəsimi, S.Vurğun 35',            1180, 76, 4400.00, 1970, 'poor',       TRUE, TRUE, FALSE, TRUE, TRUE, 'İsmayılov Elşən Vaqif oğlu',     '+994125432112', 40.401000, 49.848000),
('SCH-BA-014', '164 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAY'),  3, 'Binəqədi, 8 km',                 1520, 94, 5600.00, 1983, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Qasımova Ülkər Namiq qızı',      '+994125432113', 40.460000, 49.815000),
('SCH-BA-015', '77 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAX'),  3, 'Xətai, Əhməd Cəmil 8',           1390, 87, 5000.00, 1977, 'satisfactory', TRUE, TRUE, TRUE, TRUE, FALSE, 'Həsənov Vüqar Rafiq oğlu',       '+994125432114', 40.378000, 49.915000),
('SCH-BA-016', '11 saylı lisey',                  (SELECT id FROM geo.regions WHERE code='BAR'),  4, 'Nərimanov, Həzi Aslanov 25',     2100, 128, 8500.00, 1960, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE, 'Rzayeva Təranə Şahin qızı',      '+994125432115', 40.412000, 49.882000),
('SCH-BA-017', '56 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAS2'), 3, 'Suraxanı, Qaraçuxur',            860,  58, 3200.00, 2000, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Babayev Murad Ehtibar oğlu',     '+994125432116', 40.419000, 50.017000),
('SCH-BA-018', '220 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAZ'),  3, 'Xəzər, Buzovna qəsəbəsi',        690,  45, 2700.00, 2008, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE,  'Əliyeva Zəminə Cəmil qızı',      '+994125432117', 40.368000, 50.078000),
('SCH-BA-019', '3 saylı gimnaziya',               (SELECT id FROM geo.regions WHERE code='BAS'),  5, 'Səbail, A.Nikitin 15',           1760, 108, 6800.00, 1971, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Həsənova Sevinc Alı qızı',       '+994125432118', 40.369000, 49.832000),
('SCH-BA-020', '301 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAY2'), 3, 'Yasamal, 20 Yanvar',             1420, 90, 5300.00, 1995, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Mikayılov Teymur Kamal oğlu',    '+994125432119', 40.390000, 49.825000),
('SCH-BA-021', '39 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAN2'), 3, 'Nizami, H.Seyidbəyli 63',        1070, 68, 4000.00, 1986, 'satisfactory', TRUE, TRUE, TRUE, TRUE, FALSE, 'Cəfərova Tahirə Əkrəm qızı',     '+994125432120', 40.400000, 49.945000),
('SCH-BA-022', '126 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAG'),  3, 'Qaradağ, Ələt',                  520,  38, 2100.00, 2012, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE,  'Əhmədova Gülşən Rəşid qızı',     '+994125432121', 40.420000, 49.635000),
('SCH-BA-023', '72 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAB'),  3, 'Sabunçu, Bilgəh',                780,  52, 2900.00, 1998, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Hacıyev Orxan Tahir oğlu',       '+994125432122', 40.440000, 49.960000),
('SCH-BA-024', '264 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAY'),  3, 'Binəqədi, Xırdalan yolu',        1280, 81, 4700.00, 1989, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Əliyev Vüqar Elxan oğlu',        '+994125432123', 40.462000, 49.812000),
('SCH-BA-025', '47 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAN'),  3, 'Nəsimi, M.Hadi 41',              1460, 91, 5400.00, 1974, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE, 'Məmmədova Ramilə Sabir qızı',    '+994125432124', 40.402000, 49.847000),
('SCH-BA-026', '178 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAX'),  3, 'Xətai, Əhmədli',                 1320, 83, 4900.00, 1982, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Qurbanov Ruslan Əli oğlu',       '+994125432125', 40.380000, 49.917000),
('SCH-BA-027', '89 saylı tam orta məktəb',       (SELECT id FROM geo.regions WHERE code='BAR'),  3, 'Nərimanov, Rəsul Rza 7',         1050, 67, 3900.00, 1979, 'poor',       TRUE, TRUE, TRUE, TRUE, FALSE, 'Əliyeva Nailə Hüseyn qızı',      '+994125432126', 40.414000, 49.884000),
('SCH-BA-028', '154 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAS'),  3, 'Səbail, Bayıl yolu',             940,  63, 3500.00, 2003, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Nəsirov Cavid Faiq oğlu',        '+994125432127', 40.365000, 49.834000),
('SCH-BA-029', '33 saylı lisey',                  (SELECT id FROM geo.regions WHERE code='BAY2'), 4, 'Yasamal, A.Cavad 52',            1950, 118, 7600.00, 1967, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Rəhimov Elşad Nadir oğlu',       '+994125432128', 40.392000, 49.823000),
('SCH-BA-030', '199 saylı tam orta məktəb',      (SELECT id FROM geo.regions WHERE code='BAX'),  3, 'Xətai, Nobel prospekti',         1720, 105, 6400.00, 1984, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Məmmədli Səbinə Rövşən qızı',    '+994125432129', 40.382000, 49.919000);

-- ─── İRİ ŞƏHƏRLƏR (Gəncə, Sumqayıt, Naxçıvan, Mingəçevir, Şəki) — 25 məktəb ───
INSERT INTO infra.schools (code, name, region_id, type_id, address, student_count, teacher_count, total_area_m2, built_year, condition, has_heating, has_canteen, has_gym, has_library, has_computer_lab, director_name, phone, lat, lng) VALUES
-- Gəncə (5)
('SCH-GA-001', '1 saylı tam orta məktəb',        (SELECT id FROM geo.regions WHERE code='GA'), 3, 'Gəncə, C.Cabbarlı küç. 14',     1380, 86, 5100.00, 1962, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE, 'Bağırova Kəmalə Zakir qızı',    '+994222562100', 40.683000, 46.361000),
('SCH-GA-002', '14 saylı gimnaziya',               (SELECT id FROM geo.regions WHERE code='GA'), 5, 'Gəncə, Heydər Əliyev prospekti', 1120, 74, 4300.00, 1985, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Əliyev Fərhad Rəşid oğlu',       '+994222562101', 40.681000, 46.362000),
('SCH-GA-003', '8 saylı lisey',                    (SELECT id FROM geo.regions WHERE code='GA'), 4, 'Gəncə, N.Gəncəvi 25',            1550, 92, 5700.00, 1971, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Həsənova Aygün Tahir qızı',      '+994222562102', 40.685000, 46.358000),
('SCH-GA-004', '27 saylı tam orta məktəb',        (SELECT id FROM geo.regions WHERE code='GA'), 3, 'Gəncə, Atatürk prospekti 18',    960,  64, 3600.00, 1993, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Məmmədov Rufat Elxan oğlu',      '+994222562103', 40.680000, 46.365000),
('SCH-GA-005', '42 saylı tam orta məktəb',        (SELECT id FROM geo.regions WHERE code='GA'), 3, 'Gəncə, Şah İsmayıl Xətai 8',     1240, 78, 4600.00, 1979, 'poor',       TRUE, TRUE, TRUE, TRUE, FALSE, 'Qurbanova Lalə Namiq qızı',      '+994222562104', 40.684000, 46.356000),
-- Sumqayıt (5)
('SCH-SM-001', '6 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='SM'), 3, 'Sumqayıt, S.Vurğun 12',          1620, 98, 6000.00, 1968, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE, 'Hüseynov Kamal Fəxrəddin oğlu', '+994186553100', 40.590000, 49.669000),
('SCH-SM-002', '19 saylı gimnaziya',                (SELECT id FROM geo.regions WHERE code='SM'), 5, 'Sumqayıt, 16-cı mikrorayon',     1180, 76, 4400.00, 1987, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Əhmədova Natalya Rövşən qızı',   '+994186553101', 40.588000, 49.671000),
('SCH-SM-003', '2 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='SM'), 3, 'Sumqayıt, Heydər Əliyev 45',     1890, 118, 7000.00, 1973, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Nəsirov Elşən Akif oğlu',        '+994186553102', 40.592000, 49.667000),
('SCH-SM-004', '35 saylı tam orta məktəb',         (SELECT id FROM geo.regions WHERE code='SM'), 3, 'Sumqayıt, Cəmil Məmmədquluzadə', 980,  66, 3700.00, 1995, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE,  'Rəhimova Fatimə Tofiq qızı',     '+994186553103', 40.589000, 49.673000),
('SCH-SM-005', '24 saylı lisey',                    (SELECT id FROM geo.regions WHERE code='SM'), 4, 'Sumqayıt, 3-cü mikrorayon',      1470, 89, 5400.00, 1981, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE,'Bağırov Samir Rəşid oğlu',       '+994186553104', 40.587000, 49.670000),
-- Naxçıvan (4)
('SCH-NX-001', '1 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='NX'), 3, 'Naxçıvan, Heydər Əliyev pr.',    1320, 82, 4900.00, 1970, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Əliyev Rüstəm Vaqif oğlu',       '+994362545100', 39.209000, 45.412000),
('SCH-NX-002', '5 saylı gimnaziya',                 (SELECT id FROM geo.regions WHERE code='NX'), 5, 'Naxçıvan, C.Cabbarlı 7',         890,  58, 3300.00, 1988, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE, 'Həsənova Aynur Ramiz qızı',      '+994362545101', 39.210000, 45.414000),
('SCH-NX-003', '12 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='NX'), 3, 'Naxçıvan, Atatürk prospekti',    1050, 67, 3900.00, 1982, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Məmmədov Aliş Səbuhi oğlu',      '+994362545102', 39.208000, 45.410000),
('SCH-NX-004', '8 saylı lisey',                     (SELECT id FROM geo.regions WHERE code='NX'), 4, 'Naxçıvan, Mərkəzi küç. 22',      1180, 74, 4300.00, 1976, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE, 'Qasımova Sevinc Ənvər qızı',    '+994362545103', 39.211000, 45.413000),
-- Mingəçevir (3)
('SCH-ML-001', '3 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='ML'), 3, 'Mingəçevir, Heydər Əliyev pr.',  1240, 78, 4600.00, 1975, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Əhmədov Rövşən Kamal oğlu',      '+994242462100', 40.770000, 47.050000),
('SCH-ML-002', '11 saylı gimnaziya',                (SELECT id FROM geo.regions WHERE code='ML'), 5, 'Mingəçevir, 28 May küç.',        860,  56, 3200.00, 1990, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Səfərova Ülviyyə Ələsgər qızı', '+994242462101', 40.772000, 47.052000),
('SCH-ML-003', '7 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='ML'), 3, 'Mingəçevir, Azərbaycan 15',      720,  48, 2700.00, 2001, 'excellent',  TRUE, TRUE, TRUE, TRUE, TRUE, 'Nəbiyev Əli Sahib oğlu',         '+994242462102', 40.769000, 47.048000),
-- Şəki (3)
('SCH-SK-001', '1 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='SK'), 3, 'Şəki, M.F.Axundov küç. 12',      980,  64, 3700.00, 1972, 'satisfactory', TRUE, TRUE, TRUE, TRUE, FALSE, 'Rəhimov Samir Adil oğlu',       '+994242442100', 41.198000, 47.170000),
('SCH-SK-002', '4 saylı gimnaziya',                 (SELECT id FROM geo.regions WHERE code='SK'), 5, 'Şəki, N.Gəncəvi 8',              660,  44, 2500.00, 1995, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Əliyeva Nərminə Rasim qızı',     '+994242442101', 41.197000, 47.172000),
('SCH-SK-003', '14 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='SK'), 3, 'Şəki, Həsənbəy Zərdabi 3',       890,  58, 3300.00, 1984, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Məmmədli Tofiq Rafiq oğlu',      '+994242442102', 41.199000, 47.168000),
-- Şirvan (2)
('SCH-SR-001', '2 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='SR'), 3, 'Şirvan, Mərkəzi küç. 15',        1050, 68, 3900.00, 1978, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Bağırov Rəşid Vaqif oğlu',       '+994212462100', 39.931000, 48.921000),
('SCH-SR-002', '6 saylı gimnaziya',                 (SELECT id FROM geo.regions WHERE code='SR'), 5, 'Şirvan, 8-ci mikrorayon',        780,  52, 2900.00, 1997, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Həsənova Zöhrə Elxan qızı',      '+994212462101', 39.933000, 48.923000),
-- Lənkəran şəhəri (2) 
('SCH-LN-001', '1 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='LN'), 3, 'Lənkəran, Mərkəzi prospekt',     920,  62, 3400.00, 1976, 'satisfactory', TRUE, TRUE, TRUE, TRUE, TRUE, 'Əliyev Vüsal Namiq oğlu',       '+994252525100', 38.755000, 48.848000),
('SCH-LN-002', '9 saylı gimnaziya',                 (SELECT id FROM geo.regions WHERE code='LN'), 5, 'Lənkəran, H.Əliyev pr. 22',      740,  48, 2800.00, 2000, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Məmmədova Gülnaz Akif qızı',     '+994252525101', 38.754000, 48.850000),
-- Yevlax şəhəri (1)
('SCH-YV-001', '1 saylı tam orta məktəb',          (SELECT id FROM geo.regions WHERE code='YV'), 3, 'Yevlax, H.Əliyev prospekti',     880,  58, 3300.00, 1981, 'good',       TRUE, TRUE, TRUE, TRUE, TRUE, 'Qasımov Akif Rafiq oğlu',        '+994222462100', 40.620000, 47.150000);

-- ─── RAYONLAR (50+ rayon, hər birindən 1 məktəb — ümumi 45 məktəb) ───
-- Bir script blokda hər rayon üçün tipik məktəb yaradaq
DO $$
DECLARE
  r RECORD;
  counter INT := 0;
  student_c INT;
  teacher_c INT;
  area_val NUMERIC;
  year_val INT;
  cond_val VARCHAR;
  conditions TEXT[] := ARRAY['excellent','good','good','satisfactory','poor'];
BEGIN
  FOR r IN 
    SELECT id, code, name_az 
    FROM geo.regions 
    WHERE type_id = 2  -- yalnız rayonlar
    ORDER BY id
    LIMIT 45  -- ilk 45 rayon
  LOOP
    counter := counter + 1;
    -- Təsadüfi dəyərlər
    student_c := 400 + (RANDOM() * 800)::INT;   -- 400-1200
    teacher_c := 25 + (RANDOM() * 50)::INT;      -- 25-75
    area_val  := 1500 + (RANDOM() * 3000);        -- 1500-4500
    year_val  := 1960 + (RANDOM() * 50)::INT;    -- 1960-2010
    cond_val  := conditions[1 + (RANDOM() * 4)::INT];
    
    INSERT INTO infra.schools (
      code, name, region_id, type_id, address,
      student_count, teacher_count, total_area_m2,
      built_year, condition,
      has_heating, has_canteen, has_gym, has_library, has_computer_lab,
      director_name, phone, lat, lng
    ) VALUES (
      'SCH-' || r.code || '-001',
      '1 saylı ' || REPLACE(REPLACE(r.name_az, ' şəhəri', ''), ' rayonu', '') || ' tam orta məktəbi',
      r.id,
      3,  -- HIGH (tam orta)
      r.name_az || ', Mərkəzi küç.',
      student_c,
      teacher_c,
      area_val,
      year_val,
      cond_val,
      TRUE,  -- heating
      (RANDOM() > 0.2),  -- 80% canteen
      (RANDOM() > 0.3),  -- 70% gym
      TRUE,
      (RANDOM() > 0.4),  -- 60% computer lab
      'Müəllim ' || counter || ' Ata Oğlu',
      '+99412' || LPAD((1000000 + counter)::TEXT, 7, '0'),
      38.5 + RANDOM() * 3.5,  -- Azerbaijan latitude range
      44.5 + RANDOM() * 6.0   -- longitude range
    );
  END LOOP;
END $$;

-- ─── BİNALAR ───
-- Hər məktəb üçün 1 əsas bina
INSERT INTO infra.buildings (school_id, building_type, floors, area_m2, year_built, classroom_count, structural_condition)
SELECT 
  id,
  'main',
  CASE WHEN total_area_m2 > 5000 THEN 4 WHEN total_area_m2 > 3000 THEN 3 ELSE 2 END,
  total_area_m2,
  built_year,
  (student_count / 25)::INT,  -- 25 şagird / sinif
  CASE condition
    WHEN 'excellent' THEN 9.0 + RANDOM()
    WHEN 'good' THEN 7.0 + RANDOM() * 2
    WHEN 'satisfactory' THEN 5.0 + RANDOM() * 2
    WHEN 'poor' THEN 3.0 + RANDOM() * 2
    ELSE 1.0 + RANDOM() * 2
  END
FROM infra.schools;

-- ─── Yoxlama ───
\echo ''
\echo '═══ MƏKTƏB STATİSTİKASI ═══'
SELECT 'Məktəb tipləri: ' || COUNT(*) FROM infra.school_types
UNION ALL
SELECT 'Məktəblər (cəmi): ' || COUNT(*) FROM infra.schools
UNION ALL
SELECT 'Binalar: ' || COUNT(*) FROM infra.buildings;

\echo ''
\echo '═══ Rayon üzrə məktəb sayı (top 10) ═══'
SELECT r.name_az AS "Rayon", COUNT(s.id) AS "Məktəb sayı"
FROM geo.regions r
LEFT JOIN infra.schools s ON s.region_id = r.id
GROUP BY r.id, r.name_az
HAVING COUNT(s.id) > 0
ORDER BY COUNT(s.id) DESC
LIMIT 10;

\echo ''
\echo '═══ Məktəb vəziyyəti ═══'
SELECT condition AS "Vəziyyət", COUNT(*) AS "Sayı"
FROM infra.schools
GROUP BY condition
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ YEKUN ═══'
SELECT 
  COUNT(*) AS total_schools,
  SUM(student_count) AS total_students,
  SUM(teacher_count) AS total_teachers,
  ROUND(AVG(total_area_m2), 0) AS avg_area
FROM infra.schools;
