-- ═══════════════════════════════════════════════════════════════
-- 02d: Maddi-Texniki Baza
-- 10 kateqoriya + 200 material + 15 anbar + avadanlıq
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. MATERİAL KATEQORİYALARI (10) ───
INSERT INTO inventory.material_categories (code, name_az, icon) VALUES
('CEMENT',    'Sement və qarışıqlar',        '🏗️'),
('BRICK',     'Kərpic və bloklar',            '🧱'),
('METAL',     'Metal konstruksiyalar',        '⚙️'),
('WOOD',      'Ağac materiallar',             '🪵'),
('GLASS',     'Şüşə və pəncərələr',           '🪟'),
('ROOF',      'Dam örtükləri',                '🏠'),
('PAINT',     'Boyalar və laklar',            '🎨'),
('ELECTRIC',  'Elektrik materialları',        '⚡'),
('PLUMBING',  'Santexnika',                   '🚰'),
('FINISH',    'Pərdahlama materialları',      '✨');

-- ─── 2. 200 MATERİAL ───
-- Hər kateqoriyadan real material nümunələri
-- Əsas materiallar əl ilə, sonra random

-- SEMENT və qarışıqlar (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-CEM-M400', 'Sement M400, Qaradağ',                   1, 'kg',  0.22, 5000,  'Qaradağ Sement ASC'),
('MAT-CEM-M500', 'Sement M500, Qaradağ',                   1, 'kg',  0.28, 5000,  'Qaradağ Sement ASC'),
('MAT-CEM-M600', 'Sement M600, premium',                   1, 'kg',  0.35, 2000,  'Holcim Azərbaycan'),
('MAT-SND-QUM',  'Tikinti qumu, Xəzər',                    1, 'ton', 18.00, 100,   'Xəzər Qum MMC'),
('MAT-SND-YUB',  'Yuyulmuş qum',                           1, 'ton', 25.00, 50,    'Xəzər Qum MMC'),
('MAT-GRL-QIR',  'Qırma (şəbhə 5-20mm)',                   1, 'ton', 22.00, 100,   'Qaradağ Daş MMC'),
('MAT-GRL-IRI',  'İri qırma (20-40mm)',                    1, 'ton', 24.00, 80,    'Qaradağ Daş MMC'),
('MAT-MRT-CEM',  'Hazır sement məhlulu M100',              1, 'm3',  85.00, 20,    'Bakı Beton MMC'),
('MAT-MRT-CON',  'Hazır beton B25',                        1, 'm3',  120.00, 30,   'Bakı Beton MMC'),
('MAT-MRT-B35',  'Yüksək dayanıqlı beton B35',             1, 'm3',  145.00, 20,   'Bakı Beton MMC'),
('MAT-MRT-RDY',  'Hazır məhlul (gipsli)',                  1, 'kg',  0.45, 1000,   'Bakı Gips MMC'),
('MAT-MRT-YAP',  'Yapışdırıcı qarışıq (plitə üçün)',       1, 'kg',  1.20, 500,    'Knauf Azərbaycan'),
('MAT-MRT-SEM',  'Semsiz dözümlü yapışdırıcı',             1, 'kg',  2.80, 300,    'Ceresit Azərbaycan'),
('MAT-PLS-GIP',  'Gips suvağı',                            1, 'kg',  0.38, 2000,   'Knauf Azərbaycan'),
('MAT-PLS-CEM',  'Sement suvağı',                          1, 'kg',  0.25, 3000,   'Bakı Gips MMC');

-- KƏRPİC (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-BRK-RED',  'Qırmızı kərpic, tam',                    2, 'adet', 0.28, 10000, 'Abşeron Kərpic MMC'),
('MAT-BRK-HOL',  'Boşluqlu kərpic',                        2, 'adet', 0.32, 10000, 'Abşeron Kərpic MMC'),
('MAT-BRK-WHT',  'Ağ kərpic (silikat)',                    2, 'adet', 0.35, 8000,  'Sumqayıt Silikat MMC'),
('MAT-BRK-FAC',  'Üzlük kərpic, dekorativ',                2, 'adet', 0.55, 5000,  'Gəncə Sənaye MMC'),
('MAT-BRK-REF',  'Oda davamlı kərpic',                     2, 'adet', 1.20, 500,   'Zaqatala Keramik'),
('MAT-BLK-GAS',  'Qazbeton bloku 600x200x300mm',           2, 'adet', 3.50, 2000,  'YTONG Azərbaycan'),
('MAT-BLK-AER',  'Aerobeton bloku',                        2, 'adet', 3.80, 2000,  'YTONG Azərbaycan'),
('MAT-BLK-KER',  'Keramzit bloku',                         2, 'adet', 2.90, 1500,  'Abşeron Keramzit'),
('MAT-BLK-PEN',  'Köpük beton bloku',                      2, 'adet', 3.20, 1500,  'Bakı Beton MMC'),
('MAT-BLK-FON',  'Fundament bloku',                        2, 'adet', 28.00, 500,  'Azər Dəmir MMC'),
('MAT-BLK-ZBT',  'Zirzəmi beton bloku',                    2, 'adet', 18.00, 500,  'Bakı Beton MMC'),
('MAT-CER-FLR',  'Döşəmə kaşısı 60x60sm',                  2, 'm2',   12.50, 200,  'Vitra Azərbaycan'),
('MAT-CER-WAL',  'Divar kaşısı 30x60sm',                   2, 'm2',   9.80, 300,   'Vitra Azərbaycan'),
('MAT-CER-MOS',  'Mozaik kaşı',                            2, 'm2',   45.00, 50,   'İtalyan Import'),
('MAT-CER-PRC',  'Porselin kaşı premium',                  2, 'm2',   35.00, 100,  'İtalyan Import');

-- METAL (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-MET-ARM8',  'Armatur 8mm',                           3, 'kg',   1.15, 2000,  'Bakı Metallurq'),
('MAT-MET-A10',   'Armatur 10mm',                          3, 'kg',   1.12, 3000,  'Bakı Metallurq'),
('MAT-MET-A12',   'Armatur 12mm',                          3, 'kg',   1.10, 3000,  'Bakı Metallurq'),
('MAT-MET-A14',   'Armatur 14mm',                          3, 'kg',   1.10, 2500,  'Bakı Metallurq'),
('MAT-MET-A16',   'Armatur 16mm',                          3, 'kg',   1.08, 2000,  'Bakı Metallurq'),
('MAT-MET-A20',   'Armatur 20mm',                          3, 'kg',   1.08, 1500,  'Bakı Metallurq'),
('MAT-MET-PRF',   'Metal profil tavan üçün',               3, 'm',    3.50, 500,   'Knauf Azərbaycan'),
('MAT-MET-COR',   'Korniş metal',                          3, 'm',    4.20, 300,   'Metal Profil MMC'),
('MAT-MET-WIR',   'Bağlama məftili 1.2mm',                 3, 'kg',   2.80, 500,   'Bakı Metallurq'),
('MAT-MET-BLT',   'Anker boltlar M12',                     3, 'adet', 1.50, 2000,  'Fasteners AZ'),
('MAT-MET-NUT',   'Qayka M12',                             3, 'adet', 0.25, 5000,  'Fasteners AZ'),
('MAT-MET-SCR',   'Saplama M14',                           3, 'adet', 0.80, 3000,  'Fasteners AZ'),
('MAT-MET-LIS',   'Metal list 1mm',                        3, 'm2',   18.00, 200,  'Bakı Metallurq'),
('MAT-MET-ANG',   'Metal bucaq 50x50',                     3, 'm',    5.60, 300,   'Bakı Metallurq'),
('MAT-MET-TRU',   'Metal boru 100mm',                      3, 'm',    8.50, 200,   'Bakı Metallurq');

-- AĞAC (12)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-WOD-LSN',  'Taxta 25mm (şüşəsiz)',                   4, 'm3',   320.00, 30,   'Şəki Ağac MMC'),
('MAT-WOD-TAX',  'Taxta 40mm',                             4, 'm3',   340.00, 30,   'Şəki Ağac MMC'),
('MAT-WOD-TAR',  'Tar taxtası',                            4, 'm3',   280.00, 50,   'Zaqatala Meşə'),
('MAT-WOD-DIR',  'Direkli taxta 100x100',                  4, 'm3',   450.00, 20,   'Qax Ağac MMC'),
('MAT-WOD-SEN',  'Santex taxtası',                         4, 'm2',   45.00, 100,  'Şəki Ağac MMC'),
('MAT-WOD-FLR',  'Meşə parket',                            4, 'm2',   65.00, 80,   'Parket Azərbaycan'),
('MAT-WOD-LVN',  'Lvan panelləri',                         4, 'm2',   28.00, 100,  'Lvan MMC'),
('MAT-WOD-DOR',  'İnteryer qapı kompleks',                 4, 'adet', 120.00, 50,  'Qapı MMC'),
('MAT-WOD-WIN',  'Ağac pəncərə çərçivəsi',                 4, 'm2',   180.00, 30,  'Pəncərə MMC'),
('MAT-WOD-ALL',  'Alüminium-ağac qarışıq',                 4, 'm2',   220.00, 20,  'Hybrid Window'),
('MAT-WOD-VRL',  'Vagon ağac',                             4, 'm2',   35.00, 150,  'Şəki Ağac MMC'),
('MAT-WOD-FVN',  'Faner 10mm',                             4, 'm2',   28.00, 100,  'Faner Azərbaycan');

-- ŞÜŞƏ (10)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-GLS-4MM',  'Şüşə 4mm',                               5, 'm2',  18.00, 100,   'Bakı Şüşə MMC'),
('MAT-GLS-6MM',  'Şüşə 6mm qalın',                         5, 'm2',  28.00, 80,    'Bakı Şüşə MMC'),
('MAT-GLS-TRP',  'Üçqat şüşəli paket',                     5, 'm2',  85.00, 50,    'ThermoWindows'),
('MAT-WIN-PVC',  'PVC pəncərə (standart)',                 5, 'm2',  120.00, 30,   'REHAU Azərbaycan'),
('MAT-WIN-ALM',  'Alüminium pəncərə',                      5, 'm2',  180.00, 20,   'ALMX Ltd'),
('MAT-WIN-LAM',  'Laminə şüşə 8mm',                        5, 'm2',  45.00, 60,    'Bakı Şüşə MMC'),
('MAT-WIN-FRM',  'Plastik pəncərə çərçivəsi',              5, 'm',   28.00, 300,   'REHAU Azərbaycan'),
('MAT-WIN-SLL',  'Pəncərə kənarı',                         5, 'm',   18.00, 300,   'REHAU Azərbaycan'),
('MAT-GLS-MIR',  'Güzgü 5mm',                              5, 'm2',  32.00, 50,    'Bakı Şüşə MMC'),
('MAT-GLS-OBS',  'Buz şüşə (mat)',                         5, 'm2',  38.00, 40,    'Bakı Şüşə MMC');

-- DAM (12)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-RF-PRF',   'Profnastil metal dam 0.5mm',             6, 'm2',  22.00, 500,   'Metroll MMC'),
('MAT-RF-KRM',   'Keramik dam kirəmiti',                   6, 'adet', 2.50, 5000,  'Qəbələ Kirəmit'),
('MAT-RF-TRN',   'Tənqid kirəmit',                         6, 'adet', 3.20, 3000,  'İtalyan Import'),
('MAT-RF-ISO',   'Dam izolyasiyası 100mm',                 6, 'm2',  18.00, 200,   'İsoVer Azərbaycan'),
('MAT-RF-MEM',   'Membran dam örtüyü',                     6, 'm2',  14.00, 300,   'Membran MMC'),
('MAT-RF-PRG',   'Preqalvanizli list',                     6, 'm2',  26.00, 400,   'Metroll MMC'),
('MAT-RF-RUB',   'Kauçuk membran',                         6, 'm2',  32.00, 200,   'Membran MMC'),
('MAT-RF-BIT',   'Bitum membran SBS',                      6, 'm2',  12.00, 500,   'Bitum MMC'),
('MAT-RF-GUT',   'Dam yağmur borusu metal',                6, 'm',   8.50, 500,   'Metroll MMC'),
('MAT-RF-CHI',   'Dam bacası hissəsi',                     6, 'adet', 45.00, 100,  'Metal Profil MMC'),
('MAT-RF-AIR',   'Havalandırma qurğusu',                   6, 'adet', 185.00, 50,  'HVAC Solutions'),
('MAT-RF-FLS',   'Dam flanşı',                             6, 'adet', 28.00, 200,  'Metroll MMC');

-- BOYA (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-PNT-WHT',  'Ağ akril boya',                          7, 'litr', 8.50, 300,   'Dulux Azərbaycan'),
('MAT-PNT-EMA',  'Emal boya (metal üçün)',                 7, 'litr', 12.00, 200,  'Tikkurila Azərbaycan'),
('MAT-PNT-FAS',  'Fasad boyası silikonlu',                 7, 'litr', 14.00, 200,  'Dulux Azərbaycan'),
('MAT-PNT-INT',  'Daxili boya mat',                        7, 'litr', 9.50, 250,   'Dulux Azərbaycan'),
('MAT-PNT-SHY',  'Parlaq boya',                            7, 'litr', 11.00, 180,  'Dulux Azərbaycan'),
('MAT-PNT-LAC',  'Parke laki',                             7, 'litr', 18.00, 100,  'Tikkurila Azərbaycan'),
('MAT-PNT-IMP',  'İmpresion boya',                         7, 'litr', 25.00, 50,   'Caparol Azərbaycan'),
('MAT-PNT-PRI',  'Primer (əsas qat)',                      7, 'litr', 7.00, 400,   'Caparol Azərbaycan'),
('MAT-PNT-ACR',  'Akril primer',                           7, 'litr', 8.20, 300,   'Caparol Azərbaycan'),
('MAT-PNT-ANT',  'Anti-korroziya boya',                    7, 'litr', 15.00, 100,  'Hempel Azərbaycan'),
('MAT-PNT-EPX',  'Epoksid boya',                           7, 'litr', 22.00, 80,   'Hempel Azərbaycan'),
('MAT-PNT-STU',  'Dekorativ şpaklyovka',                   7, 'kg',   2.80, 500,   'Bakı Gips MMC'),
('MAT-PNT-SPA',  'Şpakyovka final',                        7, 'kg',   3.20, 400,   'Knauf Azərbaycan'),
('MAT-PNT-TAP',  'Maskalama lenti',                        7, 'rulon', 2.50, 300,  'Ofis MMC'),
('MAT-PNT-BRU',  'Boya fırçası set',                       7, 'qutu', 8.00, 100,   'Tools MMC');

-- ELEKTRİK (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-ELC-CAB',  'Kabel VVGng 3x1.5',                      8, 'm',    1.20, 1000,  'Bakı Kabel MMC'),
('MAT-ELC-2X',   'Kabel VVGng 2x2.5',                      8, 'm',    1.80, 1000,  'Bakı Kabel MMC'),
('MAT-ELC-3X',   'Kabel VVGng 3x2.5',                      8, 'm',    2.40, 800,   'Bakı Kabel MMC'),
('MAT-ELC-5X',   'Kabel VVGng 5x4',                        8, 'm',    5.20, 500,   'Bakı Kabel MMC'),
('MAT-ELC-MST',  'Master kabel 1x16',                      8, 'm',    6.80, 300,   'Bakı Kabel MMC'),
('MAT-ELC-SWT',  'Daxili açar (divar)',                    8, 'adet', 3.50, 500,   'Legrand Azərbaycan'),
('MAT-ELC-SKT',  'Divar rozetkası',                        8, 'adet', 4.20, 500,   'Legrand Azərbaycan'),
('MAT-ELC-PRG',  'Programmable açar',                      8, 'adet', 18.00, 100,  'Legrand Azərbaycan'),
('MAT-ELC-PNL',  'Elektrik şitı 12 xətli',                 8, 'adet', 85.00, 50,   'ABB Azərbaycan'),
('MAT-ELC-BRK',  'Avtomat açar 16A',                       8, 'adet', 8.50, 300,   'ABB Azərbaycan'),
('MAT-ELC-RCD',  'RCD qoruma 30mA',                        8, 'adet', 28.00, 100,  'ABB Azərbaycan'),
('MAT-ELC-LED',  'LED lampa 10W',                          8, 'adet', 3.80, 1000,  'Philips Azərbaycan'),
('MAT-ELC-LMP',  'LED panel 60x60',                        8, 'adet', 45.00, 200,  'Philips Azərbaycan'),
('MAT-ELC-WRE',  'Çılpaq məftil 2.5mm²',                   8, 'm',    0.80, 2000,  'Bakı Kabel MMC'),
('MAT-ELC-TRM',  'Klemmalı birləşdirici',                  8, 'adet', 0.65, 3000,  'Legrand Azərbaycan');

-- SANTEXNIKA (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-PLM-PPT',  'PPR boru 20mm',                          9, 'm',    2.20, 1000,  'Wavin Azərbaycan'),
('MAT-PLM-PP2',  'PPR boru 25mm',                          9, 'm',    2.80, 1000,  'Wavin Azərbaycan'),
('MAT-PLM-PP3',  'PPR boru 32mm',                          9, 'm',    3.50, 800,   'Wavin Azərbaycan'),
('MAT-PLM-KAN',  'Kanalizasiya borusu 110mm',              9, 'm',    5.80, 500,   'Wavin Azərbaycan'),
('MAT-PLM-KNS',  'Kanalizasiya borusu 50mm',               9, 'm',    3.20, 800,   'Wavin Azərbaycan'),
('MAT-PLM-UNT',  'Unitaz kompleks',                        9, 'adet', 180.00, 50,  'Vitra Azərbaycan'),
('MAT-PLM-BLY',  'Biday kompleks',                         9, 'adet', 220.00, 30,  'Vitra Azərbaycan'),
('MAT-PLM-VAN',  'Vanna akril',                            9, 'adet', 380.00, 20,  'Ravak Azərbaycan'),
('MAT-PLM-DUS',  'Duş kabinəsi',                           9, 'adet', 520.00, 15,  'Ravak Azərbaycan'),
('MAT-PLM-SIN',  'Əlüzyuyan',                              9, 'adet', 120.00, 60,  'Vitra Azərbaycan'),
('MAT-PLM-KRN',  'Kran (smеsitel) vanna',                  9, 'adet', 85.00, 80,   'Grohe Azərbaycan'),
('MAT-PLM-KSR',  'Kran sink (mətbəx)',                     9, 'adet', 95.00, 100,  'Grohe Azərbaycan'),
('MAT-PLM-BOI',  'Qaz qazanı (100L)',                      9, 'adet', 680.00, 10,  'Ariston Azərbaycan'),
('MAT-PLM-RAD',  'Radiator alüminium 6 bölməli',           9, 'adet', 85.00, 100,  'Global Radiators'),
('MAT-PLM-VLV',  'Şar vana 1/2"',                          9, 'adet', 8.50, 500,   'Grohe Azərbaycan');

-- PƏRDAHLAMA (15)
INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier) VALUES
('MAT-FIN-LAM',  'Laminat 8mm',                            10, 'm2',  15.00, 300,  'Parket Azərbaycan'),
('MAT-FIN-LNT',  'Linoleum 2.5mm',                         10, 'm2',  12.00, 250,  'Tarkett Azərbaycan'),
('MAT-FIN-CRP',  'Kilim (örgü)',                           10, 'm2',   28.00, 100, 'Kilim MMC'),
('MAT-FIN-DEK',  'Dekorativ stuk',                         10, 'm2',   38.00, 80,  'İtalyan Import'),
('MAT-FIN-WLP',  'Divar kağızı vinil',                     10, 'rulon', 18.00, 200, 'Bakı Kağız'),
('MAT-FIN-FLX',  'Flizelin divar kağızı',                  10, 'rulon', 28.00, 150, 'Bakı Kağız'),
('MAT-FIN-MOL',  'Tavan bordürü',                          10, 'm',    3.50, 500,  'Dekor MMC'),
('MAT-FIN-PLT',  'Tavan plitəsi',                          10, 'm2',   18.00, 200, 'Armstrong Azərbaycan'),
('MAT-FIN-SUS',  'Asma tavan gipsli',                      10, 'm2',   22.00, 200, 'Knauf Azərbaycan'),
('MAT-FIN-CEI',  'Gipskarton 9mm',                         10, 'm2',   8.50, 500,  'Knauf Azərbaycan'),
('MAT-FIN-GK1',  'Gipskarton 12.5mm',                      10, 'm2',   10.20, 500, 'Knauf Azərbaycan'),
('MAT-FIN-TRS',  'Mərmər plitə',                           10, 'm2',   85.00, 50,  'Mərmər MMC'),
('MAT-FIN-GRN',  'Qranit plitə',                           10, 'm2',   95.00, 50,  'Mərmər MMC'),
('MAT-FIN-BGT',  'Baget tavan',                            10, 'm',    4.80, 400,  'Dekor MMC'),
('MAT-FIN-PRO',  'Dekorativ plastik panel',                10, 'm2',   18.00, 150, 'Dekor MMC');

-- QALAN MATERIALLAR RANDOM (65 ədəd - ümumilikdə 200-ə çatsın)
DO $$
DECLARE
  prefixes TEXT[] := ARRAY['Yüksək keyfiyyətli', 'Premium', 'Standart', 'Ekonom', 'Professional', 'Sənaye'];
  base_materials TEXT[] := ARRAY[
    'izolyasiya materialı', 'yapışqan', 'hermetik', 'köpük', 'bolt', 'qoruyucu lent',
    'silikon', 'montaj köpüyü', 'məftil', 'köpük lenti', 'armatur qoruyucu', 'PVC profil',
    'termoizolyasiya', 'ses izolyasiyası', 'su izolyasiyası'
  ];
  units TEXT[] := ARRAY['kg','m','m2','adet','litr','rulon','qutu'];
  i INT;
  cat_id INT;
  cat_count INT;
BEGIN
  SELECT COUNT(*) INTO cat_count FROM inventory.material_categories;
  
  FOR i IN 1..65 LOOP
    cat_id := 1 + (RANDOM() * (cat_count - 1))::INT;
    
    INSERT INTO inventory.materials (code, name_az, category_id, unit, standard_price, min_stock_level, typical_supplier)
    VALUES (
      'MAT-GEN-' || LPAD(i::TEXT, 3, '0'),
      prefixes[1 + (RANDOM() * (array_length(prefixes,1)-1))::INT] || ' ' || 
        base_materials[1 + (RANDOM() * (array_length(base_materials,1)-1))::INT] || ' ' ||
        'Tip-' || i,
      cat_id,
      units[1 + (RANDOM() * (array_length(units,1)-1))::INT],
      ROUND((1 + RANDOM() * 100)::NUMERIC, 2),
      (50 + RANDOM() * 2000)::INT,
      'Təchizatçı #' || (1 + (RANDOM() * 20)::INT)
    );
  END LOOP;
  
  RAISE NOTICE '✅ Əlavə 65 material yaradıldı';
END $$;

-- ─── 3. 15 ANBAR ───
-- Əsas bölgələrdə anbarlar
INSERT INTO inventory.warehouses (code, name, region_id, address, area_m2, is_central) VALUES
('WH-BA-01', 'Bakı Mərkəzi Anbar',         (SELECT id FROM geo.regions WHERE code='BA'),   'Bakı, Suraxanı, Sənaye zonası',   3500.00, TRUE),
('WH-BA-02', 'Bakı Əlavə Anbar (Qaradağ)', (SELECT id FROM geo.regions WHERE code='BAG'),  'Qaradağ, Salyan şosesi',           1800.00, FALSE),
('WH-BA-03', 'Bakı Pirallahı Anbarı',      (SELECT id FROM geo.regions WHERE code='BAP'),  'Pirallahı, Sənaye zonası',         1200.00, FALSE),
('WH-GA-01', 'Gəncə Regional Anbarı',      (SELECT id FROM geo.regions WHERE code='GA'),   'Gəncə, Sənaye rayonu',             2500.00, TRUE),
('WH-SM-01', 'Sumqayıt Regional Anbarı',   (SELECT id FROM geo.regions WHERE code='SM'),   'Sumqayıt, Kimyaçılar qəsəbəsi',    2200.00, TRUE),
('WH-NX-01', 'Naxçıvan Regional Anbarı',   (SELECT id FROM geo.regions WHERE code='NX'),   'Naxçıvan, Cəlil Məmmədquluzadə',   1800.00, TRUE),
('WH-ML-01', 'Mingəçevir Anbarı',          (SELECT id FROM geo.regions WHERE code='ML'),   'Mingəçevir, Sənaye rayonu',        1500.00, FALSE),
('WH-SK-01', 'Şəki Anbarı',                (SELECT id FROM geo.regions WHERE code='SK'),   'Şəki, Sənaye zonası',              1100.00, FALSE),
('WH-LN-01', 'Lənkəran Anbarı',            (SELECT id FROM geo.regions WHERE code='LN'),   'Lənkəran, Sənaye zonası',          1300.00, FALSE),
('WH-QB-01', 'Quba-Xaçmaz Anbarı',         (SELECT id FROM geo.regions WHERE code='QB'),   'Quba, Şəhər kənarı',               1400.00, FALSE),
('WH-AG-01', 'Ağdam-Bərdə Anbarı',         (SELECT id FROM geo.regions WHERE code='BR'),   'Bərdə, Mərkəzi sənaye zonası',     1600.00, FALSE),
('WH-ZQ-01', 'Şəki-Zaqatala Anbarı',       (SELECT id FROM geo.regions WHERE code='ZQ'),   'Zaqatala, Sənaye zonası',          1000.00, FALSE),
('WH-TV-01', 'Gəncə-Qazax Anbarı',         (SELECT id FROM geo.regions WHERE code='TV'),   'Tovuz, Sənaye zonası',             1200.00, FALSE),
('WH-MS-01', 'Lənkəran-Astara Anbarı',     (SELECT id FROM geo.regions WHERE code='MS'),   'Masallı, Mərkəzi anbar',           1100.00, FALSE),
('WH-IM-01', 'Aran Regional Anbarı',       (SELECT id FROM geo.regions WHERE code='IM'),   'İmişli, Sənaye rayonu',            1300.00, FALSE);

-- Anbar menecerləri — işçilərdən təyin edirik
UPDATE inventory.warehouses 
SET manager_id = (SELECT id FROM hr.employees ORDER BY RANDOM() LIMIT 1);

-- ─── 4. STOK SƏVİYYƏLƏRI (hər anbarda hər material üçün başlanğıc qalıq) ───
DO $$
DECLARE
  w RECORD;
  m RECORD;
  qty NUMERIC;
BEGIN
  FOR w IN SELECT id FROM inventory.warehouses LOOP
    FOR m IN SELECT id, min_stock_level FROM inventory.materials LOOP
      -- Hər anbarda hər materialın 50-70%-i var (bəzilərində az)
      IF RANDOM() > 0.3 THEN  -- 70% şans — stok var
        qty := m.min_stock_level * (0.5 + RANDOM() * 3);  -- min_stock * 0.5-3.5
        INSERT INTO inventory.stock_levels (warehouse_id, material_id, quantity)
        VALUES (w.id, m.id, qty);
      END IF;
    END LOOP;
  END LOOP;
  RAISE NOTICE '✅ Anbar stokları yaradıldı';
END $$;

-- ─── 5. AVADANLIQ (30 ədəd) ───
DO $$
DECLARE
  equip_types TEXT[] := ARRAY[
    'Ekskavator','Buldozer','Kran','Betonqarışdıran','Mişarlı maşın','Qaynaq aparatı',
    'Kompressor','Generator','Dözüm sınayıcı','Nivelir','Teodolit','Lazer ölçən',
    'Elektrik drel','Perforator','Boya püskürən','Beton pomp','Yük avtomobili','Mini ekskavator'
  ];
  equip_names TEXT[] := ARRAY['JCB','CAT','Volvo','Komatsu','Bobcat','Hitachi','Liebherr'];
  statuses TEXT[] := ARRAY['active','active','active','active','maintenance','broken'];
  i INT;
  wh_id INT;
  emp_id INT;
BEGIN
  FOR i IN 1..30 LOOP
    SELECT id INTO wh_id FROM inventory.warehouses ORDER BY RANDOM() LIMIT 1;
    SELECT id INTO emp_id FROM hr.employees WHERE RANDOM() > 0.5 ORDER BY RANDOM() LIMIT 1;
    
    INSERT INTO inventory.equipment (code, name, equipment_type, warehouse_id, purchase_date, purchase_price, status, assigned_to)
    VALUES (
      'EQ-' || LPAD(i::TEXT, 3, '0'),
      equip_names[1 + (RANDOM() * (array_length(equip_names,1)-1))::INT] || ' ' ||
        equip_types[1 + (RANDOM() * (array_length(equip_types,1)-1))::INT] || ' ' ||
        '#' || i,
      equip_types[1 + (RANDOM() * (array_length(equip_types,1)-1))::INT],
      wh_id,
      DATE '2015-01-01' + (RANDOM() * 365 * 10)::INT,
      ROUND((5000 + RANDOM() * 200000)::NUMERIC, 0),
      statuses[1 + (RANDOM() * (array_length(statuses,1)-1))::INT],
      emp_id
    );
  END LOOP;
  RAISE NOTICE '✅ 30 avadanlıq yaradıldı';
END $$;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ İNVENTAR STATİSTİKASI ═══'
SELECT 'Kateqoriyalar: ' || COUNT(*) FROM inventory.material_categories
UNION ALL
SELECT 'Materiallar: '   || COUNT(*) FROM inventory.materials
UNION ALL
SELECT 'Anbarlar: '      || COUNT(*) FROM inventory.warehouses
UNION ALL
SELECT 'Stok sətirləri: ' || COUNT(*) FROM inventory.stock_levels
UNION ALL
SELECT 'Avadanlıq: '     || COUNT(*) FROM inventory.equipment;

\echo ''
\echo '═══ Kateqoriya üzrə materiallar ═══'
SELECT mc.icon || ' ' || mc.name_az AS "Kateqoriya", COUNT(m.id) AS "Material sayı"
FROM inventory.material_categories mc
LEFT JOIN inventory.materials m ON m.category_id = mc.id
GROUP BY mc.id, mc.icon, mc.name_az
ORDER BY COUNT(m.id) DESC;

\echo ''
\echo '═══ Anbar ölçüləri ═══'
SELECT name AS "Anbar", area_m2 AS "Sahə (m²)", 
       CASE WHEN is_central THEN '⭐ Mərkəzi' ELSE 'Regional' END AS "Tip"
FROM inventory.warehouses
ORDER BY area_m2 DESC
LIMIT 5;

\echo ''
\echo '═══ Avadanlıq status ═══'
SELECT status AS "Status", COUNT(*) AS "Sayı"
FROM inventory.equipment
GROUP BY status;

\echo ''
\echo '═══ Ümumi stok ═══'
SELECT 
  COUNT(*) AS stock_records,
  COUNT(DISTINCT warehouse_id) AS warehouses_used,
  COUNT(DISTINCT material_id) AS materials_in_stock
FROM inventory.stock_levels;
