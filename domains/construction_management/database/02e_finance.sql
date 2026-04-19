-- ═══════════════════════════════════════════════════════════════
-- 02e: Maliyyə — Büdcələr (2023-2026)
-- ═══════════════════════════════════════════════════════════════

-- ─── BÜDCƏLƏR ───
-- 4 il × 5 kateqoriya × (bəzi rayonlar üçün spesifik) = ~60 sətir

-- 1. ÜMUMİ RESPUBLİKA BÜDCƏLƏRI (region_id = NULL, hamı üçün)
INSERT INTO finance.budgets (fiscal_year, region_id, category, allocated_amount, spent_amount, source) VALUES
-- 2023
(2023, NULL, 'current',       25000000, 24200000, 'state'),
(2023, NULL, 'capital',       65000000, 61800000, 'state'),
(2023, NULL, 'construction', 180000000, 172500000, 'state'),
(2023, NULL, 'emergency',     15000000,  11200000, 'state'),
(2023, NULL, 'salaries',      45000000,  44500000, 'state'),
-- 2024
(2024, NULL, 'current',       28000000, 26800000, 'state'),
(2024, NULL, 'capital',       72000000, 68400000, 'state'),
(2024, NULL, 'construction', 195000000, 188700000, 'state'),
(2024, NULL, 'emergency',     18000000,  14500000, 'state'),
(2024, NULL, 'salaries',      48000000,  47800000, 'state'),
-- 2025
(2025, NULL, 'current',       32000000, 18600000, 'state'),
(2025, NULL, 'capital',       82000000, 45200000, 'state'),
(2025, NULL, 'construction', 220000000, 128300000, 'state'),
(2025, NULL, 'emergency',     20000000,   8900000, 'state'),
(2025, NULL, 'salaries',      52000000,  32100000, 'state'),
-- 2026 (plan, hələ başlamayıb)
(2026, NULL, 'current',       35000000,         0, 'state'),
(2026, NULL, 'capital',       90000000,         0, 'state'),
(2026, NULL, 'construction', 245000000,         0, 'state'),
(2026, NULL, 'emergency',     22000000,         0, 'state'),
(2026, NULL, 'salaries',      55000000,         0, 'state');

-- 2. XÜSUSİ RAYON BÜDCƏLƏRI (böyük şəhərlər üçün əlavə)
-- Bakı üçün əlavə büdcə
INSERT INTO finance.budgets (fiscal_year, region_id, category, allocated_amount, spent_amount, source) VALUES
(2024, (SELECT id FROM geo.regions WHERE code='BA'), 'construction', 35000000, 33200000, 'municipal'),
(2025, (SELECT id FROM geo.regions WHERE code='BA'), 'construction', 42000000, 24800000, 'municipal'),
(2026, (SELECT id FROM geo.regions WHERE code='BA'), 'construction', 48000000,        0, 'municipal');

-- Qarabağ bərpası üçün xüsusi büdcə
INSERT INTO finance.budgets (fiscal_year, region_id, category, allocated_amount, spent_amount, source) VALUES
(2023, (SELECT id FROM geo.regions WHERE code='AG'), 'construction', 85000000, 78400000, 'state'),
(2024, (SELECT id FROM geo.regions WHERE code='AG'), 'construction', 95000000, 89200000, 'state'),
(2023, (SELECT id FROM geo.regions WHERE code='FZ'), 'construction', 72000000, 68100000, 'state'),
(2024, (SELECT id FROM geo.regions WHERE code='FZ'), 'construction', 82000000, 76500000, 'state'),
(2023, (SELECT id FROM geo.regions WHERE code='LC'), 'construction', 58000000, 52300000, 'state'),
(2024, (SELECT id FROM geo.regions WHERE code='LC'), 'construction', 68000000, 61400000, 'state'),
(2025, (SELECT id FROM geo.regions WHERE code='KD'), 'construction', 45000000, 24800000, 'state'),
(2025, (SELECT id FROM geo.regions WHERE code='CB'), 'construction', 52000000, 28300000, 'state');

-- Grant (beynəlxalq təşkilatlardan)
INSERT INTO finance.budgets (fiscal_year, region_id, category, allocated_amount, spent_amount, source) VALUES
(2024, NULL, 'capital', 12000000, 11200000, 'grant'),  -- Dünya Bankı
(2025, NULL, 'capital', 15000000,  8400000, 'grant');  -- ADB

-- ─── YOXLAMA ───
\echo ''
\echo '═══ BÜDCƏ STATİSTİKASI ═══'
SELECT 'Büdcə sətirləri: ' || COUNT(*) FROM finance.budgets;

\echo ''
\echo '═══ İl üzrə ümumi büdcə ═══'
SELECT 
  fiscal_year AS "İl",
  ROUND(SUM(allocated_amount)/1000000, 1) AS "Ayrılmış (mln AZN)",
  ROUND(SUM(spent_amount)/1000000, 1) AS "Xərclənmiş (mln AZN)",
  ROUND(100.0 * SUM(spent_amount) / NULLIF(SUM(allocated_amount), 0), 1) AS "İcra %"
FROM finance.budgets
GROUP BY fiscal_year
ORDER BY fiscal_year;

\echo ''
\echo '═══ Kateqoriya üzrə ═══'
SELECT 
  category AS "Kateqoriya",
  COUNT(*) AS "Sətir",
  ROUND(SUM(allocated_amount)/1000000, 1) AS "Cəmi (mln AZN)"
FROM finance.budgets
GROUP BY category
ORDER BY SUM(allocated_amount) DESC;

\echo ''
\echo '═══ Mənbə üzrə ═══'
SELECT 
  source AS "Mənbə",
  COUNT(*) AS "Sətir",
  ROUND(SUM(allocated_amount)/1000000, 1) AS "Cəmi (mln AZN)"
FROM finance.budgets
GROUP BY source
ORDER BY SUM(allocated_amount) DESC;
