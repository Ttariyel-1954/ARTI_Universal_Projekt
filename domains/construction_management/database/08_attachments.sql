-- ═══════════════════════════════════════════════════════════════
-- 08: Fayl əlavələri sistemi (Hybrid storage)
-- Metadata: PostgreSQL · Fayl: Disk
-- ═══════════════════════════════════════════════════════════════

-- Attachment type enum
DO $$ BEGIN
  CREATE TYPE construction.attachment_type AS ENUM (
    'photo',           -- ümumi foto
    'inspection_photo',-- yoxlama foto
    'complaint_photo', -- şikayət foto
    'progress_photo',  -- tərəqqi foto
    'invoice',         -- qaimə (qaimə-faktura)
    'contract',        -- müqavilə
    'receipt',         -- qəbz
    'certificate',     -- sertifikat
    'blueprint',       -- planşet/layihə
    'scan',            -- ümumi skan
    'other'            -- digər
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ═══════════════════════════════════════════════════════════════
-- ATTACHMENTS — əsas cədvəl
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS construction.attachments (
  id              SERIAL PRIMARY KEY,
  
  -- TYPE və PARENT
  attachment_type construction.attachment_type NOT NULL DEFAULT 'photo',
  parent_table    VARCHAR(50) NOT NULL,        -- 'inspections', 'complaints', 'daily_reports', 'projects', 'schools'
  parent_id       INT NOT NULL,                -- FK manual (cross-schema üçün)
  
  -- FAYL MƏLUMATI
  filename        VARCHAR(255) NOT NULL,       -- original ad
  stored_name     VARCHAR(255) NOT NULL,       -- disk-dəki ad (unikal)
  file_path       VARCHAR(500) NOT NULL,       -- tam yol
  file_size       BIGINT NOT NULL,             -- bayt
  mime_type       VARCHAR(100) NOT NULL,       -- 'image/jpeg', 'application/pdf'
  file_extension  VARCHAR(10),                 -- '.jpg', '.pdf'
  
  -- METADATA
  title           VARCHAR(255),                -- istifadəçi başlığı
  description     TEXT,                        -- qeyd
  
  -- TƏSVİR XÜSUSİYYƏTLƏRI
  width           INT,                         -- piksel (şəkil üçün)
  height          INT,
  page_count      INT,                         -- PDF üçün səhifə sayı
  
  -- COĞRAFİ
  gps_lat         NUMERIC(10, 7),
  gps_lng         NUMERIC(10, 7),
  
  -- KİM YÜKLƏDİ
  uploaded_by     INT REFERENCES audit.users(id),
  uploader_role   VARCHAR(20),                 -- 'admin', 'editor', 'regional_worker'
  ip_address      INET,
  source          VARCHAR(20),                 -- 'mobile', 'dashboard'
  
  -- THUMBNAIL (preview üçün)
  thumbnail_path  VARCHAR(500),
  
  -- STATUS
  is_deleted      BOOLEAN DEFAULT FALSE,       -- soft delete
  deleted_at      TIMESTAMP,
  deleted_by      INT REFERENCES audit.users(id),
  
  created_at      TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT chk_file_size CHECK (file_size > 0 AND file_size <= 5242880)  -- max 5 MB
);

-- İndekslər
CREATE INDEX IF NOT EXISTS idx_att_parent       ON construction.attachments(parent_table, parent_id);
CREATE INDEX IF NOT EXISTS idx_att_type         ON construction.attachments(attachment_type);
CREATE INDEX IF NOT EXISTS idx_att_uploader     ON construction.attachments(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_att_created      ON construction.attachments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_att_active       ON construction.attachments(is_deleted) WHERE is_deleted = FALSE;

-- ═══════════════════════════════════════════════════════════════
-- HELPER VIEW-LAR
-- ═══════════════════════════════════════════════════════════════

-- Əlavələr (dashboard-da göstərmək üçün)
CREATE OR REPLACE VIEW construction.v_attachments_full AS
SELECT 
  a.id,
  a.attachment_type,
  a.parent_table,
  a.parent_id,
  a.filename,
  a.stored_name,
  a.file_path,
  a.file_size,
  ROUND(a.file_size / 1024.0, 1) AS size_kb,
  a.mime_type,
  a.title,
  a.description,
  a.gps_lat,
  a.gps_lng,
  
  -- Uploader info
  u.username AS uploader_username,
  u.full_name AS uploader_name,
  a.uploader_role,
  a.source,
  
  -- Region (regional worker üçün)
  r.name_az AS region_name,
  
  -- Thumbnail
  a.thumbnail_path,
  
  -- File category (UI üçün)
  CASE 
    WHEN a.mime_type LIKE 'image/%' THEN 'image'
    WHEN a.mime_type = 'application/pdf' THEN 'pdf'
    WHEN a.mime_type LIKE 'application/vnd%' THEN 'office'
    ELSE 'other'
  END AS file_category,
  
  -- Icon (UI üçün)
  CASE 
    WHEN a.attachment_type IN ('photo','inspection_photo','complaint_photo','progress_photo') THEN '📸'
    WHEN a.attachment_type = 'invoice' THEN '🧾'
    WHEN a.attachment_type = 'contract' THEN '📋'
    WHEN a.attachment_type = 'receipt' THEN '🧾'
    WHEN a.attachment_type = 'certificate' THEN '🏅'
    WHEN a.attachment_type = 'blueprint' THEN '📐'
    WHEN a.attachment_type = 'scan' THEN '📄'
    ELSE '📎'
  END AS icon,
  
  a.created_at
FROM construction.attachments a
LEFT JOIN audit.users u ON a.uploaded_by = u.id
LEFT JOIN geo.regions r ON u.region_id = r.id
WHERE a.is_deleted = FALSE;

-- Statistika view
CREATE OR REPLACE VIEW construction.v_attachment_stats AS
SELECT 
  COUNT(*) AS total_files,
  COUNT(*) FILTER (WHERE mime_type LIKE 'image/%') AS total_images,
  COUNT(*) FILTER (WHERE mime_type = 'application/pdf') AS total_pdfs,
  COUNT(*) FILTER (WHERE created_at::date = CURRENT_DATE) AS today_files,
  COUNT(*) FILTER (WHERE source = 'mobile') AS mobile_files,
  COUNT(*) FILTER (WHERE source = 'dashboard') AS dashboard_files,
  ROUND(SUM(file_size)/1048576.0, 2) AS total_mb,
  COUNT(DISTINCT uploaded_by) AS unique_uploaders,
  COUNT(DISTINCT parent_table || ':' || parent_id) AS attached_to_objects
FROM construction.attachments
WHERE is_deleted = FALSE;

-- ═══════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

-- Əlavə yarat (R-dən çağrılır)
CREATE OR REPLACE FUNCTION construction.add_attachment(
  p_type            VARCHAR,
  p_parent_table    VARCHAR,
  p_parent_id       INT,
  p_filename        VARCHAR,
  p_stored_name     VARCHAR,
  p_file_path       VARCHAR,
  p_file_size       BIGINT,
  p_mime_type       VARCHAR,
  p_uploaded_by     INT,
  p_source          VARCHAR DEFAULT 'mobile',
  p_ip              INET DEFAULT NULL,
  p_title           VARCHAR DEFAULT NULL,
  p_description     TEXT DEFAULT NULL,
  p_gps_lat         NUMERIC DEFAULT NULL,
  p_gps_lng         NUMERIC DEFAULT NULL
) RETURNS INT AS $$
DECLARE
  new_id INT;
  user_role VARCHAR;
BEGIN
  -- User-in rolunu al
  SELECT role::TEXT INTO user_role FROM audit.users WHERE id = p_uploaded_by;
  
  INSERT INTO construction.attachments (
    attachment_type, parent_table, parent_id,
    filename, stored_name, file_path, file_size, mime_type,
    file_extension, uploaded_by, uploader_role, source, ip_address,
    title, description, gps_lat, gps_lng
  ) VALUES (
    p_type::construction.attachment_type, p_parent_table, p_parent_id,
    p_filename, p_stored_name, p_file_path, p_file_size, p_mime_type,
    LOWER(SUBSTRING(p_filename FROM '\.[^.]+$')),
    p_uploaded_by, user_role, p_source, p_ip,
    p_title, p_description, p_gps_lat, p_gps_lng
  ) RETURNING id INTO new_id;
  
  RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Object üçün əlavələri al
CREATE OR REPLACE FUNCTION construction.get_attachments(
  p_parent_table VARCHAR,
  p_parent_id INT
) RETURNS TABLE(
  id INT,
  attachment_type construction.attachment_type,
  filename VARCHAR,
  file_path VARCHAR,
  file_size BIGINT,
  mime_type VARCHAR,
  uploaded_by INT,
  uploader_name VARCHAR,
  created_at TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.attachment_type, a.filename, a.file_path, 
         a.file_size, a.mime_type, a.uploaded_by, u.full_name, a.created_at
  FROM construction.attachments a
  LEFT JOIN audit.users u ON a.uploaded_by = u.id
  WHERE a.parent_table = p_parent_table 
    AND a.parent_id = p_parent_id
    AND a.is_deleted = FALSE
  ORDER BY a.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Permissions (audit.permissions cədvəlinə əlavə)
INSERT INTO audit.permissions (role, resource, can_select, can_insert, can_update, can_delete, can_approve, notes) VALUES
('admin', 'attachments',           TRUE, TRUE, TRUE, TRUE, FALSE, 'Tam giriş'),
('editor', 'attachments',          TRUE, TRUE, TRUE, FALSE, FALSE, 'Yükləmək və redaktə'),
('viewer', 'attachments',          TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('regional_worker', 'attachments', TRUE, TRUE, FALSE, FALSE, FALSE, 'Yükləmək (öz region)')
ON CONFLICT (role, resource) DO UPDATE 
  SET can_select = EXCLUDED.can_select,
      can_insert = EXCLUDED.can_insert,
      can_update = EXCLUDED.can_update,
      can_delete = EXCLUDED.can_delete,
      notes = EXCLUDED.notes;

-- ═══════════════════════════════════════════════════════════════
-- YOXLAMA
-- ═══════════════════════════════════════════════════════════════
\echo ''
\echo '═══ ATTACHMENT SİSTEMİ QURULDU ═══'
\dt construction.attachments

\echo ''
\echo '═══ Sütunlar: ═══'
\d construction.attachments

\echo ''
\echo '═══ View-lar: ═══'
\dv construction.v_attachment*

\echo ''
\echo '═══ Funksiyalar: ═══'
\df construction.*attachment*

\echo ''
\echo '═══ Hüquqlar: ═══'
SELECT role AS "Rol", 
       CASE WHEN can_select THEN '✅' ELSE '❌' END AS "Oxu",
       CASE WHEN can_insert THEN '✅' ELSE '❌' END AS "Yüklə",
       CASE WHEN can_update THEN '✅' ELSE '❌' END AS "Dəyiş",
       CASE WHEN can_delete THEN '✅' ELSE '❌' END AS "Sil",
       notes AS "Qeyd"
FROM audit.permissions WHERE resource = 'attachments' ORDER BY role;

\echo ''
\echo '═══ Statistika (boşdur, hələ): ═══'
SELECT * FROM construction.v_attachment_stats;
