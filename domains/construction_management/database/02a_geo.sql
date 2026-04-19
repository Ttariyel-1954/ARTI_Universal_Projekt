-- ═══════════════════════════════════════════════════════════════
-- 02a: Coğrafi data — 77 real Azərbaycan rayonu
-- ═══════════════════════════════════════════════════════════════

-- ─── Region tipləri ───
INSERT INTO geo.region_types (code, name_az, priority) VALUES
('CITY',           'Respublika tabeli şəhər',  1),
('DISTRICT',       'Rayon',                     2),
('BAKU_DISTRICT',  'Bakı rayonu',               1),
('AUTONOMOUS',     'Muxtar Respublika',         1);

-- ─── 77 Azərbaycan rayonu ───
INSERT INTO geo.regions (code, name_az, type_id, population, area_km2, center_lat, center_lng) VALUES
-- Respublika tabeli şəhərlər (11)
('BA',  'Bakı şəhəri',              1, 2300500,  2140.00, 40.409264, 49.867092),
('GA',  'Gəncə şəhəri',             1,  335600,   110.00, 40.682799, 46.360585),
('SM',  'Sumqayıt şəhəri',          1,  345300,    83.00, 40.589730, 49.668685),
('ML',  'Mingəçevir şəhəri',        1,  106300,   118.00, 40.770600, 47.049700),
('SK',  'Şəki şəhəri',              1,   68800,    20.00, 41.197500, 47.170700),
('YV',  'Yevlax şəhəri',            1,   61100,    80.00, 40.619800, 47.150300),
('SR',  'Şirvan şəhəri',            1,   84300,    34.00, 39.931300, 48.921000),
('LN',  'Lənkəran şəhəri',          1,   51400,    36.00, 38.754700, 48.847500),
('NF',  'Naftalan şəhəri',          1,    9700,    30.00, 40.504500, 46.832100),
('XB',  'Xankəndi şəhəri',          1,   56400,    26.00, 39.826700, 46.767100),
('ST',  'Stepanakert (Xankəndi)',   1,       1,    10.00, 39.800000, 46.750000),

-- Bakı rayonları (12)
('ABS', 'Abşeron rayonu',           2,  245500,  1360.00, 40.500000, 49.700000),
('BAY', 'Binəqədi rayonu',          3,  265800,   173.00, 40.455800, 49.819000),
('BAG', 'Qaradağ rayonu',           3,  129600,  1080.00, 40.422800, 49.636800),
('BAN', 'Nəsimi rayonu',            3,  215100,    11.00, 40.398900, 49.845700),
('BAR', 'Nərimanov rayonu',         3,  188700,    21.00, 40.409200, 49.879000),
('BAS', 'Səbail rayonu',            3,  104400,    32.00, 40.367700, 49.829800),
('BAX', 'Xətai rayonu',             3,  299200,    30.00, 40.376100, 49.912800),
('BAZ', 'Xəzər rayonu',             3,  169600,   342.00, 40.365700, 50.075700),
('BAP', 'Pirallahı rayonu',         3,   22200,    13.00, 40.569700, 50.288600),
('BAS2','Suraxanı rayonu',          3,  225800,    125.00, 40.417000, 50.015000),
('BAY2','Yasamal rayonu',           3,  244500,    21.00, 40.387900, 49.827300),
('BAN2','Nizami rayonu',            3,  202100,    22.00, 40.397600, 49.942700),

-- Aran iqtisadi rayonu (15)
('AG',  'Ağdam rayonu',             2,  204800,  1094.00, 39.986100, 46.929500),
('AGC', 'Ağcabədi rayonu',          2,  131800,  1760.00, 40.053100, 47.458700),
('AGS', 'Ağsu rayonu',              2,   83400,  1010.00, 40.570800, 48.398500),
('BX',  'Beyləqan rayonu',          2,   99200,  1130.00, 39.771700, 47.621700),
('BR',  'Bərdə rayonu',             2,  161800,   957.00, 40.370500, 47.127800),
('BS',  'Biləsuvar rayonu',         2,   95300,  1360.00, 39.459700, 48.548300),
('GB',  'Göyçay rayonu',            2,  115800,   740.00, 40.650200, 47.744500),
('HC',  'Hacıqabul rayonu',         2,   76500,  1640.00, 40.039200, 48.918400),
('IM',  'İmişli rayonu',            2,  124800,  1840.00, 39.869400, 48.068900),
('KR',  'Kürdəmir rayonu',          2,  112700,  1700.00, 40.349400, 48.144200),
('NG',  'Neftçala rayonu',          2,   85800,  1452.00, 39.386400, 49.238700),
('SB',  'Saatlı rayonu',            2,  102500,  1180.00, 39.910400, 48.362500),
('SL',  'Salyan rayonu',            2,  139500,  1790.00, 39.579200, 48.971900),
('UC',  'Ucar rayonu',              2,   88800,   840.00, 40.508600, 47.651500),
('ZD',  'Zərdab rayonu',            2,   59300,   858.00, 40.214900, 47.715800),

-- Abşeron-Xızı iqtisadi rayonu (3 əlavə)
('XZ',  'Xızı rayonu',              2,   17900,  1850.00, 40.910300, 49.072000),
('SK2', 'Siyəzən rayonu',           2,   41200,   698.00, 41.077200, 49.111200),
('QB',  'Quba rayonu',              2,  172100,  2610.00, 41.361300, 48.512300),

-- Dağlıq Şirvan iqtisadi rayonu (5)
('QZ',  'Qobustan rayonu',          2,   46300,  1370.00, 40.534400, 48.926100),
('IS',  'İsmayıllı rayonu',         2,   86100,  2074.00, 40.786900, 48.152700),
('SB2', 'Şamaxı rayonu',            2,  111400,  1667.00, 40.631000, 48.638500),
('AS',  'Astara rayonu',            2,  107500,   616.00, 38.459200, 48.873800),

-- Quba-Xaçmaz iqtisadi rayonu (əlavə)
('QS',  'Qusar rayonu',             2,   95400,  1542.00, 41.426700, 48.437100),
('XC',  'Xaçmaz rayonu',            2,  177400,  1050.00, 41.461600, 48.801700),
('QU',  'Qax rayonu',               2,   57500,  1494.00, 41.419500, 46.929000),
('OG',  'Oğuz rayonu',              2,   43900,  1109.00, 41.072700, 47.465500),
('YV2', 'Yevlax rayonu',            2,  131200,  1540.00, 40.617800, 47.145400),

-- Gəncə-Qazax iqtisadi rayonu (9)
('AH',  'Ağstafa rayonu',           2,   87800,   1498.00, 41.119600, 45.447800),
('AK',  'Ağkənd (Gədəbəy)',         2,       1,     11.00, 40.570000, 45.810000),
('DS',  'Daşkəsən rayonu',          2,   34400,   798.00, 40.515000, 46.079200),
('GE',  'Gədəbəy rayonu',           2,   99300,  1287.00, 40.569700, 45.813900),
('GL',  'Goranboy rayonu',          2,   97700,  1760.00, 40.610100, 46.788900),
('GY',  'Göygöl rayonu',            2,   62700,   999.00, 40.588000, 46.328300),
('KZ',  'Qazax rayonu',             2,   93300,   699.00, 41.096400, 45.369200),
('SD',  'Samux rayonu',             2,   58200,  1452.00, 40.758400, 46.414600),
('TV',  'Tovuz rayonu',             2,  168700,  1900.00, 40.996100, 45.634800),

-- Şəki-Zaqatala iqtisadi rayonu (4)
('BL',  'Balakən rayonu',           2,   95500,   917.00, 41.705000, 46.404200),
('QB2', 'Qəbələ rayonu',            2,  106500,  1549.00, 40.980700, 47.845400),
('ZQ',  'Zaqatala rayonu',          2,  128500,  1348.00, 41.630959, 46.642954),

-- Lənkəran-Astara iqtisadi rayonu (4)
('MS',  'Masallı rayonu',           2,  217900,  721.00,  39.033600, 48.657300),
('YR',  'Yardımlı rayonu',          2,   63700,   673.00, 38.908300, 48.252500),
('LK',  'Lənkəran rayonu',          2,  201400,  1539.00, 38.752500, 48.854400),
('LR',  'Lerik rayonu',             2,   81700,  1083.00, 38.773100, 48.415000),

-- Şirvan-Salyan iqtisadi rayonu
('SB3', 'Sabirabad rayonu',         2,  171300,  1470.00, 40.000300, 48.479700),

-- Yuxarı Qarabağ iqtisadi rayonu (5)
('XN',  'Xocavənd rayonu',          2,   45300,   1458.00, 39.786700, 46.998700),
('KH',  'Xocalı rayonu',            2,   26700,   938.00,  39.916700, 46.800000),
('TR',  'Tərtər rayonu',            2,  106500,   957.00,  40.344800, 46.931700),
('KD',  'Kəlbəcər rayonu',          2,   94500,  3054.00,  40.107200, 46.036700),
('LC',  'Laçın rayonu',             2,   73800,  1835.00,  39.641600, 46.544700),

-- Kəlbəcər-Laçın iqtisadi rayonu əlavə (3)
('QR',  'Qubadlı rayonu',           2,   36100,   802.00,  39.344300, 46.578600),
('ZG',  'Zəngilan rayonu',          2,   43700,   707.00,  39.085400, 46.648700),
('CB',  'Cəbrayıl rayonu',          2,   75200,  1050.00,  39.399400, 47.025300),
('FZ',  'Füzuli rayonu',            2,  133400,  1386.00,  39.600600, 47.143500),

-- Naxçıvan Muxtar Respublikası (8)
('NX',  'Naxçıvan şəhəri',          4,   89900,   192.00, 39.209170, 45.412220),
('NXB', 'Babək rayonu',             2,   76900,   751.00, 39.149500, 45.408100),
('NXO', 'Ordubad rayonu',           2,   49100,   988.00, 38.899200, 46.022200),
('NXC', 'Culfa rayonu',             2,   47500,   997.00, 38.957000, 45.631700),
('NXK', 'Kəngərli rayonu',          2,   34600,   710.00, 39.450600, 45.155000),
('NXS', 'Sədərək rayonu',           2,   18500,   156.00, 39.700700, 44.884500),
('NXM', 'Şahbuz rayonu',            2,   25400,   846.00, 39.406900, 45.566700),
('NXR', 'Şərur rayonu',             2,  114200,   849.00, 39.555400, 44.986100);

-- ─── Bir neçə nümunə yaşayış məntəqəsi ───
INSERT INTO geo.settlements (region_id, name_az, settlement_type, population, is_district_center) VALUES
-- Bakı üçün
((SELECT id FROM geo.regions WHERE code='BA'), 'Bakı şəhər mərkəzi', 'city', 2300500, TRUE),
-- Gəncə
((SELECT id FROM geo.regions WHERE code='GA'), 'Gəncə şəhər mərkəzi', 'city', 335600, TRUE),
-- Naxçıvan
((SELECT id FROM geo.regions WHERE code='NX'), 'Naxçıvan şəhər mərkəzi', 'city', 89900, TRUE),
-- Sumqayıt
((SELECT id FROM geo.regions WHERE code='SM'), 'Sumqayıt şəhər mərkəzi', 'city', 345300, TRUE),
-- Bir neçə rayon mərkəzi qəsəbə
((SELECT id FROM geo.regions WHERE code='AG'),  'Ağdam şəhəri',    'town', 45000, TRUE),
((SELECT id FROM geo.regions WHERE code='BR'),  'Bərdə şəhəri',    'town', 38000, TRUE),
((SELECT id FROM geo.regions WHERE code='QB'),  'Quba şəhəri',     'town', 41000, TRUE),
((SELECT id FROM geo.regions WHERE code='LK'),  'Lənkəran şəhəri', 'town', 85000, TRUE),
((SELECT id FROM geo.regions WHERE code='ZQ'),  'Zaqatala şəhəri', 'town', 20000, TRUE),
((SELECT id FROM geo.regions WHERE code='TV'),  'Tovuz şəhəri',    'town', 15500, TRUE);

-- ─── Yoxlama ───
SELECT 'Region tipləri: ' || COUNT(*)::text AS result FROM geo.region_types
UNION ALL
SELECT '77 rayon: ' || COUNT(*)::text FROM geo.regions
UNION ALL
SELECT 'Yaşayış məntəqələri: ' || COUNT(*)::text FROM geo.settlements;

-- Rayonlar iqtisadi bölgə üzrə
\echo ''
\echo '═══ Rayon sayı növ üzrə ═══'
SELECT rt.name_az AS "Növ", COUNT(r.id) AS "Sayı"
FROM geo.region_types rt
LEFT JOIN geo.regions r ON r.type_id = rt.id
GROUP BY rt.id, rt.name_az
ORDER BY rt.priority;
