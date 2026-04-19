-- ═══════════════════════════════════════════════════════════════
-- 06: Audit + Users sistemi (RBAC + Logging)
-- 3 rol: admin, editor, viewer
-- ═══════════════════════════════════════════════════════════════

-- ─── Schema (artıq var, əmin olaq) ───
CREATE SCHEMA IF NOT EXISTS audit;

-- ═══════════════════════════════════════════════════════════════
-- 1. ROLLAR (enum)
-- ═══════════════════════════════════════════════════════════════
DO $$ BEGIN
  CREATE TYPE audit.user_role AS ENUM ('admin', 'editor', 'viewer');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE audit.action_type AS ENUM ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'AI_QUERY', 'EXPORT');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ═══════════════════════════════════════════════════════════════
-- 2. USERS — İstifadəçilər
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit.users (
  id              SERIAL PRIMARY KEY,
  username        VARCHAR(50) UNIQUE NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,           -- bcrypt hash
  email           VARCHAR(100) UNIQUE,
  full_name       VARCHAR(150) NOT NULL,
  role            audit.user_role NOT NULL DEFAULT 'viewer',
  
  -- Əlaqə məlumatları
  phone           VARCHAR(20),
  position        VARCHAR(100),                    -- vəzifə
  department_id   INT REFERENCES hr.departments(id),
  region_id       INT REFERENCES geo.regions(id),  -- hansı rayon üzrə
  
  -- Status
  is_active       BOOLEAN DEFAULT TRUE,
  is_verified     BOOLEAN DEFAULT FALSE,
  must_change_pwd BOOLEAN DEFAULT TRUE,            -- ilk girişdə məcburi dəyişmək
  
  -- Metadata
  last_login      TIMESTAMP,
  last_ip         INET,
  failed_attempts INT DEFAULT 0,                   -- uğursuz giriş cəhdləri
  locked_until    TIMESTAMP,                       -- brute-force qorunma
  
  created_at      TIMESTAMP DEFAULT NOW(),
  updated_at      TIMESTAMP DEFAULT NOW(),
  created_by      INT REFERENCES audit.users(id),
  
  CONSTRAINT chk_username_format CHECK (username ~ '^[a-z0-9_.-]{3,50}$'),
  CONSTRAINT chk_email_format    CHECK (email IS NULL OR email ~ '^[^@]+@[^@]+\.[^@]+$')
);

CREATE INDEX IF NOT EXISTS idx_users_username ON audit.users(username);
CREATE INDEX IF NOT EXISTS idx_users_role     ON audit.users(role);
CREATE INDEX IF NOT EXISTS idx_users_active   ON audit.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_region   ON audit.users(region_id);

-- ═══════════════════════════════════════════════════════════════
-- 3. SESSIONS — Aktiv sessiyalar (JWT izləmə)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit.sessions (
  id              SERIAL PRIMARY KEY,
  user_id         INT NOT NULL REFERENCES audit.users(id) ON DELETE CASCADE,
  token_hash      VARCHAR(255) NOT NULL,           -- JWT hash (raw token saxlanmır)
  refresh_hash    VARCHAR(255),
  
  -- Bağlantı info
  ip_address      INET NOT NULL,
  user_agent      TEXT,
  tailscale_name  VARCHAR(100),                    -- Tailscale hostname
  device_type     VARCHAR(20),                     -- 'desktop', 'mobile', 'tablet'
  
  -- Vaxt
  created_at      TIMESTAMP DEFAULT NOW(),
  expires_at      TIMESTAMP NOT NULL,
  last_activity   TIMESTAMP DEFAULT NOW(),
  revoked_at      TIMESTAMP,                       -- logout və ya force revoke
  revoke_reason   VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_sessions_user     ON audit.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active   ON audit.sessions(revoked_at) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sessions_expires  ON audit.sessions(expires_at);

-- ═══════════════════════════════════════════════════════════════
-- 4. PERMISSIONS — Rol bazalı hüquq cədvəli
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit.permissions (
  id              SERIAL PRIMARY KEY,
  role            audit.user_role NOT NULL,
  resource        VARCHAR(100) NOT NULL,           -- 'projects', 'budgets', 'complaints' və s.
  can_select      BOOLEAN DEFAULT TRUE,
  can_insert      BOOLEAN DEFAULT FALSE,
  can_update      BOOLEAN DEFAULT FALSE,
  can_delete      BOOLEAN DEFAULT FALSE,
  can_approve     BOOLEAN DEFAULT FALSE,           -- Düzgünləşdirmə (approve workflow)
  notes           TEXT,
  
  UNIQUE (role, resource)
);

-- Default permissions yükləyək
INSERT INTO audit.permissions (role, resource, can_select, can_insert, can_update, can_delete, can_approve, notes) VALUES
-- ADMIN — hər şeyə tam giriş
('admin', 'projects',     TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'budgets',      TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'contractors',  TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'schools',      TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'employees',    TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'materials',    TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'inspections',  TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'complaints',   TRUE, TRUE, TRUE, TRUE, TRUE, 'Tam giriş'),
('admin', 'users',        TRUE, TRUE, TRUE, TRUE, TRUE, 'İstifadəçi idarəsi'),
('admin', 'audit_log',    TRUE, FALSE, FALSE, FALSE, FALSE, 'Log görmək'),
('admin', 'ai_query',     TRUE, TRUE, FALSE, FALSE, FALSE, 'AI soruşmaq'),

-- EDITOR — məlumat daxil edə bilər, amma silmək və user idarə edə bilməz
('editor', 'projects',     TRUE, TRUE, TRUE, FALSE, FALSE, 'Daxiletmə və redaktə'),
('editor', 'budgets',      TRUE, TRUE, TRUE, FALSE, FALSE, 'Daxiletmə və redaktə'),
('editor', 'contractors',  TRUE, TRUE, TRUE, FALSE, FALSE, 'Daxiletmə və redaktə'),
('editor', 'schools',      TRUE, TRUE, TRUE, FALSE, FALSE, 'Daxiletmə və redaktə'),
('editor', 'employees',    TRUE, FALSE, TRUE, FALSE, FALSE, 'Yalnız redaktə'),
('editor', 'materials',    TRUE, TRUE, TRUE, FALSE, FALSE, 'Daxiletmə və redaktə'),
('editor', 'inspections',  TRUE, TRUE, TRUE, FALSE, FALSE, 'Yoxlama əlavə etmək'),
('editor', 'complaints',   TRUE, TRUE, TRUE, FALSE, FALSE, 'Şikayət cavabı'),
('editor', 'users',        FALSE, FALSE, FALSE, FALSE, FALSE, 'Giriş yoxdur'),
('editor', 'audit_log',    TRUE, FALSE, FALSE, FALSE, FALSE, 'Öz əməliyyatlarını görə bilər'),
('editor', 'ai_query',     TRUE, TRUE, FALSE, FALSE, FALSE, 'AI soruşmaq'),

-- VIEWER — yalnız oxuya bilər
('viewer', 'projects',     TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'budgets',      TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'contractors',  TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'schools',      TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'employees',    FALSE, FALSE, FALSE, FALSE, FALSE, 'HR məlumat - admin görər'),
('viewer', 'materials',    TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'inspections',  TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'complaints',   TRUE, FALSE, FALSE, FALSE, FALSE, 'Yalnız oxuma'),
('viewer', 'users',        FALSE, FALSE, FALSE, FALSE, FALSE, 'Giriş yoxdur'),
('viewer', 'audit_log',    FALSE, FALSE, FALSE, FALSE, FALSE, 'Giriş yoxdur'),
('viewer', 'ai_query',     FALSE, FALSE, FALSE, FALSE, FALSE, 'AI istifadə edə bilməz')
ON CONFLICT (role, resource) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════
-- 5. QUERY_LOG — Hər sorğunun qeydi (dashboard + AI)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit.query_log (
  id              BIGSERIAL PRIMARY KEY,
  user_id         INT REFERENCES audit.users(id),
  username        VARCHAR(50),                     -- denormalize (user silinəndə saxla)
  user_role       audit.user_role,
  session_id      INT REFERENCES audit.sessions(id),
  
  -- Əməliyyat
  action          audit.action_type NOT NULL,
  resource        VARCHAR(100),                    -- 'projects', 'budgets' ...
  resource_id     INT,                             -- hansı sətir
  
  -- Sorğu məzmunu
  query_text      TEXT,                            -- SQL / AI sualı / endpoint
  query_params    JSONB,                           -- parametrlər
  
  -- Bağlantı məlumatı (VACİB!)
  ip_address      INET,
  tailscale_name  VARCHAR(100),                    -- Tailscale cihaz adı
  user_agent      TEXT,
  source          VARCHAR(50),                     -- 'dashboard', 'mobile', 'api', 'ai_panel'
  
  -- Performans
  duration_ms     INT,
  status          VARCHAR(20) DEFAULT 'success',   -- 'success', 'error', 'denied'
  error_message   TEXT,
  
  -- AI sorğuları üçün
  ai_tokens_input  INT,
  ai_tokens_output INT,
  ai_cost_usd      NUMERIC(10, 6),
  
  created_at      TIMESTAMP DEFAULT NOW()
);

-- İndekslər (tez axtarış üçün)
CREATE INDEX IF NOT EXISTS idx_qlog_user     ON audit.query_log(user_id);
CREATE INDEX IF NOT EXISTS idx_qlog_action   ON audit.query_log(action);
CREATE INDEX IF NOT EXISTS idx_qlog_resource ON audit.query_log(resource);
CREATE INDEX IF NOT EXISTS idx_qlog_time     ON audit.query_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_qlog_ip       ON audit.query_log(ip_address);
CREATE INDEX IF NOT EXISTS idx_qlog_source   ON audit.query_log(source);
CREATE INDEX IF NOT EXISTS idx_qlog_status   ON audit.query_log(status);

-- ═══════════════════════════════════════════════════════════════
-- 6. DATA_CHANGES — Dəyişikliklərin tarixçəsi (audit trail)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit.data_changes (
  id              BIGSERIAL PRIMARY KEY,
  query_log_id    BIGINT REFERENCES audit.query_log(id),
  user_id         INT REFERENCES audit.users(id),
  username        VARCHAR(50),
  
  -- Nə dəyişdi
  table_schema    VARCHAR(50) NOT NULL,            -- 'construction', 'finance' ...
  table_name      VARCHAR(50) NOT NULL,            -- 'projects', 'budgets' ...
  record_id       INT NOT NULL,
  action          audit.action_type NOT NULL,      -- INSERT/UPDATE/DELETE
  
  -- JSON formatında əvvəl-sonra
  old_values      JSONB,                           -- köhnə dəyərlər (UPDATE/DELETE)
  new_values      JSONB,                           -- yeni dəyərlər (INSERT/UPDATE)
  changed_fields  TEXT[],                          -- hansı sütunlar dəyişdi
  
  -- Kontekst
  reason          TEXT,                            -- istifadəçi qeyd
  ip_address      INET,
  
  created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dchng_user    ON audit.data_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_dchng_table   ON audit.data_changes(table_schema, table_name);
CREATE INDEX IF NOT EXISTS idx_dchng_record  ON audit.data_changes(table_schema, table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_dchng_time    ON audit.data_changes(created_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- 7. LOGIN_HISTORY — Giriş tarixçəsi
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit.login_history (
  id              BIGSERIAL PRIMARY KEY,
  user_id         INT REFERENCES audit.users(id),
  username        VARCHAR(50) NOT NULL,            -- username yazılır, user silinsə belə qalır
  
  -- Nəticə
  status          VARCHAR(20) NOT NULL,            -- 'success', 'failed', 'locked'
  failure_reason  VARCHAR(100),                    -- 'invalid_password', 'user_inactive', 'locked_out'
  
  -- Bağlantı
  ip_address      INET,
  tailscale_name  VARCHAR(100),
  user_agent      TEXT,
  device_type     VARCHAR(20),
  
  -- Vaxt
  attempted_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lhist_user    ON audit.login_history(user_id);
CREATE INDEX IF NOT EXISTS idx_lhist_username ON audit.login_history(username);
CREATE INDEX IF NOT EXISTS idx_lhist_status  ON audit.login_history(status);
CREATE INDEX IF NOT EXISTS idx_lhist_time    ON audit.login_history(attempted_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- 8. HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

-- Hüquq yoxlama funksiyası
CREATE OR REPLACE FUNCTION audit.check_permission(
  p_user_id INT,
  p_resource VARCHAR,
  p_action VARCHAR  -- 'select', 'insert', 'update', 'delete', 'approve'
) RETURNS BOOLEAN AS $$
DECLARE
  user_role_v audit.user_role;
  has_permission BOOLEAN := FALSE;
BEGIN
  -- User-in rolunu tap
  SELECT role INTO user_role_v FROM audit.users WHERE id = p_user_id AND is_active;
  IF user_role_v IS NULL THEN RETURN FALSE; END IF;
  
  -- Hüquq cədvəlindən yoxla
  EXECUTE format('SELECT can_%I FROM audit.permissions WHERE role = $1 AND resource = $2', p_action)
    INTO has_permission
    USING user_role_v, p_resource;
  
  RETURN COALESCE(has_permission, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Sorğu log etmə funksiyası (quick log)
CREATE OR REPLACE FUNCTION audit.log_query(
  p_user_id INT,
  p_action audit.action_type,
  p_resource VARCHAR,
  p_query_text TEXT DEFAULT NULL,
  p_ip INET DEFAULT NULL,
  p_source VARCHAR DEFAULT 'dashboard',
  p_duration_ms INT DEFAULT NULL,
  p_status VARCHAR DEFAULT 'success'
) RETURNS BIGINT AS $$
DECLARE
  log_id BIGINT;
  user_data RECORD;
BEGIN
  SELECT username, role INTO user_data FROM audit.users WHERE id = p_user_id;
  
  INSERT INTO audit.query_log (
    user_id, username, user_role,
    action, resource, query_text,
    ip_address, source, duration_ms, status
  ) VALUES (
    p_user_id, user_data.username, user_data.role,
    p_action, p_resource, p_query_text,
    p_ip, p_source, p_duration_ms, p_status
  ) RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- Login uğurlu/uğursuz qeyd
CREATE OR REPLACE FUNCTION audit.log_login(
  p_username VARCHAR,
  p_status VARCHAR,
  p_ip INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_tailscale VARCHAR DEFAULT NULL,
  p_failure_reason VARCHAR DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
  u_id INT;
  log_id BIGINT;
BEGIN
  SELECT id INTO u_id FROM audit.users WHERE username = p_username;
  
  INSERT INTO audit.login_history (
    user_id, username, status, failure_reason,
    ip_address, user_agent, tailscale_name
  ) VALUES (
    u_id, p_username, p_status, p_failure_reason,
    p_ip, p_user_agent, p_tailscale
  ) RETURNING id INTO log_id;
  
  -- Uğurlu login-də user-in last_login-nu yenilə
  IF p_status = 'success' AND u_id IS NOT NULL THEN
    UPDATE audit.users 
      SET last_login = NOW(), last_ip = p_ip, failed_attempts = 0
      WHERE id = u_id;
  END IF;
  
  -- Uğursuz cəhd — failed_attempts artır
  IF p_status = 'failed' AND u_id IS NOT NULL THEN
    UPDATE audit.users 
      SET failed_attempts = failed_attempts + 1,
          locked_until = CASE WHEN failed_attempts + 1 >= 5 
                              THEN NOW() + INTERVAL '15 minutes' 
                              ELSE locked_until END
      WHERE id = u_id;
  END IF;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- ═══════════════════════════════════════════════════════════════
-- 9. REPORTING VIEW-lar (audit görüntüsü üçün)
-- ═══════════════════════════════════════════════════════════════

-- Aktiv istifadəçilər
CREATE OR REPLACE VIEW audit.v_active_users AS
SELECT 
  u.id, u.username, u.full_name, u.role, u.email, u.position,
  d.name_az AS department,
  r.name_az AS region,
  u.last_login, u.last_ip, u.failed_attempts,
  CASE WHEN u.locked_until > NOW() THEN 'Bloklanıb' ELSE 'Aktiv' END AS status,
  u.created_at
FROM audit.users u
LEFT JOIN hr.departments d ON u.department_id = d.id
LEFT JOIN geo.regions r ON u.region_id = r.id
WHERE u.is_active;

-- Son 24 saatın aktivliyi
CREATE OR REPLACE VIEW audit.v_recent_activity AS
SELECT 
  ql.id, ql.created_at,
  ql.username, ql.user_role,
  ql.action, ql.resource, ql.resource_id,
  ql.source, ql.ip_address, ql.tailscale_name,
  ql.duration_ms, ql.status,
  ql.ai_tokens_input, ql.ai_tokens_output, ql.ai_cost_usd,
  LEFT(ql.query_text, 100) AS query_preview,
  CASE 
    WHEN ql.action = 'AI_QUERY' THEN '🤖 AI'
    WHEN ql.action = 'SELECT'   THEN '👁️ Oxuma'
    WHEN ql.action = 'INSERT'   THEN '➕ Əlavə'
    WHEN ql.action = 'UPDATE'   THEN '✏️ Dəyişdirmə'
    WHEN ql.action = 'DELETE'   THEN '🗑️ Silmək'
    WHEN ql.action = 'LOGIN'    THEN '🔑 Giriş'
    WHEN ql.action = 'LOGOUT'   THEN '🚪 Çıxış'
    WHEN ql.action = 'EXPORT'   THEN '📤 Eksport'
    ELSE ql.action::TEXT
  END AS action_label
FROM audit.query_log ql
WHERE ql.created_at > NOW() - INTERVAL '24 hours'
ORDER BY ql.created_at DESC;

-- İstifadəçi statistikası (dashboard üçün)
CREATE OR REPLACE VIEW audit.v_user_stats AS
SELECT 
  u.id, u.username, u.full_name, u.role,
  COUNT(ql.id)                                   AS total_queries,
  COUNT(ql.id) FILTER (WHERE ql.action = 'AI_QUERY') AS ai_queries,
  COUNT(ql.id) FILTER (WHERE ql.action IN ('INSERT','UPDATE','DELETE')) AS modifications,
  COALESCE(SUM(ql.ai_cost_usd), 0)               AS total_ai_cost,
  MAX(ql.created_at)                             AS last_activity,
  COUNT(DISTINCT ql.ip_address)                  AS unique_ips
FROM audit.users u
LEFT JOIN audit.query_log ql ON ql.user_id = u.id 
  AND ql.created_at > NOW() - INTERVAL '30 days'
WHERE u.is_active
GROUP BY u.id, u.username, u.full_name, u.role;

-- Top sorğu edənlər
CREATE OR REPLACE VIEW audit.v_top_users AS
SELECT 
  username, user_role,
  COUNT(*) AS query_count,
  COUNT(DISTINCT DATE(created_at)) AS active_days,
  MAX(created_at) AS last_query
FROM audit.query_log
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY username, user_role
ORDER BY query_count DESC
LIMIT 10;

-- IP address statistikası (təhlükəsizlik üçün)
CREATE OR REPLACE VIEW audit.v_ip_stats AS
SELECT 
  ip_address,
  tailscale_name,
  COUNT(*) AS total_requests,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(*) FILTER (WHERE status = 'error') AS errors,
  COUNT(*) FILTER (WHERE status = 'denied') AS denied,
  MIN(created_at) AS first_seen,
  MAX(created_at) AS last_seen
FROM audit.query_log
WHERE created_at > NOW() - INTERVAL '7 days'
  AND ip_address IS NOT NULL
GROUP BY ip_address, tailscale_name
ORDER BY total_requests DESC;

-- ═══════════════════════════════════════════════════════════════
-- 10. İLK ADMIN ve TEST istifadəçiləri
-- ═══════════════════════════════════════════════════════════════
-- Default admin: username=admin, password=admin123 (İLK GİRİŞDƏ DƏYİŞDİRİLMƏLİ!)
-- bcrypt hash of 'admin123' (rounds=10)
INSERT INTO audit.users (username, password_hash, full_name, email, role, position, is_verified, must_change_pwd, created_at)
VALUES 
  ('admin', '$2b$10$rJOu6vJvMZzW.9xZn0JQx.iPfK7xQp6TzO5K3F6gH3hXbN8v7d7xa', 
   'Talıbov Tariyel İsmayıl oğlu', 'talibovtariyel@gmail.com', 'admin', 
   'Müavin Direktor', TRUE, TRUE, NOW()),
  ('demo_editor', '$2b$10$rJOu6vJvMZzW.9xZn0JQx.iPfK7xQp6TzO5K3F6gH3hXbN8v7d7xa',
   'Test Editor', 'editor@arti.az', 'editor',
   'Layihə meneceri', TRUE, TRUE, NOW()),
  ('demo_viewer', '$2b$10$rJOu6vJvMZzW.9xZn0JQx.iPfK7xQp6TzO5K3F6gH3hXbN8v7d7xa',
   'Test Viewer', 'viewer@arti.az', 'viewer',
   'İşçi', TRUE, TRUE, NOW())
ON CONFLICT (username) DO NOTHING;

-- ─── YOXLAMA ───
\echo ''
\echo '═══ AUDİT SİSTEMİ QURULDU ═══'
SELECT 'Cədvəllər: '    || COUNT(*) FROM information_schema.tables 
  WHERE table_schema = 'audit' AND table_type = 'BASE TABLE';
SELECT 'View-lar: '      || COUNT(*) FROM information_schema.views
  WHERE table_schema = 'audit';
SELECT 'İstifadəçilər: '|| COUNT(*) FROM audit.users;
SELECT 'Hüquqlar: '     || COUNT(*) FROM audit.permissions;
SELECT 'Funksiyalar: '  || COUNT(*) FROM information_schema.routines
  WHERE routine_schema = 'audit';

\echo ''
\echo '═══ ROLLAR VƏ HÜQUQLAR ═══'
SELECT role, resource, 
       CASE WHEN can_select THEN '✅' ELSE '❌' END AS "Oxu",
       CASE WHEN can_insert THEN '✅' ELSE '❌' END AS "Əlavə",
       CASE WHEN can_update THEN '✅' ELSE '❌' END AS "Dəyiş",
       CASE WHEN can_delete THEN '✅' ELSE '❌' END AS "Sil"
FROM audit.permissions
WHERE resource IN ('projects','budgets','users','ai_query','audit_log')
ORDER BY role, resource;

\echo ''
\echo '═══ TEST İSTİFADƏÇİLƏR (password: admin123) ═══'
SELECT username, full_name, role, position, is_verified FROM audit.users;
