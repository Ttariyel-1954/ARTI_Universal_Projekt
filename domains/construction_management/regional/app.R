# ═══════════════════════════════════════════════════════════════
# ARTI Regional Mobile App v2.0
# Mobile-first iOS/Android dizayn + Smart DB + Material İdarəsi
# Müəllif: Talıbov Tariyel İsmayıl oğlu, ARTI
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({
  library(shiny)
  library(DBI)
  library(RPostgres)
  library(pool)
  library(dplyr)
  library(DT)
  library(shinyjs)
  library(bcrypt)
  library(yaml)
})

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

# Config faylından oxu
CONFIG_PATH <- path.expand("~/Desktop/ARTI_Universal_Platform/shared/config.yml")
if (!file.exists(CONFIG_PATH)) {
  stop("config.yml tapılmadı: ", CONFIG_PATH)
}
cfg <- yaml::read_yaml(CONFIG_PATH)

# .env faylını da yüklə (API key üçün)
env_path <- path.expand("~/Desktop/ARTI_Universal_Platform/shared/.env")
if (file.exists(env_path)) {
  lines <- readLines(env_path, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (line == "" || startsWith(line, "#")) next
    if (grepl("=", line, fixed = TRUE)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      key <- trimws(parts[1])
      val <- gsub('^["\']|["\']$', "", trimws(paste(parts[-1], collapse = "=")))
      if (Sys.getenv(key) == "") do.call(Sys.setenv, setNames(list(val), key))
    }
  }
}

# Upload konfiqurasiyası
UPLOADS_DIR <- path.expand(cfg$uploads$directory)
MAX_FILE_SIZE <- cfg$uploads$max_file_size_mb * 1024 * 1024
ALLOWED_TYPES <- unlist(cfg$uploads$allowed_types)
ALLOWED_EXT <- unlist(cfg$uploads$allowed_extensions)
options(shiny.maxRequestSize = MAX_FILE_SIZE)

# Qovluqları yarat (yoxsa)
for (sub in c("inspections", "complaints", "daily_reports", 
              "material_movements", "thumbnails")) {
  d <- file.path(UPLOADS_DIR, sub)
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# ═══════════════════════════════════════════════════════════════
# SMART DATABASE CONNECTION
# ═══════════════════════════════════════════════════════════════

detect_db_host <- function(cfg) {
  mode <- cfg$database$mode %||% "smart"
  
  if (mode == "localhost") {
    return(list(host = cfg$database$localhost$host, 
                port = cfg$database$localhost$port,
                source = "localhost"))
  }
  
  if (mode == "tailscale") {
    return(list(host = cfg$database$tailscale$host,
                port = cfg$database$tailscale$port,
                source = "tailscale"))
  }
  
  # Smart mode: localhost əvvəl sına, sonra Tailscale
  try_localhost <- tryCatch({
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      host = cfg$database$localhost$host,
      port = cfg$database$localhost$port,
      dbname = cfg$database$localhost$dbname,
      user = cfg$database$localhost$user,
      password = cfg$database$localhost$password,
      connect_timeout = cfg$database$connect_timeout_sec %||% 5
    )
    DBI::dbDisconnect(con)
    TRUE
  }, error = function(e) FALSE)
  
  if (try_localhost) {
    message("✅ Localhost DB aktiv - istifadə olunur")
    return(list(host = cfg$database$localhost$host,
                port = cfg$database$localhost$port,
                source = "localhost"))
  }
  
  # Localhost yoxdursa, Tailscale sına
  try_tailscale <- tryCatch({
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      host = cfg$database$tailscale$host,
      port = cfg$database$tailscale$port,
      dbname = cfg$database$tailscale$dbname,
      user = cfg$database$tailscale$user,
      password = cfg$database$tailscale$password,
      connect_timeout = cfg$database$connect_timeout_sec %||% 5
    )
    DBI::dbDisconnect(con)
    TRUE
  }, error = function(e) FALSE)
  
  if (try_tailscale) {
    message("✅ Tailscale DB aktiv - mərkəzi serverə qoşuldu")
    return(list(host = cfg$database$tailscale$host,
                port = cfg$database$tailscale$port,
                source = "tailscale"))
  }
  
  stop("❌ Heç bir DB-yə qoşulmaq olmur! Config.yml-ı yoxlayın.")
}

# NULL-safe operator
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# DB connection
db_info <- detect_db_host(cfg)
message("═══ DB Source: ", db_info$source, " (", db_info$host, ":", db_info$port, ") ═══")

# Config-dan hansı credentials götürməliyik
db_creds <- if (db_info$source == "localhost") cfg$database$localhost else cfg$database$tailscale

pool <- pool::dbPool(
  RPostgres::Postgres(),
  host = db_info$host,
  port = db_info$port,
  dbname = db_creds$dbname,
  user = db_creds$user,
  password = db_creds$password,
  minSize = cfg$database$pool_min %||% 2,
  maxSize = cfg$database$pool_max %||% 10
)

onStop(function() {
  if (!is.null(pool) && pool$valid) try(poolClose(pool), silent = TRUE)
})

# ═══════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════

safe_query <- function(sql, params = NULL) {
  tryCatch({
    if (is.null(params)) {
      res <- dbGetQuery(pool, sql)
    } else {
      res <- dbGetQuery(pool, sql, params = params)
    }
    for (col in names(res)) {
      if (inherits(res[[col]], "integer64")) {
        res[[col]] <- as.numeric(res[[col]])
      }
    }
    res
  }, error = function(e) {
    message("SQL xəta: ", e$message)
    data.frame()
  })
}

safe_execute <- function(sql, params = NULL) {
  tryCatch({
    if (is.null(params)) {
      dbExecute(pool, sql)
    } else {
      dbExecute(pool, sql, params = params)
    }
  }, error = function(e) {
    message("SQL execute xəta: ", e$message)
    -1
  })
}

# NULL/empty → NA converter (RPostgres üçün)
na_safe <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  as.character(x)
}

na_int <- function(x) {
  if (is.null(x) || length(x) == 0 || x == "" || x == "0") return(NA_integer_)
  as.integer(x)
}

# Connection info (IP, tailscale)
get_connection_info <- function(session) {
  list(
    ip = session$request$REMOTE_ADDR %||% "127.0.0.1",
    tailscale = NA_character_,
    user_agent = session$request$HTTP_USER_AGENT %||% NA_character_
  )
}

# Audit log yaz
log_action <- function(user_id, action, resource = NULL, 
                       query_text = NULL, status = "success",
                       ip = NULL) {
  if (is.null(user_id)) return(invisible(NULL))
  
  tryCatch({
    dbExecute(pool, "
      INSERT INTO audit.query_log (
        user_id, username, user_role, action, resource, 
        query_text, source, status, ip_address
      )
      SELECT $1, username, role, $2, $3, $4, 'mobile', $5, $6::inet
      FROM audit.users WHERE id = $1
    ", params = list(
      as.integer(user_id),
      na_safe(action),
      na_safe(resource),
      substr(na_safe(query_text), 1, 500),
      na_safe(status),
      na_safe(ip)
    ))
  }, error = function(e) message("Log xəta: ", e$message))
}

# Fayl yüklə
save_attachment <- function(file_info, parent_table, parent_id, 
                             attachment_type, user_id, ip_addr = NULL) {
  tryCatch({
    ext <- tolower(tools::file_ext(file_info$name))
    if (!ext %in% ALLOWED_EXT) {
      return(list(success = FALSE, 
                  error = paste0("Yalnız ", paste(ALLOWED_EXT, collapse=", "), " qəbul edilir")))
    }
    
    if (file_info$size > MAX_FILE_SIZE) {
      return(list(success = FALSE, 
                  error = paste0("Fayl çox böyükdür (", round(file_info$size/1024/1024, 1), " MB). Max: 5 MB")))
    }
    
    sub_dir <- switch(parent_table,
      "inspections" = "inspections",
      "citizen_complaints" = "complaints",
      "daily_reports" = "daily_reports",
      "material_transactions" = "material_movements",
      "other"
    )
    
    target_dir <- file.path(UPLOADS_DIR, sub_dir)
    if (!dir.exists(target_dir)) dir.create(target_dir, recursive = TRUE)
    
    timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
    safe_orig <- gsub("[^A-Za-z0-9._-]", "_", file_info$name)
    stored_name <- paste0(timestamp, "_u", user_id, "_", safe_orig)
    target_path <- file.path(target_dir, stored_name)
    
    file.copy(file_info$datapath, target_path, overwrite = FALSE)
    
    mime_v <- file_info$type
    if (is.null(mime_v) || mime_v == "") {
      mime_v <- switch(ext,
        "jpg" = "image/jpeg", "jpeg" = "image/jpeg",
        "png" = "image/png", "pdf" = "application/pdf",
        "application/octet-stream")
    }
    
    new_id <- dbGetQuery(pool, "
      SELECT construction.add_attachment(
        $1, $2, $3, $4, $5, $6, $7, $8, $9, 'mobile', $10
      ) AS id
    ", params = list(
      attachment_type, parent_table, as.integer(parent_id),
      file_info$name, stored_name, target_path, 
      as.numeric(file_info$size), mime_v, as.integer(user_id),
      ip_addr
    ))
    
    return(list(
      success = TRUE, 
      id = new_id$id[1], 
      filename = file_info$name,
      size_kb = round(file_info$size / 1024, 1)
    ))
  }, error = function(e) {
    return(list(success = FALSE, error = paste("Xəta:", e$message)))
  })
}
# ═══════════════════════════════════════════════════════════════
# CSS — MODERN iOS/ANDROID DİZAYN
# ═══════════════════════════════════════════════════════════════

mobile_css <- "
:root {
  --primary: #059669;
  --primary-dark: #047857;
  --primary-light: #10b981;
  --primary-bg: #d1fae5;
  --primary-bg-soft: #f0fdf4;
  
  --danger: #dc2626;
  --warning: #f59e0b;
  --info: #0369a1;
  --success: #10b981;
  
  --text-primary: #0f172a;
  --text-secondary: #475569;
  --text-muted: #94a3b8;
  
  --bg-main: #f8fafc;
  --bg-card: #ffffff;
  --bg-hover: #f0fdf4;
  
  --border-light: #e2e8f0;
  --border-soft: #f1f5f9;
  
  --shadow-sm: 0 1px 3px rgba(0,0,0,0.04);
  --shadow-md: 0 4px 12px rgba(0,0,0,0.08);
  --shadow-lg: 0 10px 30px rgba(16,185,129,0.15);
  
  --radius-sm: 10px;
  --radius-md: 14px;
  --radius-lg: 20px;
  
  --ease: cubic-bezier(0.4, 0, 0.2, 1);
}

* { 
  box-sizing: border-box; 
  -webkit-tap-highlight-color: transparent;
}

body { 
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, sans-serif;
  background: var(--bg-main);
  color: var(--text-primary);
  margin: 0; 
  padding: 0;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  overscroll-behavior: none;
}

.container-fluid, .row, .col-sm-12 {
  margin: 0 !important;
  padding: 0 !important;
}

/* ═══ APP ƏSAS KONTEYNER ═══ */
.app-container {
  max-width: 500px;
  margin: 0 auto;
  min-height: 100vh;
  background: var(--bg-main);
  position: relative;
  padding-bottom: 80px;
}

/* ═══ HEADER ═══ */
.mobile-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
  color: white;
  padding: env(safe-area-inset-top, 20px) 20px 20px 20px;
  box-shadow: var(--shadow-md);
}

.mobile-header h1 {
  font-size: 22px;
  font-weight: 800;
  margin: 0 0 4px 0;
  letter-spacing: -0.5px;
}

.mobile-header .subtitle {
  font-size: 13px;
  opacity: 0.9;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 6px;
}

.mobile-header .connection-badge {
  display: inline-block;
  background: rgba(255,255,255,0.2);
  padding: 3px 10px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 600;
  margin-left: auto;
}

.mobile-header .header-flex {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logout-btn {
  background: rgba(255,255,255,0.15);
  border: none;
  color: white;
  padding: 8px 12px;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.2s var(--ease);
}
.logout-btn:active { background: rgba(255,255,255,0.3); }

/* ═══ CONTENT AREA ═══ */
.mobile-content {
  padding: 16px;
}

/* ═══ STATS CARDS ═══ */
.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-bottom: 20px;
}

.stat-card {
  background: var(--bg-card);
  border-radius: var(--radius-md);
  padding: 16px;
  box-shadow: var(--shadow-sm);
  border-left: 4px solid var(--primary);
  text-align: center;
  animation: slideUp 0.4s var(--ease) backwards;
}
.stat-card:nth-child(1) { animation-delay: 0.05s; }
.stat-card:nth-child(2) { animation-delay: 0.1s; }

.stat-value {
  font-size: 28px;
  font-weight: 800;
  color: var(--primary-dark);
  margin: 0;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}

.stat-label {
  font-size: 11px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-top: 6px;
  font-weight: 600;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

/* ═══ SECTION TITLE ═══ */
.section-title {
  font-size: 12px;
  font-weight: 700;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 1.2px;
  margin: 24px 4px 12px 4px;
}

/* ═══ ACTION CARDS (KLIK) ═══ */
.action-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.action-card {
  display: flex;
  align-items: center;
  gap: 14px;
  background: var(--bg-card);
  padding: 18px;
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
  cursor: pointer;
  transition: all 0.2s var(--ease);
  border: 1px solid transparent;
  animation: slideUp 0.4s var(--ease) backwards;
  user-select: none;
}
.action-card:nth-child(1) { animation-delay: 0.15s; }
.action-card:nth-child(2) { animation-delay: 0.2s; }
.action-card:nth-child(3) { animation-delay: 0.25s; }
.action-card:nth-child(4) { animation-delay: 0.3s; }
.action-card:nth-child(5) { animation-delay: 0.35s; }

.action-card:hover { 
  background: var(--bg-hover);
  border-color: var(--primary-light);
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.action-card:active { 
  transform: scale(0.98);
  background: var(--primary-bg);
}

.action-icon {
  flex-shrink: 0;
  width: 52px;
  height: 52px;
  border-radius: 14px;
  background: var(--primary-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 26px;
  transition: transform 0.2s var(--ease);
}
.action-card:hover .action-icon {
  transform: scale(1.1) rotate(-5deg);
}

.action-icon.danger { background: #fee2e2; }
.action-icon.warning { background: #fef3c7; }
.action-icon.info { background: #dbeafe; }
.action-icon.purple { background: #ede9fe; }

.action-text {
  flex: 1;
  min-width: 0;
}

.action-title {
  font-weight: 700;
  font-size: 16px;
  color: var(--text-primary);
  margin: 0 0 2px 0;
  line-height: 1.3;
}

.action-desc {
  font-size: 13px;
  color: var(--text-muted);
  margin: 0;
  line-height: 1.4;
}

.action-arrow {
  color: var(--text-muted);
  font-size: 22px;
  font-weight: 300;
  flex-shrink: 0;
}

/* ═══ FORMS ═══ */
.form-container {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: var(--shadow-sm);
}

.form-container h3 {
  margin: 0 0 16px 0;
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
}

.form-group { margin-bottom: 16px; }
.form-group label {
  display: block;
  font-weight: 600;
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 6px;
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.form-control, 
input[type='text'], 
input[type='number'],
input[type='password'],
input[type='email'],
select, 
textarea {
  width: 100% !important;
  padding: 12px 14px !important;
  border: 2px solid var(--border-light) !important;
  border-radius: var(--radius-sm) !important;
  font-size: 15px !important;
  background: var(--bg-card) !important;
  transition: border-color 0.2s var(--ease) !important;
  font-family: inherit !important;
}

.form-control:focus,
input:focus,
select:focus,
textarea:focus {
  outline: none !important;
  border-color: var(--primary) !important;
  box-shadow: 0 0 0 3px rgba(16,185,129,0.1) !important;
}

textarea { 
  min-height: 80px !important; 
  resize: vertical !important; 
}

/* ═══ BUTTONS ═══ */
.btn-mobile {
  width: 100%;
  padding: 15px;
  border: none;
  border-radius: 14px;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s var(--ease);
  margin-top: 8px;
  margin-bottom: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  letter-spacing: 0.3px;
}

.btn-primary-mobile {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
}
.btn-primary-mobile:active {
  transform: scale(0.98);
  box-shadow: 0 2px 6px rgba(16,185,129,0.25);
}

.btn-success-mobile {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(16,185,129,0.3);
}
.btn-success-mobile:active {
  transform: scale(0.98);
}

.btn-secondary-mobile {
  background: #f1f5f9;
  color: var(--text-secondary);
}
.btn-secondary-mobile:active {
  background: #e2e8f0;
  transform: scale(0.98);
}

.btn-danger-mobile {
  background: linear-gradient(135deg, #dc2626 0%, #ef4444 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(220,38,38,0.25);
}
.btn-danger-mobile:active {
  transform: scale(0.98);
}

/* ═══ SLIDER ═══ */
.irs--shiny .irs-bar {
  background: linear-gradient(to right, var(--primary), var(--primary-light));
  border: none;
  top: 25px;
  height: 8px;
}
.irs--shiny .irs-line { 
  background: #e2e8f0; 
  border: none;
  top: 25px;
  height: 8px;
}
.irs--shiny .irs-handle {
  width: 24px;
  height: 24px;
  top: 17px;
  background: white;
  border: 3px solid var(--primary);
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.irs--shiny .irs-single, 
.irs--shiny .irs-from, 
.irs--shiny .irs-to {
  background: var(--primary);
  color: white;
  font-weight: 600;
}

/* ═══ CHECKBOX ═══ */
.checkbox label, 
.form-check label {
  font-size: 15px;
  color: var(--text-primary);
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  background: var(--primary-bg-soft);
  border-radius: var(--radius-sm);
  transition: background 0.15s var(--ease);
}
.checkbox label:hover,
.form-check label:hover { 
  background: var(--primary-bg); 
}

input[type='checkbox'] {
  width: 20px;
  height: 20px;
  accent-color: var(--primary);
  cursor: pointer;
}

/* ═══ BOTTOM NAVIGATION ═══ */
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--bg-card);
  box-shadow: 0 -2px 15px rgba(0,0,0,0.08);
  padding: 8px 0 env(safe-area-inset-bottom, 8px) 0;
  display: flex;
  justify-content: space-around;
  max-width: 500px;
  margin: 0 auto;
  z-index: 1000;
  border-top: 1px solid var(--border-light);
}

.bottom-nav-item {
  flex: 1;
  text-align: center;
  padding: 8px 4px;
  cursor: pointer;
  transition: all 0.2s var(--ease);
  user-select: none;
  border-radius: 10px;
  margin: 0 3px;
}

.bottom-nav-item:hover,
.bottom-nav-item.active {
  background: var(--primary-bg-soft);
}

.bottom-nav-item .nav-icon {
  font-size: 22px;
  display: block;
  margin-bottom: 3px;
  transition: transform 0.15s var(--ease);
}
.bottom-nav-item:active .nav-icon {
  transform: scale(0.85);
}

.bottom-nav-item .nav-label {
  font-size: 10px;
  color: var(--text-muted);
  font-weight: 600;
  letter-spacing: 0.3px;
  text-transform: uppercase;
}

.bottom-nav-item.active .nav-label,
.bottom-nav-item:hover .nav-label {
  color: var(--primary);
}

/* ═══ LOGIN PAGE ═══ */
.login-container {
  max-width: 420px;
  margin: 0 auto;
  padding: 40px 20px;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  background: linear-gradient(180deg, #f0fdf4 0%, #dbeafe 100%);
}

.login-logo {
  text-align: center;
  margin-bottom: 30px;
  animation: slideUp 0.6s var(--ease);
}

.login-logo .emoji {
  font-size: 64px;
  margin-bottom: 10px;
  display: block;
}

.login-logo h1 {
  font-size: 28px;
  font-weight: 800;
  color: var(--primary-dark);
  margin: 0 0 8px 0;
}

.login-logo .subtitle {
  color: var(--text-secondary);
  font-size: 15px;
  margin: 0;
}

.login-card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: 30px 24px;
  box-shadow: 0 20px 50px rgba(0,0,0,0.08);
  animation: slideUp 0.6s var(--ease) 0.1s backwards;
}

.login-error {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px 14px;
  border-radius: var(--radius-sm);
  font-size: 14px;
  margin-bottom: 15px;
  border-left: 4px solid var(--danger);
  font-weight: 500;
}

.login-success {
  background: var(--primary-bg);
  color: var(--primary-dark);
  padding: 12px 14px;
  border-radius: var(--radius-sm);
  font-size: 14px;
  margin-bottom: 15px;
  border-left: 4px solid var(--primary);
}

.demo-info {
  margin-top: 16px;
  padding: 12px;
  background: #f1f5f9;
  border-radius: var(--radius-sm);
  font-size: 12px;
  color: var(--text-secondary);
  text-align: center;
  font-family: 'SF Mono', Menlo, monospace;
}

/* ═══ LIST ITEMS (layihələr və s.) ═══ */
.list-item {
  background: var(--bg-card);
  border-radius: var(--radius-md);
  padding: 16px;
  margin-bottom: 10px;
  box-shadow: var(--shadow-sm);
  border-left: 4px solid var(--primary);
  animation: slideUp 0.3s var(--ease) backwards;
}

.list-item-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.list-item-title {
  font-weight: 700;
  font-size: 15px;
  color: var(--text-primary);
  margin: 0;
}

.list-item-badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
}

.status-completed { background: var(--primary-bg); color: var(--primary-dark); }
.status-active    { background: #dbeafe; color: #1e40af; }
.status-planned   { background: #fef3c7; color: #92400e; }

.list-item-meta {
  font-size: 12px;
  color: var(--text-muted);
  margin: 2px 0;
}

.list-item-progress {
  height: 6px;
  background: var(--border-soft);
  border-radius: 3px;
  overflow: hidden;
  margin-top: 8px;
}
.list-item-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--primary), var(--primary-light));
  border-radius: 3px;
  transition: width 0.5s var(--ease);
}

/* ═══ FILE UPLOAD ═══ */
.file-upload-section {
  background: var(--primary-bg-soft);
  border: 2px dashed var(--primary-light);
  border-radius: var(--radius-md);
  padding: 16px;
  margin: 12px 0;
  transition: background 0.2s var(--ease);
}

.file-upload-section:hover {
  background: var(--primary-bg);
}

.file-upload-section h4 {
  color: var(--primary-dark);
  font-size: 13px;
  margin: 0 0 10px 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 700;
}

.attached-list { margin-top: 10px; }
.attached-item {
  display: flex;
  align-items: center;
  gap: 10px;
  background: white;
  padding: 10px 12px;
  border-radius: 10px;
  margin: 6px 0;
  border-left: 3px solid var(--primary-light);
  font-size: 13px;
}

.attached-icon { font-size: 24px; }
.attached-info { flex: 1; min-width: 0; }
.attached-name { 
  font-weight: 600; 
  color: var(--primary-dark); 
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.attached-size { color: var(--text-muted); font-size: 11px; }

/* ═══ MATERIAL ═══ */
.material-action-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 10px;
}

.material-action-card {
  background: var(--bg-card);
  border-radius: var(--radius-md);
  padding: 20px 14px;
  text-align: center;
  cursor: pointer;
  box-shadow: var(--shadow-sm);
  transition: all 0.2s var(--ease);
  user-select: none;
  border: 2px solid transparent;
}

.material-action-card:active {
  transform: scale(0.96);
}

.material-action-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-lg);
}

.material-action-card.in:hover { border-color: var(--primary-light); }
.material-action-card.out:hover { border-color: #f59e0b; }
.material-action-card.waste:hover { border-color: var(--danger); }
.material-action-card.ret:hover { border-color: #8b5cf6; }

.material-action-icon {
  font-size: 32px;
  margin-bottom: 8px;
  display: block;
}

.material-action-title {
  font-weight: 700;
  font-size: 14px;
  color: var(--text-primary);
  margin: 0;
}

.material-action-desc {
  font-size: 11px;
  color: var(--text-muted);
  margin-top: 2px;
}

.stock-item {
  background: var(--bg-card);
  border-radius: 12px;
  padding: 12px 14px;
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: var(--shadow-sm);
  border-left: 4px solid var(--primary);
}

.stock-item.low {
  border-left-color: var(--warning);
  background: #fffbeb;
}

.stock-item.critical {
  border-left-color: var(--danger);
  background: #fef2f2;
}

.stock-name { 
  font-weight: 600; 
  color: var(--text-primary);
  font-size: 14px;
}

.stock-meta { 
  font-size: 12px; 
  color: var(--text-muted);
  margin-top: 2px;
}

.stock-qty {
  font-weight: 800;
  font-size: 16px;
  color: var(--primary-dark);
  font-variant-numeric: tabular-nums;
}

.stock-qty.low { color: var(--warning); }
.stock-qty.critical { color: var(--danger); }

/* ═══ LOADING & EMPTY STATES ═══ */
.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-muted);
}

.empty-state .emoji {
  font-size: 48px;
  margin-bottom: 12px;
  display: block;
  opacity: 0.6;
}

.empty-state h4 {
  margin: 0 0 6px 0;
  color: var(--text-secondary);
  font-size: 16px;
}

.empty-state p {
  margin: 0;
  font-size: 13px;
}

/* ═══ NOTIFICATION TOASTS ═══ */
.shiny-notification {
  border-radius: 14px !important;
  font-weight: 600;
  box-shadow: var(--shadow-md) !important;
  max-width: 420px;
  font-family: inherit !important;
}

/* ═══ RESPONSIVE ═══ */
@media (min-width: 501px) {
  .app-container {
    margin-top: 20px;
    margin-bottom: 20px;
    border-radius: 24px;
    overflow: hidden;
    min-height: calc(100vh - 40px);
    box-shadow: 0 20px 60px rgba(0,0,0,0.1);
  }
  .bottom-nav {
    border-radius: 0 0 24px 24px;
  }
}

/* Scrollbar yaxşılaşdırılmış */
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { 
  background: var(--text-muted); 
  border-radius: 3px; 
  opacity: 0.3;
}
"
# ═══════════════════════════════════════════════════════════════
# PAGE BUILDERS (Səhifə UI funksiyaları)
# ═══════════════════════════════════════════════════════════════

# Helper: action card div (klik ilə)
action_card <- function(input_id, icon, title, desc, icon_class = "") {
  div(
    class = "action-card",
    onclick = sprintf("Shiny.setInputValue('%s', Math.random());", input_id),
    div(class = paste("action-icon", icon_class), icon),
    div(class = "action-text",
      tags$p(class = "action-title", title),
      tags$p(class = "action-desc", desc)
    ),
    div(class = "action-arrow", HTML("&rsaquo;"))
  )
}

# Material action card (kvadrat, material əməliyyatları)
material_action_card <- function(input_id, icon, title, desc, variant) {
  div(
    class = paste("material-action-card", variant),
    onclick = sprintf("Shiny.setInputValue('%s', Math.random());", input_id),
    tags$span(class = "material-action-icon", icon),
    tags$p(class = "material-action-title", title),
    tags$p(class = "material-action-desc", desc)
  )
}

# ═══ LOGIN SƏHİFƏSİ ═══
page_login <- function() {
  div(class = "login-container",
    div(class = "login-logo",
      tags$span(class = "emoji", "🏗️"),
      h1("ARTI Regional"),
      tags$p(class = "subtitle", "Bölgə işçi paneli")
    ),
    div(class = "login-card",
      uiOutput("login_message"),
      div(class = "form-group",
        tags$label("İstifadəçi adı"),
        textInput("login_user", NULL, 
                  placeholder = "rw_01, rw_02, ...",
                  width = "100%")
      ),
      div(class = "form-group",
        tags$label("Şifrə"),
        passwordInput("login_pass", NULL,
                      placeholder = "••••••••",
                      width = "100%")
      ),
      actionButton("do_login", "Daxil ol",
                   class = "btn-mobile btn-primary-mobile",
                   icon = icon("right-to-bracket")),
      div(class = "demo-info",
        HTML("<strong>Demo:</strong> rw_01 / regional123")
      )
    )
  )
}

# ═══ HOME (ANA SƏHİFƏ) ═══
page_home <- function(user_data, stats) {
  tagList(
    # Stats
    div(class = "stats-grid",
      div(class = "stat-card",
        tags$p(class = "stat-value", stats$weekly_inspections %||% 0),
        tags$p(class = "stat-label", "Bu həftə yoxlama")
      ),
      div(class = "stat-card",
        tags$p(class = "stat-value", stats$open_complaints %||% 0),
        tags$p(class = "stat-label", "Açıq şikayət")
      )
    ),
    
    # Quick actions
    tags$h3(class = "section-title", "Sürətli əməliyyatlar"),
    div(class = "action-list",
      action_card("quick_inspect", "🔍", "Yeni Yoxlama", 
                  "Layihə üzrə keyfiyyət qiymətləndirməsi"),
      action_card("quick_complaint", "📧", "Şikayət Qeydə Al",
                  "Vətəndaşdan gələn müraciət", "warning"),
      action_card("quick_report", "📋", "Gündəlik Hesabat",
                  "Bu günkü iş haqqında", "info"),
      action_card("quick_material", "📦", "Material İdarəsi",
                  "Anbar əməliyyatları və qalıqlar", "purple"),
      action_card("quick_projects", "🏗️", "Mənim Layihələrim",
                  "Region üzrə bütün layihələr")
    )
  )
}

# ═══ YOXLAMA FORMA ═══
page_inspect <- function(projects) {
  project_choices <- c("— Layihə seçin —" = "0")
  if (nrow(projects) > 0) {
    project_choices <- c(project_choices, 
                         setNames(as.character(projects$id),
                                  paste0(projects$project_code, " — ", 
                                         substr(projects$name, 1, 40))))
  }
  
  div(class = "form-container",
    h3("🔍 Yeni Yoxlama"),
    
    div(class = "form-group",
      tags$label("Layihə"),
      selectInput("ins_project", NULL, choices = project_choices, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Yoxlama növü"),
      selectInput("ins_type", NULL,
        choices = c(
          "Planlı yoxlama" = "planned",
          "Planxarici" = "unplanned",
          "Vətəndaş şikayəti əsaslı" = "citizen",
          "Təhvil yoxlaması" = "final"
        ), width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Keyfiyyət balı (1-10)"),
      sliderInput("ins_quality", NULL,
                  min = 1, max = 10, value = 7, step = 0.5,
                  width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Tapılan nöqsan sayı"),
      numericInput("ins_issues_found", NULL, value = 0, min = 0, max = 100, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Həll olunan nöqsanlar"),
      numericInput("ins_issues_resolved", NULL, value = 0, min = 0, max = 100, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Yoxlama hesabatı"),
      textAreaInput("ins_report", NULL,
                    placeholder = "Detallı qeyd, müşahidələr, tövsiyələr...",
                    rows = 4, width = "100%")
    ),
    
    div(class = "form-group",
      checkboxInput("ins_followup", "Təkrar yoxlama tələb olunur", value = FALSE)
    ),
    
    # FAYL YÜKLƏMƏ
    div(class = "file-upload-section",
      h4("📸 Foto/Sənəd əlavə et"),
      fileInput("ins_files", NULL,
                multiple = TRUE,
                accept = c("image/jpeg", "image/png", "application/pdf"),
                buttonLabel = "Seç...",
                placeholder = "Fayl seçilməyib (max 5 MB)"),
      uiOutput("ins_files_preview")
    ),
    
    actionButton("ins_save", "Yoxlamanı saxla",
                 class = "btn-mobile btn-primary-mobile",
                 icon = icon("save")),
    actionButton("ins_cancel", "Ləğv et",
                 class = "btn-mobile btn-secondary-mobile")
  )
}

# ═══ ŞİKAYƏT FORMA ═══
page_complaint <- function(schools) {
  school_choices <- c("— Məktəb seçimi (isteğe bağlı) —" = "0")
  if (nrow(schools) > 0) {
    school_choices <- c(school_choices,
                        setNames(as.character(schools$id),
                                 substr(schools$name, 1, 50)))
  }
  
  div(class = "form-container",
    h3("📧 Vətəndaş Şikayəti"),
    
    div(class = "form-group",
      tags$label("Vətəndaş adı"),
      textInput("cmp_citizen", NULL,
                placeholder = "Soyad Ad Ata adı",
                width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Əlaqə (telefon/email)"),
      textInput("cmp_contact", NULL,
                placeholder = "050-xxx-xx-xx və ya email",
                width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Məktəb (isteğe bağlı)"),
      selectInput("cmp_school", NULL, choices = school_choices, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Kateqoriya"),
      selectInput("cmp_category", NULL,
        choices = c(
          "İstilik problemi" = "heating",
          "Dam dəliklidi" = "roof",
          "Təhlükəsizlik" = "safety",
          "Elektrik" = "electric",
          "Su və kanalizasiya" = "water",
          "Təmir keyfiyyəti" = "quality",
          "Uzun gecikmə" = "delay",
          "Korrupsiya şübhəsi" = "corruption",
          "Digər" = "other"
        ), width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Urgency (əhəmiyyət)"),
      selectInput("cmp_urgency", NULL,
        choices = c(
          "Normal" = "normal",
          "Yüksək" = "high",
          "Kritik" = "critical"
        ), width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Şikayət mətni"),
      textAreaInput("cmp_text", NULL,
                    placeholder = "Vətəndaşın müraciətini ətraflı qeyd edin...",
                    rows = 5, width = "100%")
    ),
    
    # FAYL YÜKLƏMƏ
    div(class = "file-upload-section",
      h4("📸 Foto/Sənəd əlavə et"),
      fileInput("cmp_files", NULL,
                multiple = TRUE,
                accept = c("image/jpeg", "image/png", "application/pdf"),
                buttonLabel = "Seç...",
                placeholder = "Fayl seçilməyib (max 5 MB)"),
      uiOutput("cmp_files_preview")
    ),
    
    actionButton("cmp_save", "Şikayəti qeydə al",
                 class = "btn-mobile btn-primary-mobile",
                 icon = icon("save")),
    actionButton("cmp_cancel", "Ləğv et",
                 class = "btn-mobile btn-secondary-mobile")
  )
}

# ═══ HESABAT FORMA ═══
page_report <- function(projects) {
  project_choices <- c("— Konkret layihə yox —" = "0")
  if (nrow(projects) > 0) {
    project_choices <- c(project_choices,
                         setNames(as.character(projects$id),
                                  paste0(projects$project_code, " — ",
                                         substr(projects$name, 1, 40))))
  }
  
  div(class = "form-container",
    h3("📋 Gündəlik Hesabat"),
    
    div(class = "form-group",
      tags$label("Layihə (isteğe bağlı)"),
      selectInput("rep_project", NULL, choices = project_choices, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Hava vəziyyəti"),
      selectInput("rep_weather", NULL,
        choices = c(
          "Günəşli ☀️" = "sunny",
          "Buludlu ⛅" = "cloudy",
          "Yağışlı 🌧️" = "rainy",
          "Qarlı ❄️" = "snow"
        ), width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Temperatur (°C)"),
      numericInput("rep_temp", NULL, value = 20, min = -30, max = 50, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("İşçi sayı"),
      numericInput("rep_workers", NULL, value = 0, min = 0, max = 200, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("İş saatı"),
      numericInput("rep_hours", NULL, value = 8, min = 0, max = 24, step = 0.5, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Görülən iş"),
      textAreaInput("rep_done", NULL,
                    placeholder = "Bu gün nə edildi...",
                    rows = 3, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Problemlər"),
      textAreaInput("rep_issues", NULL,
                    placeholder = "Hansısa maneə oldumu?",
                    rows = 3, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Cari icra faizi"),
      sliderInput("rep_progress", NULL,
                  min = 0, max = 100, value = 0, step = 5,
                  post = "%", width = "100%")
    ),
    
    # FAYL YÜKLƏMƏ
    div(class = "file-upload-section",
      h4("📸 Foto/Sənəd əlavə et"),
      fileInput("rep_files", NULL,
                multiple = TRUE,
                accept = c("image/jpeg", "image/png", "application/pdf"),
                buttonLabel = "Seç...",
                placeholder = "Fayl seçilməyib (max 5 MB)"),
      uiOutput("rep_files_preview")
    ),
    
    actionButton("rep_save", "Hesabatı təqdim et",
                 class = "btn-mobile btn-primary-mobile",
                 icon = icon("save")),
    actionButton("rep_cancel", "Ləğv et",
                 class = "btn-mobile btn-secondary-mobile")
  )
}

# ═══ MATERIAL ANA SƏHİFƏSİ ═══
page_material <- function() {
  tagList(
    div(class = "form-container", style = "padding: 16px;",
      h3("📦 Material İdarəsi"),
      tags$p(style = "color: var(--text-muted); font-size: 14px; margin: 0 0 10px 0;",
             "Anbar əməliyyatlarını seçin:"),
      
      div(class = "material-action-grid",
        material_action_card("mat_in", "➕", "Anbara daxil", "Material qəbulu", "in"),
        material_action_card("mat_out", "📤", "Çıxar", "Layihəyə ötür", "out"),
        material_action_card("mat_waste", "❌", "Zədəli", "Silinmə/itki", "waste"),
        material_action_card("mat_return", "🔄", "Qaytarıldı", "Geri qaytar", "ret")
      )
    ),
    
    div(class = "form-container",
      h3("📊 Anbar Qalıqları"),
      tags$p(style = "color: var(--text-muted); font-size: 13px;",
             "Region üzrə anbarlarınızdakı cari məhsul qalıqları:"),
      uiOutput("material_stock_view")
    )
  )
}

# ═══ MATERIAL ƏMƏLİYYAT FORMA (universal) ═══
page_material_action <- function(action_type, warehouses, materials_df) {
  # Labels
  labels <- switch(action_type,
    "in" = list(title = "➕ Anbara daxil", btn = "Qəbul et",
                quantity_label = "Qəbul olunan miqdar",
                reason_label = "Mənbə / Qaimə nömrəsi",
                reason_ph = "Məs. Karol MMC qaiməsi #123"),
    "out" = list(title = "📤 Layihəyə çıxar", btn = "Çıxış et",
                 quantity_label = "Çıxarılan miqdar",
                 reason_label = "Layihə və ya istifadə səbəbi",
                 reason_ph = "Məs. Məktəb 23 təmiri"),
    "waste" = list(title = "❌ Zədəli/İtki kimi sil", btn = "Silməni təsdiq et",
                   quantity_label = "İtki miqdarı",
                   reason_label = "Səbəb",
                   reason_ph = "Məs. Yağış səbəbindən zədələnmə"),
    "return" = list(title = "🔄 Qaytarma", btn = "Qaytarmanı qeyd et",
                    quantity_label = "Qaytarılan miqdar",
                    reason_label = "Qaytarma səbəbi",
                    reason_ph = "Məs. Artıqlıq, səhvən götürülüb")
  )
  
  # Warehouse choices (yalnız region)
  wh_choices <- c("— Anbar seçin —" = "0")
  if (nrow(warehouses) > 0) {
    wh_choices <- c(wh_choices,
                    setNames(as.character(warehouses$id),
                             paste0(warehouses$name, " (", warehouses$code, ")")))
  }
  
  # Material choices
  mat_choices <- c("— Material seçin —" = "0")
  if (nrow(materials_df) > 0) {
    mat_choices <- c(mat_choices,
                     setNames(as.character(materials_df$id),
                              paste0(materials_df$name_az, " [", materials_df$unit, "]")))
  }
  
  div(class = "form-container",
    h3(labels$title),
    
    div(class = "form-group",
      tags$label("Anbar"),
      selectInput("mat_warehouse", NULL, choices = wh_choices, width = "100%")
    ),
    
    div(class = "form-group",
      tags$label("Material"),
      selectInput("mat_material", NULL, choices = mat_choices, width = "100%")
    ),
    
    # Dinamik qalıq göstəricisi
    uiOutput("mat_current_stock"),
    
    div(class = "form-group",
      tags$label(labels$quantity_label),
      numericInput("mat_quantity", NULL, value = 0, min = 0.001, step = 0.1, width = "100%")
    ),
    
    if (action_type == "in") {
      tagList(
        div(class = "form-group",
          tags$label("Vahid qiyməti (AZN, isteğe bağlı)"),
          numericInput("mat_price", NULL, value = 0, min = 0, step = 0.01, width = "100%")
        )
      )
    } else NULL,
    
    div(class = "form-group",
      tags$label(labels$reason_label),
      textAreaInput("mat_reason", NULL,
                    placeholder = labels$reason_ph,
                    rows = 3, width = "100%")
    ),
    
    # Saxlanan action_type (hidden)
    tags$script(sprintf("Shiny.setInputValue('mat_action_type', '%s');", action_type)),
    
    # FAYL YÜKLƏMƏ
    div(class = "file-upload-section",
      h4("📸 Qaimə/Foto əlavə et"),
      fileInput("mat_files", NULL,
                multiple = TRUE,
                accept = c("image/jpeg", "image/png", "application/pdf"),
                buttonLabel = "Seç...",
                placeholder = "Fayl seçilməyib"),
      uiOutput("mat_files_preview")
    ),
    
    actionButton("mat_save", labels$btn,
                 class = "btn-mobile btn-primary-mobile",
                 icon = icon("save")),
    actionButton("mat_cancel", "Ləğv et",
                 class = "btn-mobile btn-secondary-mobile")
  )
}

# ═══ LAYİHƏLƏR SİYAHISI ═══
page_projects <- function(projects) {
  if (nrow(projects) == 0) {
    return(div(class = "empty-state",
      tags$span(class = "emoji", "🏗️"),
      h4("Layihə tapılmadı"),
      tags$p("Region-da aktiv layihə yoxdur")
    ))
  }
  
  tagList(
    tags$h3(class = "section-title", 
            paste0("Region layihələri (", nrow(projects), ")")),
    
    lapply(seq_len(nrow(projects)), function(i) {
      p <- projects[i, ]
      status_class <- switch(p$status,
        "completed" = "status-completed",
        "in_progress" = "status-active",
        "active" = "status-active",
        "planned" = "status-planned",
        "approved" = "status-active",
        "status-planned"
      )
      status_label <- switch(p$status,
        "completed" = "Tamamlandı",
        "in_progress" = "Davam edir",
        "active" = "Aktiv",
        "planned" = "Planlaşdırılıb",
        "approved" = "Təsdiq olundu",
        p$status
      )
      
      progress <- p$progress_percent %||% 0
      if (is.na(progress)) progress <- 0
      
      div(class = "list-item",
        style = sprintf("animation-delay: %dms;", i * 50),
        div(class = "list-item-header",
          tags$p(class = "list-item-title", 
                 paste0(p$project_code, " — ", substr(p$name, 1, 40))),
          tags$span(class = paste("list-item-badge", status_class), status_label)
        ),
        div(class = "list-item-meta",
            tags$span("📅 Başlama: ", as.character(p$start_date %||% "N/A"))),
        div(class = "list-item-meta",
            tags$span("💰 Büdcə: ", 
                      format(round(p$planned_budget %||% 0, 0), big.mark = ","), " AZN")),
        div(class = "list-item-progress",
            div(class = "list-item-progress-fill",
                style = sprintf("width: %d%%;", as.integer(progress))))
      )
    })
  )
}
# ═══════════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════════

ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$meta(name = "viewport", 
              content = "width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no"),
    tags$meta(name = "apple-mobile-web-app-capable", content = "yes"),
    tags$meta(name = "apple-mobile-web-app-status-bar-style", content = "default"),
    tags$meta(name = "theme-color", content = "#059669"),
    tags$title(cfg$app$title_regional %||% "ARTI Regional"),
    tags$style(HTML(mobile_css))
  ),
  
  uiOutput("main_ui")
)

# ═══════════════════════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════════════════════

server <- function(input, output, session) {
  
  # ═══ STATE ═══
  state <- reactiveValues(
    logged_in = FALSE,
    user = NULL,
    page = "home",
    material_action = NULL,  # in, out, waste, return
    login_error = NULL
  )
  
  # ═══ LOGIN ═══
  observeEvent(input$do_login, {
    req(input$login_user, input$login_pass)
    
    user_data <- safe_query(
      "SELECT id, username, full_name, role, region_id, password_hash, is_active 
       FROM audit.users WHERE username = $1",
      params = list(input$login_user)
    )
    
    if (nrow(user_data) == 0) {
      state$login_error <- "İstifadəçi adı və ya şifrə səhvdir"
      # Login attempt logla
      tryCatch({
        dbExecute(pool, "
          INSERT INTO audit.login_history (username, status, failure_reason, ip_address)
          VALUES ($1, 'failed', 'user_not_found', $2::inet)
        ", params = list(input$login_user, get_connection_info(session)$ip))
      }, error = function(e) message("Login log xəta: ", e$message))
      return()
    }
    
    user <- user_data[1, ]
    
    if (!isTRUE(user$is_active)) {
      state$login_error <- "Hesab deaktiv edilib"
      return()
    }
    
    # Yalnız regional_worker bu app-a daxil ola bilər
    if (user$role != "regional_worker") {
      state$login_error <- paste0("Bu app yalnız regional işçilər üçündür (sizin rol: ", user$role, ")")
      return()
    }
    
    # Şifrə yoxla
    pwd_ok <- tryCatch({
      bcrypt::checkpw(input$login_pass, user$password_hash)
    }, error = function(e) FALSE)
    
    if (!isTRUE(pwd_ok)) {
      state$login_error <- "İstifadəçi adı və ya şifrə səhvdir"
      tryCatch({
        dbExecute(pool, "
          INSERT INTO audit.login_history (username, status, failure_reason, ip_address)
          VALUES ($1, 'failed', 'wrong_password', $2::inet)
        ", params = list(input$login_user, get_connection_info(session)$ip))
      }, error = function(e) message("Login log xəta: ", e$message))
      return()
    }
    
    # Uğurlu login
    state$logged_in <- TRUE
    state$user <- user
    state$login_error <- NULL
    state$page <- "home"
    
    # Last login yenilə
    safe_execute("UPDATE audit.users SET last_login = NOW() WHERE id = $1",
                 params = list(as.integer(user$id)))
    
    # Login tarixçəsi
    conn <- get_connection_info(session)
    tryCatch({
      dbExecute(pool, "
        INSERT INTO audit.login_history (user_id, username, status, ip_address, user_agent)
        VALUES ($1, $2, 'success', $3::inet, $4)
      ", params = list(as.integer(user$id), user$username, conn$ip, conn$user_agent))
    }, error = function(e) message("Login log xəta: ", e$message))
    
    # Audit log
    log_action(user$id, "LOGIN", "session", 
               paste0("Mobile login from IP ", conn$ip), 
               "success", conn$ip)
    
    showNotification(paste0("Xoş gəldiniz, ", user$full_name), 
                     type = "message", duration = 3)
  })
  
  # ═══ LOGOUT ═══
  observeEvent(input$do_logout, {
    if (!is.null(state$user)) {
      log_action(state$user$id, "LOGOUT", "session", "Mobile logout",
                 "success", get_connection_info(session)$ip)
    }
    state$logged_in <- FALSE
    state$user <- NULL
    state$page <- "home"
    state$login_error <- NULL
  })
  
  # ═══ LOGIN MESSAGE ═══
  output$login_message <- renderUI({
    if (!is.null(state$login_error)) {
      div(class = "login-error", state$login_error)
    } else NULL
  })
  
  # ═══ PAGE NAVIGATION ═══
  # Bottom nav
  observeEvent(input$nav_home, { state$page <- "home" })
  observeEvent(input$nav_inspect, { state$page <- "inspect" })
  observeEvent(input$nav_complaint, { state$page <- "complaint" })
  observeEvent(input$nav_report, { state$page <- "report" })
  observeEvent(input$nav_material, { state$page <- "material" })
  
  # Quick action cards (home-dan)
  observeEvent(input$quick_inspect, { state$page <- "inspect" })
  observeEvent(input$quick_complaint, { state$page <- "complaint" })
  observeEvent(input$quick_report, { state$page <- "report" })
  observeEvent(input$quick_material, { state$page <- "material" })
  observeEvent(input$quick_projects, { state$page <- "projects" })
  
  # Material sub-pages
  observeEvent(input$mat_in, { 
    state$material_action <- "in"
    state$page <- "material_action"
  })
  observeEvent(input$mat_out, { 
    state$material_action <- "out"
    state$page <- "material_action"
  })
  observeEvent(input$mat_waste, { 
    state$material_action <- "waste"
    state$page <- "material_action"
  })
  observeEvent(input$mat_return, { 
    state$material_action <- "return"
    state$page <- "material_action"
  })
  
  # Cancel buttons
  observeEvent(input$ins_cancel, { state$page <- "home" })
  observeEvent(input$cmp_cancel, { state$page <- "home" })
  observeEvent(input$rep_cancel, { state$page <- "home" })
  observeEvent(input$mat_cancel, { state$page <- "material" })
  
  # ═══ REACTIVE DATA ═══
  weekly_stats <- reactive({
    req(state$logged_in, state$user)
    uid <- state$user$id
    
    ins <- safe_query(
      "SELECT COUNT(*) AS n FROM construction.inspections 
       WHERE report_text LIKE $1 
         AND inspection_date >= CURRENT_DATE - INTERVAL '7 days'",
      params = list(paste0("%[Mobile by ", state$user$username, "]%"))
    )
    
    cmp <- safe_query(
      "SELECT COUNT(*) AS n FROM construction.citizen_complaints 
       WHERE status IN ('new', 'investigating')
         AND (text LIKE $1 OR school_id IN (SELECT id FROM infra.schools WHERE region_id = $2))",
      params = list(paste0("%[Mobile by ", state$user$username, "]%"),
                    as.integer(state$user$region_id %||% 0))
    )
    
    list(
      weekly_inspections = ins$n[1] %||% 0,
      open_complaints = cmp$n[1] %||% 0
    )
  })
  
  region_projects <- reactive({
    req(state$logged_in, state$user)
    rid <- state$user$region_id
    if (is.null(rid) || is.na(rid)) return(data.frame())
    
    safe_query(
      "SELECT id, project_code, name, status, start_date, end_date, 
              planned_budget, progress_percent 
       FROM construction.projects 
       WHERE region_id = $1 
         AND status IN ('in_progress', 'active', 'approved', 'planned', 'completed')
       ORDER BY 
         CASE status 
           WHEN 'in_progress' THEN 1
           WHEN 'active' THEN 2
           WHEN 'approved' THEN 3
           WHEN 'planned' THEN 4
           WHEN 'completed' THEN 5
           ELSE 6 END,
         end_date NULLS LAST
       LIMIT 50",
      params = list(as.integer(rid))
    )
  })
  
  region_schools <- reactive({
    req(state$logged_in, state$user)
    rid <- state$user$region_id
    if (is.null(rid) || is.na(rid)) return(data.frame())
    
    safe_query(
      "SELECT id, name FROM infra.schools WHERE region_id = $1 ORDER BY name LIMIT 100",
      params = list(as.integer(rid))
    )
  })
  
  region_warehouses <- reactive({
    req(state$logged_in, state$user)
    rid <- state$user$region_id
    if (is.null(rid) || is.na(rid)) return(data.frame())
    
    # Region anbarı + mərkəzi anbar da
    safe_query(
      "SELECT id, code, name, region_id, is_central 
       FROM inventory.warehouses 
       WHERE is_active = TRUE
         AND (region_id = $1 OR is_central = TRUE)
       ORDER BY is_central DESC, name",
      params = list(as.integer(rid))
    )
  })
  
  all_materials <- reactive({
    safe_query(
      "SELECT m.id, m.code, m.name_az, m.unit, m.category_id,
              c.name_az AS category_name, c.icon AS category_icon
       FROM inventory.materials m
       LEFT JOIN inventory.material_categories c ON m.category_id = c.id
       WHERE m.is_active = TRUE
       ORDER BY c.name_az, m.name_az"
    )
  })
  
  # Cari anbar qalıqları (region üzrə)
  region_stock <- reactive({
    req(state$logged_in, state$user)
    rid <- state$user$region_id
    if (is.null(rid) || is.na(rid)) return(data.frame())
    
    safe_query(
      "SELECT 
         sl.warehouse_id, sl.material_id, sl.quantity,
         w.name AS warehouse_name, w.is_central,
         m.name_az AS material_name, m.unit, m.min_stock_level,
         c.name_az AS category
       FROM inventory.stock_levels sl
       JOIN inventory.warehouses w ON sl.warehouse_id = w.id
       JOIN inventory.materials m ON sl.material_id = m.id
       LEFT JOIN inventory.material_categories c ON m.category_id = c.id
       WHERE (w.region_id = $1 OR w.is_central = TRUE)
         AND w.is_active = TRUE
         AND sl.quantity > 0
       ORDER BY c.name_az, sl.quantity DESC
       LIMIT 100",
      params = list(as.integer(rid))
    )
  })
  
  # ═══ MAIN UI ROUTER ═══
  output$main_ui <- renderUI({
    if (!isTRUE(state$logged_in)) {
      return(page_login())
    }
    
    user <- state$user
    region_name <- safe_query(
      "SELECT name_az FROM geo.regions WHERE id = $1",
      params = list(as.integer(user$region_id %||% 0))
    )$name_az[1] %||% "N/A"
    
    # Current page
    page_content <- switch(state$page,
      "home" = page_home(user, weekly_stats()),
      "inspect" = page_inspect(region_projects()),
      "complaint" = page_complaint(region_schools()),
      "report" = page_report(region_projects()),
      "material" = page_material(),
      "material_action" = page_material_action(
        state$material_action, region_warehouses(), all_materials()
      ),
      "projects" = page_projects(region_projects()),
      page_home(user, weekly_stats())
    )
    
    # Connection badge
    conn_label <- if (db_info$source == "localhost") "● Yerli" else "● Tailscale"
    conn_color <- if (db_info$source == "localhost") "#10b981" else "#0369a1"
    
    div(class = "app-container",
      # HEADER
      div(class = "mobile-header",
        div(class = "header-flex",
          div(style = "flex:1;",
            h1(user$full_name %||% "İşçi"),
            tags$p(class = "subtitle", 
                   paste0("🌍 ", region_name, " · ", user$username))
          ),
          tags$span(class = "connection-badge", 
                    style = paste0("background:", conn_color, "33;"),
                    conn_label),
          actionButton("do_logout", "Çıxış", class = "logout-btn")
        )
      ),
      
      # CONTENT
      div(class = "mobile-content", page_content),
      
      # BOTTOM NAVIGATION
      div(class = "bottom-nav",
        div(class = paste("bottom-nav-item", if (state$page == "home") "active" else ""),
            onclick = "Shiny.setInputValue('nav_home', Math.random());",
            tags$span(class = "nav-icon", "🏠"),
            tags$span(class = "nav-label", "Ana")
        ),
        div(class = paste("bottom-nav-item", if (state$page == "inspect") "active" else ""),
            onclick = "Shiny.setInputValue('nav_inspect', Math.random());",
            tags$span(class = "nav-icon", "🔍"),
            tags$span(class = "nav-label", "Yoxlama")
        ),
        div(class = paste("bottom-nav-item", if (state$page == "complaint") "active" else ""),
            onclick = "Shiny.setInputValue('nav_complaint', Math.random());",
            tags$span(class = "nav-icon", "📧"),
            tags$span(class = "nav-label", "Şikayət")
        ),
        div(class = paste("bottom-nav-item", if (state$page == "report") "active" else ""),
            onclick = "Shiny.setInputValue('nav_report', Math.random());",
            tags$span(class = "nav-icon", "📋"),
            tags$span(class = "nav-label", "Hesabat")
        ),
        div(class = paste("bottom-nav-item", if (state$page %in% c("material", "material_action")) "active" else ""),
            onclick = "Shiny.setInputValue('nav_material', Math.random());",
            tags$span(class = "nav-icon", "📦"),
            tags$span(class = "nav-label", "Material")
        )
      )
    )
  })
  # ═══════════════════════════════════════════════════════════════
  # FORM HANDLERS
  # ═══════════════════════════════════════════════════════════════
  
  # ═══ FAYL PREVIEW UI ═══
  render_file_preview <- function(files) {
    if (is.null(files) || nrow(files) == 0) return(NULL)
    
    items <- lapply(seq_len(nrow(files)), function(i) {
      f <- files[i, ]
      ext <- tolower(tools::file_ext(f$name))
      icon <- if (ext == "pdf") "📄" else if (ext %in% c("jpg","jpeg","png")) "🖼️" else "📎"
      size_kb <- round(f$size / 1024, 1)
      size_text <- if (size_kb > 1024) {
        paste0(round(size_kb/1024, 2), " MB")
      } else {
        paste0(size_kb, " KB")
      }
      
      div(class = "attached-item",
        span(class = "attached-icon", icon),
        div(class = "attached-info",
          div(class = "attached-name", f$name),
          div(class = "attached-size", size_text, " · ", ext)
        )
      )
    })
    
    div(class = "attached-list", do.call(tagList, items))
  }
  
  output$ins_files_preview <- renderUI({ render_file_preview(input$ins_files) })
  output$cmp_files_preview <- renderUI({ render_file_preview(input$cmp_files) })
  output$rep_files_preview <- renderUI({ render_file_preview(input$rep_files) })
  output$mat_files_preview <- renderUI({ render_file_preview(input$mat_files) })
  
  # ═══ MATERIAL CURRENT STOCK DISPLAY ═══
  output$mat_current_stock <- renderUI({
    req(input$mat_warehouse, input$mat_material)
    if (input$mat_warehouse == "0" || input$mat_material == "0") return(NULL)
    
    stock <- safe_query(
      "SELECT sl.quantity, m.unit, m.name_az, m.min_stock_level
       FROM inventory.stock_levels sl
       JOIN inventory.materials m ON sl.material_id = m.id
       WHERE sl.warehouse_id = $1 AND sl.material_id = $2",
      params = list(as.integer(input$mat_warehouse),
                    as.integer(input$mat_material))
    )
    
    if (nrow(stock) == 0) {
      return(div(style = "padding: 12px; background: #fef3c7; border-radius: 10px; margin-bottom: 12px; color: #92400e; font-weight: 600; font-size: 13px;",
        "ℹ️ Bu anbarda bu material hələ yoxdur"))
    }
    
    qty <- stock$quantity[1]
    min_lvl <- stock$min_stock_level[1] %||% 0
    unit <- stock$unit[1]
    
    status_bg <- "#d1fae5"
    status_color <- "#065f46"
    status_text <- paste0("✅ Cari qalıq: ", format(qty, big.mark = ","), " ", unit)
    
    if (qty < min_lvl) {
      status_bg <- "#fee2e2"
      status_color <- "#991b1b"
      status_text <- paste0("⚠️ Az qalıb: ", format(qty, big.mark = ","), " ", unit, " (min: ", min_lvl, ")")
    }
    
    div(style = sprintf("padding: 12px; background: %s; border-radius: 10px; margin-bottom: 12px; color: %s; font-weight: 600; font-size: 13px;",
                        status_bg, status_color),
        status_text)
  })
  
  # ═══ INSPECTION SAVE ═══
  observeEvent(input$ins_save, {
    req(state$logged_in, state$user)
    
    if (is.null(input$ins_report) || nchar(trimws(input$ins_report)) < 10) {
      showNotification("⚠️ Yoxlama hesabatı ən az 10 simvol olmalıdır", 
                       type = "warning", duration = 4)
      return()
    }
    
    proj_id <- na_int(input$ins_project)
    user_id <- as.integer(state$user$id)
    conn <- get_connection_info(session)
    
    # Inspector tap (hr.employees-dən)
    inspector_id <- safe_query(
      "SELECT id FROM hr.employees WHERE region_id = $1 AND is_active = TRUE LIMIT 1",
      params = list(as.integer(state$user$region_id %||% 0))
    )
    inspector_v <- if (nrow(inspector_id) > 0) as.integer(inspector_id$id[1]) else NA_integer_
    
    # Mobile prefix ilə text
    full_report <- paste0("[Mobile by ", state$user$username, "] ", trimws(input$ins_report))
    
    ins_id <- tryCatch({
      result <- dbGetQuery(pool, "
        INSERT INTO construction.inspections (
          project_id, inspector_id, inspection_date, inspection_type,
          quality_score, issues_found, issues_resolved, 
          report_text, followup_required, followup_date
        ) VALUES (
          $1, $2, NOW(), $3, $4, $5, $6, $7, $8, $9
        ) RETURNING id
      ", params = list(
        proj_id,
        inspector_v,
        na_safe(input$ins_type),
        as.numeric(input$ins_quality),
        as.integer(input$ins_issues_found %||% 0),
        as.integer(input$ins_issues_resolved %||% 0),
        full_report,
        isTRUE(input$ins_followup),
        if (isTRUE(input$ins_followup)) Sys.Date() + 14 else as.Date(NA)
      ))
      result$id[1]
    }, error = function(e) {
      message("INSERT xəta: ", e$message)
      NULL
    })
    
    if (is.null(ins_id)) {
      showNotification("❌ Yoxlama saxlanıla bilmədi", type = "error", duration = 5)
      log_action(user_id, "INSERT", "inspections", 
                 "Mobile inspection failed", "error", conn$ip)
      return()
    }
    
    log_action(user_id, "INSERT", "inspections",
               paste0("Mobile inspection #", ins_id), "success", conn$ip)
    
    # Faylları yüklə
    uploaded_files <- 0
    if (!is.null(input$ins_files) && nrow(input$ins_files) > 0) {
      for (i in seq_len(nrow(input$ins_files))) {
        f <- input$ins_files[i, ]
        result <- save_attachment(f, "inspections", ins_id, 
                                  "inspection_photo", user_id, conn$ip)
        if (isTRUE(result$success)) {
          uploaded_files <- uploaded_files + 1
          log_action(user_id, "INSERT", "attachments",
                     paste("Inspection file:", result$filename), 
                     "success", conn$ip)
        }
      }
    }
    
    msg <- paste0("✅ Yoxlama #", ins_id, " saxlanıldı!")
    if (uploaded_files > 0) msg <- paste0(msg, " 📎 ", uploaded_files, " fayl yükləndi.")
    showNotification(msg, type = "message", duration = 5)
    
    # Formu sıfırla
    updateSliderInput(session, "ins_quality", value = 7)
    updateNumericInput(session, "ins_issues_found", value = 0)
    updateNumericInput(session, "ins_issues_resolved", value = 0)
    updateTextAreaInput(session, "ins_report", value = "")
    updateCheckboxInput(session, "ins_followup", value = FALSE)
    try(shinyjs::reset("ins_files"), silent = TRUE)
    
    state$page <- "home"
  })
  
  # ═══ COMPLAINT SAVE ═══
  observeEvent(input$cmp_save, {
    req(state$logged_in, state$user)
    
    if (is.null(input$cmp_text) || nchar(trimws(input$cmp_text)) < 10) {
      showNotification("⚠️ Şikayət mətni ən az 10 simvol olmalıdır", 
                       type = "warning", duration = 4)
      return()
    }
    
    user_id <- as.integer(state$user$id)
    conn <- get_connection_info(session)
    school_id_v <- na_int(input$cmp_school)
    
    full_text <- paste0("[Mobile by ", state$user$username, "] ", 
                        "Vətəndaş: ", na_safe(input$cmp_citizen), " | ",
                        "Əlaqə: ", na_safe(input$cmp_contact), " | ",
                        trimws(input$cmp_text))
    
    cmp_id <- tryCatch({
      result <- dbGetQuery(pool, "
        INSERT INTO construction.citizen_complaints (
          complaint_date, region_id, school_id, channel,
          category, urgency, text, status
        ) VALUES (
          NOW(), $1, $2, 'mobile', $3, $4, $5, 'new'
        ) RETURNING id
      ", params = list(
        as.integer(state$user$region_id %||% 0),
        school_id_v,
        na_safe(input$cmp_category),
        na_safe(input$cmp_urgency),
        full_text
      ))
      result$id[1]
    }, error = function(e) {
      message("Complaint xəta: ", e$message)
      NULL
    })
    
    if (is.null(cmp_id)) {
      showNotification("❌ Şikayət saxlanıla bilmədi", type = "error", duration = 5)
      log_action(user_id, "INSERT", "complaints", 
                 "Mobile complaint failed", "error", conn$ip)
      return()
    }
    
    log_action(user_id, "INSERT", "complaints",
               paste0("Mobile complaint #", cmp_id), "success", conn$ip)
    
    # Faylları yüklə
    uploaded_files <- 0
    if (!is.null(input$cmp_files) && nrow(input$cmp_files) > 0) {
      for (i in seq_len(nrow(input$cmp_files))) {
        f <- input$cmp_files[i, ]
        result <- save_attachment(f, "citizen_complaints", cmp_id,
                                  "complaint_photo", user_id, conn$ip)
        if (isTRUE(result$success)) {
          uploaded_files <- uploaded_files + 1
          log_action(user_id, "INSERT", "attachments",
                     paste("Complaint file:", result$filename),
                     "success", conn$ip)
        }
      }
    }
    
    msg <- paste0("✅ Şikayət #", cmp_id, " qeydə alındı!")
    if (uploaded_files > 0) msg <- paste0(msg, " 📎 ", uploaded_files, " fayl yükləndi.")
    showNotification(msg, type = "message", duration = 5)
    
    updateTextInput(session, "cmp_citizen", value = "")
    updateTextInput(session, "cmp_contact", value = "")
    updateTextAreaInput(session, "cmp_text", value = "")
    updateSelectInput(session, "cmp_school", selected = "0")
    try(shinyjs::reset("cmp_files"), silent = TRUE)
    
    state$page <- "home"
  })
  
  # ═══ REPORT SAVE ═══
  observeEvent(input$rep_save, {
    req(state$logged_in, state$user)
    
    if (is.null(input$rep_done) || nchar(trimws(input$rep_done)) < 5) {
      showNotification("⚠️ Görülən iş sahəsi boş ola bilməz", 
                       type = "warning", duration = 4)
      return()
    }
    
    user_id <- as.integer(state$user$id)
    conn <- get_connection_info(session)
    proj_id <- na_int(input$rep_project)
    
    rep_id <- tryCatch({
      result <- dbGetQuery(pool, "
        INSERT INTO construction.daily_reports (
          worker_id, region_id, project_id, report_date,
          weather, temperature, workers_count, hours_worked,
          work_done, issues, progress_after, created_at
        ) VALUES (
          $1, $2, $3, CURRENT_DATE, $4, $5, $6, $7, $8, $9, $10, NOW()
        ) RETURNING id
      ", params = list(
        user_id,
        as.integer(state$user$region_id %||% 0),
        proj_id,
        na_safe(input$rep_weather),
        as.numeric(input$rep_temp %||% 20),
        as.integer(input$rep_workers %||% 0),
        as.numeric(input$rep_hours %||% 8),
        trimws(input$rep_done),
        na_safe(input$rep_issues),
        as.integer(input$rep_progress %||% 0)
      ))
      result$id[1]
    }, error = function(e) {
      message("Report xəta: ", e$message)
      NULL
    })
    
    if (is.null(rep_id)) {
      showNotification("❌ Hesabat saxlanıla bilmədi", type = "error", duration = 5)
      log_action(user_id, "INSERT", "daily_report",
                 "Mobile report failed", "error", conn$ip)
      return()
    }
    
    log_action(user_id, "INSERT", "daily_report",
               paste0("Mobile daily report #", rep_id), "success", conn$ip)
    
    # Faylları yüklə
    uploaded_files <- 0
    if (!is.null(input$rep_files) && nrow(input$rep_files) > 0) {
      for (i in seq_len(nrow(input$rep_files))) {
        f <- input$rep_files[i, ]
        file_result <- save_attachment(f, "daily_reports", rep_id,
                                       "progress_photo", user_id, conn$ip)
        if (isTRUE(file_result$success)) {
          uploaded_files <- uploaded_files + 1
          log_action(user_id, "INSERT", "attachments",
                     paste("Report file:", file_result$filename),
                     "success", conn$ip)
        }
      }
    }
    
    msg <- paste0("✅ Hesabat #", rep_id, " təqdim edildi!")
    if (uploaded_files > 0) msg <- paste0(msg, " 📎 ", uploaded_files, " fayl yükləndi.")
    showNotification(msg, type = "message", duration = 5)
    
    updateTextAreaInput(session, "rep_done", value = "")
    updateTextAreaInput(session, "rep_issues", value = "")
    updateSliderInput(session, "rep_progress", value = 0)
    updateNumericInput(session, "rep_workers", value = 0)
    try(shinyjs::reset("rep_files"), silent = TRUE)
    
    state$page <- "home"
  })
  
  # ═══ MATERIAL SAVE ═══
  observeEvent(input$mat_save, {
    req(state$logged_in, state$user, state$material_action)
    
    action_type <- state$material_action
    
    # Validation
    if (input$mat_warehouse == "0") {
      showNotification("⚠️ Anbar seçin", type = "warning", duration = 4)
      return()
    }
    if (input$mat_material == "0") {
      showNotification("⚠️ Material seçin", type = "warning", duration = 4)
      return()
    }
    if (is.null(input$mat_quantity) || input$mat_quantity <= 0) {
      showNotification("⚠️ Miqdar 0-dan böyük olmalıdır", type = "warning", duration = 4)
      return()
    }
    if (is.null(input$mat_reason) || nchar(trimws(input$mat_reason)) < 3) {
      showNotification("⚠️ Səbəb/qeyd sahəsi boş ola bilməz", type = "warning", duration = 4)
      return()
    }
    
    user_id <- as.integer(state$user$id)
    conn <- get_connection_info(session)
    wh_id <- as.integer(input$mat_warehouse)
    mat_id <- as.integer(input$mat_material)
    qty <- as.numeric(input$mat_quantity)
    
    # Çıxış/silmə/qaytarma üçün stock yoxla
    if (action_type %in% c("out", "waste")) {
      current_stock <- safe_query(
        "SELECT quantity FROM inventory.stock_levels 
         WHERE warehouse_id = $1 AND material_id = $2",
        params = list(wh_id, mat_id)
      )
      
      cur_qty <- if (nrow(current_stock) > 0) current_stock$quantity[1] else 0
      
      if (cur_qty < qty) {
        showNotification(
          sprintf("⚠️ Kifayət qədər material yoxdur. Cari qalıq: %s", format(cur_qty, big.mark=",")),
          type = "warning", duration = 5
        )
        return()
      }
    }
    
    # Mobile tag ilə notes
    full_notes <- paste0("[Mobile by ", state$user$username, "] ", 
                         trimws(input$mat_reason))
    
    # Price
    price_v <- if (action_type == "in") as.numeric(input$mat_price %||% 0) else NA_real_
    total_v <- if (action_type == "in" && !is.na(price_v) && price_v > 0) price_v * qty else NA_real_
    
    # Insert transaction
    trans_id <- tryCatch({
      result <- dbGetQuery(pool, "
        INSERT INTO inventory.material_transactions (
          transaction_type, warehouse_id, material_id, quantity,
          unit_price, total_amount, transaction_date, notes,
          reference_number
        ) VALUES (
          $1, $2, $3, $4, $5, $6, NOW(), $7, $8
        ) RETURNING id
      ", params = list(
        action_type,
        wh_id,
        mat_id,
        qty,
        price_v,
        total_v,
        full_notes,
        paste0("MOB-", format(Sys.time(), "%Y%m%d%H%M%S"))
      ))
      result$id[1]
    }, error = function(e) {
      message("Material transaction xəta: ", e$message)
      NULL
    })
    
    if (is.null(trans_id)) {
      showNotification("❌ Əməliyyat saxlanıla bilmədi", type = "error", duration = 5)
      log_action(user_id, "INSERT", "material_transaction",
                 "Mobile material action failed", "error", conn$ip)
      return()
    }
    
    # Stock yenilə (upsert)
    stock_delta <- switch(action_type,
      "in" = qty,
      "out" = -qty,
      "waste" = -qty,
      "return" = qty,
      0
    )
    
    safe_execute(
      "INSERT INTO inventory.stock_levels (warehouse_id, material_id, quantity, last_updated)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (warehouse_id, material_id) 
       DO UPDATE SET quantity = inventory.stock_levels.quantity + $3, last_updated = NOW()",
      params = list(wh_id, mat_id, stock_delta)
    )
    
    # Audit log
    action_label <- switch(action_type,
      "in" = "daxil etmə",
      "out" = "çıxış",
      "waste" = "zədə silmə",
      "return" = "qaytarma",
      action_type
    )
    
    log_action(user_id, "INSERT", "material_transaction",
               paste0("Mobile material ", action_label, " #", trans_id, 
                      " (qty: ", qty, ")"),
               "success", conn$ip)
    
    # Faylları yüklə
    uploaded_files <- 0
    if (!is.null(input$mat_files) && nrow(input$mat_files) > 0) {
      for (i in seq_len(nrow(input$mat_files))) {
        f <- input$mat_files[i, ]
        file_result <- save_attachment(f, "material_transactions", trans_id,
                                       "invoice", user_id, conn$ip)
        if (isTRUE(file_result$success)) {
          uploaded_files <- uploaded_files + 1
          log_action(user_id, "INSERT", "attachments",
                     paste("Material file:", file_result$filename),
                     "success", conn$ip)
        }
      }
    }
    
    msg <- paste0("✅ Material #", trans_id, " ", action_label, " uğurla qeydə alındı!")
    if (uploaded_files > 0) msg <- paste0(msg, " 📎 ", uploaded_files, " fayl yükləndi.")
    showNotification(msg, type = "message", duration = 5)
    
    # Form sıfırla
    updateSelectInput(session, "mat_warehouse", selected = "0")
    updateSelectInput(session, "mat_material", selected = "0")
    updateNumericInput(session, "mat_quantity", value = 0)
    updateTextAreaInput(session, "mat_reason", value = "")
    try(shinyjs::reset("mat_files"), silent = TRUE)
    
    state$page <- "material"
  })
  
  # ═══ STOCK VIEW ═══
  output$material_stock_view <- renderUI({
    stock <- region_stock()
    
    if (nrow(stock) == 0) {
      return(div(class = "empty-state",
        tags$span(class = "emoji", "📦"),
        h4("Qalıq məlumatı yoxdur"),
        tags$p("Region anbarlarında aktiv material yoxdur")
      ))
    }
    
    # Top 20 göstər
    stock <- head(stock, 20)
    
    items <- lapply(seq_len(nrow(stock)), function(i) {
      s <- stock[i, ]
      min_lvl <- s$min_stock_level %||% 0
      
      stock_class <- ""
      qty_class <- ""
      
      if (!is.na(min_lvl) && min_lvl > 0) {
        if (s$quantity < min_lvl * 0.5) {
          stock_class <- "critical"
          qty_class <- "critical"
        } else if (s$quantity < min_lvl) {
          stock_class <- "low"
          qty_class <- "low"
        }
      }
      
      div(class = paste("stock-item", stock_class),
        div(style = "flex: 1; min-width: 0;",
          tags$p(class = "stock-name", 
                 substr(s$material_name, 1, 35)),
          tags$p(class = "stock-meta",
                 paste0("🏢 ", substr(s$warehouse_name, 1, 25)))
        ),
        tags$span(class = paste("stock-qty", qty_class),
                  paste0(format(round(s$quantity, 1), big.mark = ","), " ", s$unit))
      )
    })
    
    do.call(tagList, items)
  })
  
  cat("[INFO] Regional app v2.0 başladı — session:", session$token, "\n")
  session$onSessionEnded(function() {
    cat("[INFO] Session bitdi:", session$token, "\n")
  })
}

# ═══════════════════════════════════════════════════════════════
# RUN
# ═══════════════════════════════════════════════════════════════
shinyApp(
  ui = ui, 
  server = server,
  options = list(
    host = "0.0.0.0",   # Bütün şəbəkə interfeyslərindən qoşulma
    port = 3839,         # Regional port
    launch.browser = TRUE
  )
)
