-- ═══════════════════════════════════════════════════════════════
-- 03b: Əməliyyatlar — Xərclər + Material hərəkəti + İnvoys
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. XƏRCLƏR (hər layihə üçün 20-70 xərc) ───
DO $$
DECLARE
  p RECORD;
  expense_count INT;
  expense_counter INT := 0;
  i INT;
  category_v TEXT;
  subcategory_v TEXT;
  amount_v NUMERIC;
  expense_date_v DATE;
  approver_id INT;
  categories TEXT[] := ARRAY['material','labor','transport','utility','equipment','other'];
  material_subs TEXT[] := ARRAY['Sement','Kərpic','Armatur','Dam materialı','Boya','Pəncərə','Elektrik','Santexnika'];
  labor_subs TEXT[] := ARRAY['Briqada iş haqqı','Mütəxəssis haqqı','Əlavə iş haqqı','Mühafizə xidməti'];
  transport_subs TEXT[] := ARRAY['Yük daşınması','Yanacaq','Avtomobil icarəsi','Kran icarəsi'];
  utility_subs TEXT[] := ARRAY['Elektrik','Qaz','Su','İnternet'];
  equipment_subs TEXT[] := ARRAY['Avadanlıq icarəsi','Alətlər','Təhlükəsizlik'];
BEGIN
  -- Random işçi tap (maliyyə şöbəsindən)
  FOR p IN SELECT id, status, start_date, actual_start, planned_budget, actual_cost 
           FROM construction.projects 
           WHERE actual_cost > 0 LOOP
    
    -- Xərclərin sayı layihə ölçüsünə görə
    expense_count := CASE 
      WHEN p.planned_budget > 1000000 THEN 50 + (RANDOM() * 30)::INT  -- 50-80 xərc
      WHEN p.planned_budget > 200000  THEN 25 + (RANDOM() * 20)::INT  -- 25-45
      WHEN p.planned_budget > 50000   THEN 10 + (RANDOM() * 15)::INT  -- 10-25
      ELSE                                  5 + (RANDOM() * 10)::INT   -- 5-15
    END;
    
    FOR i IN 1..expense_count LOOP
      -- Kateqoriya (paylanma: 45% material, 30% labor, 10% transport, 5% utility, 7% equipment, 3% other)
      category_v := CASE 
        WHEN RANDOM() < 0.45 THEN 'material'
        WHEN RANDOM() < 0.75 THEN 'labor'
        WHEN RANDOM() < 0.85 THEN 'transport'
        WHEN RANDOM() < 0.90 THEN 'utility'
        WHEN RANDOM() < 0.97 THEN 'equipment'
        ELSE 'other'
      END;
      
      -- Subkateqoriya
      subcategory_v := CASE category_v
        WHEN 'material'  THEN material_subs[1 + (RANDOM() * (array_length(material_subs,1)-1))::INT]
        WHEN 'labor'     THEN labor_subs[1 + (RANDOM() * (array_length(labor_subs,1)-1))::INT]
        WHEN 'transport' THEN transport_subs[1 + (RANDOM() * (array_length(transport_subs,1)-1))::INT]
        WHEN 'utility'   THEN utility_subs[1 + (RANDOM() * (array_length(utility_subs,1)-1))::INT]
        WHEN 'equipment' THEN equipment_subs[1 + (RANDOM() * (array_length(equipment_subs,1)-1))::INT]
        ELSE 'Digər xərclər'
      END;
      
      -- Məbləğ (total_cost / expense_count, amma variasiya ilə)
      amount_v := (p.actual_cost / expense_count) * (0.3 + RANDOM() * 1.8);
      amount_v := ROUND(amount_v, 2);
      
      -- Tarix (actual_start-dan start_date+180 gün-ə qədər)
      expense_date_v := COALESCE(p.actual_start, p.start_date) + (RANDOM() * 200)::INT;
      
      -- Təsdiqləyən
      SELECT id INTO approver_id FROM hr.employees 
        WHERE position_id IN (SELECT id FROM hr.positions 
                              WHERE code IN ('CHIEF_ACC','DEPT_HEAD','DEPUTY_DIR'))
        ORDER BY RANDOM() LIMIT 1;
      
      INSERT INTO finance.expenses (
        project_id, expense_date, category, subcategory, amount,
        vat_included, description, approved_by, invoice_number
      ) VALUES (
        p.id, expense_date_v, category_v, subcategory_v, amount_v,
        TRUE,
        subcategory_v || ' xərci - ' || TO_CHAR(expense_date_v, 'MM/YYYY'),
        approver_id,
        'INV-' || TO_CHAR(expense_date_v, 'YYYY') || '-' || LPAD((expense_counter * 17 + 1000)::TEXT, 6, '0')
      );
      
      expense_counter := expense_counter + 1;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE '✅ % xərc sətri yaradıldı', expense_counter;
END $$;

-- ─── 2. MATERİAL HƏRƏKƏTİ (anbara daxil olma + layihəyə çıxış) ───
DO $$
DECLARE
  w RECORD;
  m RECORD;
  p RECORD;
  trans_count INT := 0;
  i INT;
  employee_id INT;
  qty_v NUMERIC;
  price_v NUMERIC;
  total_v NUMERIC;
  trans_date TIMESTAMP;
BEGIN
  -- A) Anbara DAXİL OLMA (1,500 əməliyyat — təchizat)
  FOR i IN 1..1500 LOOP
    SELECT id INTO w.id FROM inventory.warehouses ORDER BY RANDOM() LIMIT 1;
    SELECT id, standard_price, unit INTO m.id, price_v, m.unit 
      FROM inventory.materials ORDER BY RANDOM() LIMIT 1;
    SELECT id INTO employee_id FROM hr.employees 
      WHERE position_id IN (SELECT id FROM hr.positions WHERE code IN ('FOREMAN','CONSTRUCTOR'))
      ORDER BY RANDOM() LIMIT 1;
    
    qty_v := 50 + RANDOM() * 500;  -- 50-550 vahid
    total_v := ROUND(qty_v * price_v, 2);
    trans_date := NOW() - (RANDOM() * 365 * 3)::INT * INTERVAL '1 day';
    
    INSERT INTO inventory.material_transactions (
      transaction_type, warehouse_id, material_id, quantity, unit_price, total_amount,
      transaction_date, performed_by, reference_number
    ) VALUES (
      'in', w.id, m.id, qty_v, price_v, total_v,
      trans_date, employee_id, 'IN-' || TO_CHAR(trans_date, 'YYYY-MM') || '-' || LPAD(i::TEXT, 5, '0')
    );
    trans_count := trans_count + 1;
  END LOOP;
  
  RAISE NOTICE '✅ % anbar daxilolması yaradıldı', trans_count;
  
  trans_count := 0;
  
  -- B) Layihəyə ÇIXIŞ (6,500 əməliyyat — layihələrə material göndərmə)
  FOR i IN 1..6500 LOOP
    -- Aktiv və ya tamamlanmış layihələr
    SELECT id, region_id, actual_start INTO p.id, p.region_id, p.actual_start 
      FROM construction.projects 
      WHERE status IN ('completed','in_progress')
        AND actual_start IS NOT NULL
      ORDER BY RANDOM() LIMIT 1;
    
    -- O layihənin rayonunda olan anbar (varsa)
    SELECT id INTO w.id FROM inventory.warehouses 
      WHERE region_id = p.region_id 
      ORDER BY RANDOM() LIMIT 1;
    -- Yoxsa Bakı mərkəzi
    IF w.id IS NULL THEN
      SELECT id INTO w.id FROM inventory.warehouses WHERE is_central = TRUE LIMIT 1;
    END IF;
    
    SELECT id, standard_price, unit INTO m.id, price_v, m.unit 
      FROM inventory.materials ORDER BY RANDOM() LIMIT 1;
    SELECT id INTO employee_id FROM hr.employees 
      WHERE position_id IN (SELECT id FROM hr.positions WHERE code IN ('FOREMAN','CONSTRUCTOR','PROJECT_MGR'))
      ORDER BY RANDOM() LIMIT 1;
    
    qty_v := 5 + RANDOM() * 100;  -- 5-105 vahid
    total_v := ROUND(qty_v * price_v, 2);
    trans_date := p.actual_start + (RANDOM() * 180)::INT * INTERVAL '1 day';
    
    INSERT INTO inventory.material_transactions (
      transaction_type, warehouse_id, project_id, material_id, quantity, unit_price, total_amount,
      transaction_date, performed_by, reference_number
    ) VALUES (
      'out', w.id, p.id, m.id, qty_v, price_v, total_v,
      trans_date, employee_id, 'OUT-' || TO_CHAR(trans_date, 'YYYY-MM') || '-' || LPAD(i::TEXT, 5, '0')
    );
    trans_count := trans_count + 1;
  END LOOP;
  
  RAISE NOTICE '✅ % layihəyə çıxış yaradıldı', trans_count;
END $$;

-- ─── 3. HESAB-FAKTURALAR (invoices) ───
-- Hər layihə üçün 1-3 invoice
DO $$
DECLARE
  p RECORD;
  inv_count INT;
  inv_counter INT := 0;
  i INT;
  issue_date_v DATE;
  due_date_v DATE;
  amount_v NUMERIC;
  status_v TEXT;
BEGIN
  FOR p IN SELECT id, contractor_id, actual_cost, status, actual_start, actual_end 
           FROM construction.projects 
           WHERE actual_cost > 0 AND contractor_id IS NOT NULL LOOP
    
    inv_count := 1 + (RANDOM() * 2)::INT;
    
    FOR i IN 1..inv_count LOOP
      issue_date_v := COALESCE(p.actual_start, CURRENT_DATE - 365) + (RANDOM() * 200)::INT;
      due_date_v := issue_date_v + 30;
      amount_v := ROUND((p.actual_cost / inv_count) * (0.8 + RANDOM() * 0.4), 2);
      
      status_v := CASE 
        WHEN p.status = 'completed' THEN 'paid'
        WHEN p.status = 'in_progress' AND RANDOM() > 0.3 THEN 'paid'
        WHEN RANDOM() > 0.5 THEN 'approved'
        ELSE 'pending'
      END;
      
      inv_counter := inv_counter + 1;
      
      INSERT INTO finance.invoices (
        invoice_number, contractor_id, project_id, issue_date, due_date, amount, status
      ) VALUES (
        'INV-' || TO_CHAR(issue_date_v, 'YYYY') || '-' || LPAD(inv_counter::TEXT, 5, '0'),
        p.contractor_id, p.id, issue_date_v, due_date_v, amount_v, status_v
      );
      
      -- Əgər paid, payment da əlavə et
      IF status_v = 'paid' THEN
        INSERT INTO finance.payments (
          invoice_id, contractor_id, payment_date, amount, method, status
        ) VALUES (
          currval('finance.invoices_id_seq'),
          p.contractor_id,
          issue_date_v + (10 + RANDOM() * 25)::INT,
          amount_v,
          'bank_transfer',
          'completed'
        );
      END IF;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE '✅ % invoice yaradıldı', inv_counter;
END $$;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ ƏMƏLIYYATLAR STATİSTİKASI ═══'
SELECT 'Xərclər: '          || COUNT(*) FROM finance.expenses
UNION ALL
SELECT 'Material hərəkəti: ' || COUNT(*) FROM inventory.material_transactions
UNION ALL
SELECT 'İnvoyslər: '        || COUNT(*) FROM finance.invoices
UNION ALL
SELECT 'Ödənişlər: '        || COUNT(*) FROM finance.payments;

\echo ''
\echo '═══ Xərc kateqoriyası ═══'
SELECT 
  category AS "Kateqoriya",
  COUNT(*) AS "Əməliyyat",
  ROUND(SUM(amount)/1000000, 2) AS "Cəmi (mln AZN)"
FROM finance.expenses
GROUP BY category
ORDER BY SUM(amount) DESC;

\echo ''
\echo '═══ Material hərəkət tipi ═══'
SELECT 
  transaction_type AS "Tip",
  COUNT(*) AS "Əməliyyat",
  ROUND(SUM(total_amount)/1000000, 2) AS "Cəmi (mln AZN)"
FROM inventory.material_transactions
GROUP BY transaction_type;

\echo ''
\echo '═══ İnvoys statusu ═══'
SELECT status AS "Status", COUNT(*) AS "Sayı", ROUND(SUM(amount)/1000000, 2) AS "Cəmi (mln AZN)"
FROM finance.invoices
GROUP BY status
ORDER BY COUNT(*) DESC;

\echo ''
\echo '═══ Ən çox xərc edilən 5 layihə ═══'
SELECT 
  p.project_code AS "Kod",
  LEFT(p.name, 50) AS "Ad",
  COUNT(e.id) AS "Xərc sayı",
  ROUND(SUM(e.amount)/1000, 1) AS "Cəmi (K AZN)"
FROM construction.projects p
JOIN finance.expenses e ON e.project_id = p.id
GROUP BY p.id, p.project_code, p.name
ORDER BY SUM(e.amount) DESC
LIMIT 5;
