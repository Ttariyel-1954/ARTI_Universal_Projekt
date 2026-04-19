# ═══════════════════════════════════════════════════════════════
# ARTI TTİ — REGIONAL WORKER APP
# Mobile-first interfeys 9 rayon işçisi üçün
# Author: Talıbov Tariyel İsmayıl oğlu, ARTI
# Version: 1.0.0
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({
  library(shiny)
  library(bs4Dash)
  library(DBI)
  library(RPostgres)
  library(pool)
  library(dplyr)
  library(DT)
  library(shinyjs)
  library(waiter)
})

# ═══ KONFIQURASIYA ═══
APP_TITLE <- "ARTI TTİ — Regional"

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

# ═══ DATABASE ═══
pool <- dbPool(RPostgres::Postgres(),
               host="localhost", port=5432,
               dbname="arti_construction",
               user="royatalibova", password="",
               minSize=2, maxSize=10)

onStop(function() {
  if (!is.null(pool) && pool$valid) try(poolClose(pool), silent = TRUE)
})

# ═══ HELPERS ═══
`%||%` <- function(a, b) if (is.null(a) || is.na(a) || a == "") b else a

safe_query <- function(sql, params = NULL) {
  tryCatch({
    res <- if (is.null(params)) dbGetQuery(pool, sql)
           else dbGetQuery(pool, sql, params = params)
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
    if (is.null(params)) dbExecute(pool, sql)
    else dbExecute(pool, sql, params = params)
    TRUE
  }, error = function(e) {
    message("Execute xəta: ", e$message)
    FALSE
  })
}

get_connection_info <- function(session) {
  list(
    ip = session$request$HTTP_X_FORWARDED_FOR %||% 
         session$request$REMOTE_ADDR %||% "127.0.0.1",
    user_agent = session$request$HTTP_USER_AGENT %||% "Unknown",
    tailscale = session$request$HTTP_HOST %||% "local"
  )
}

log_action <- function(user_id, action, resource = NULL, 
                       query_text = NULL, status = "success",
                       ip = NULL, tailscale = NULL, user_agent = NULL) {
  if (is.null(user_id)) return(invisible(NULL))
  
  # NULL → NA çevir (RPostgres üçün)
  na_safe <- function(x) if (is.null(x) || length(x) == 0) NA_character_ else as.character(x)
  
  tryCatch({
    dbExecute(pool, "
      INSERT INTO audit.query_log (
        user_id, username, user_role, action, resource, 
        query_text, source, status,
        ip_address, tailscale_name, user_agent
      )
      SELECT $1, username, role, $2, $3, $4, 'mobile', $5, $6::inet, $7, $8
      FROM audit.users WHERE id = $1
    ", params = list(
      as.integer(user_id), 
      na_safe(action), 
      na_safe(resource), 
      substr(na_safe(query_text), 1, 500), 
      na_safe(status), 
      na_safe(ip), 
      na_safe(tailscale), 
      na_safe(user_agent)
    ))
  }, error = function(e) message("Log xəta: ", e$message))
}

authenticate <- function(username, password) {
  tryCatch({
    res <- dbGetQuery(pool, 
      "SELECT * FROM audit.verify_password($1, $2)",
      params = list(username, password))
    if (nrow(res) == 0) return(list(is_valid = FALSE, error_msg = "Xəta"))
    res[1, ]
  }, error = function(e) {
    list(is_valid = FALSE, error_msg = paste("Xəta:", e$message))
  })
}

# ═══ MOBİL CSS ═══
mobile_css <- "
* { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
html, body { 
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif; 
  font-size: 16px;
  -webkit-text-size-adjust: 100%;
}

/* === LOGIN === */
.login-bg {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background: linear-gradient(135deg, #059669 0%, #10b981 100%);
  display: flex; align-items: center; justify-content: center;
  padding: 20px;
}
.login-card { 
  background: white; padding: 35px 25px; border-radius: 24px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
  width: 100%; max-width: 380px;
}
.login-icon { font-size: 70px; text-align: center; margin-bottom: 10px; }
.login-title { 
  text-align: center; color: #065f46; font-weight: 800; 
  font-size: 24px; margin: 0 0 5px 0;
}
.login-sub { text-align: center; color: #64748b; font-size: 14px; margin-bottom: 25px; }
.login-card .form-control { 
  font-size: 17px; padding: 14px 16px; border-radius: 14px;
  border: 2px solid #e2e8f0; transition: all 0.2s;
}
.login-card .form-control:focus { 
  border-color: #10b981; box-shadow: 0 0 0 4px rgba(16,185,129,0.1);
}
.login-btn {
  background: linear-gradient(135deg, #059669, #10b981); color: white; 
  padding: 16px; width: 100%; border: none; border-radius: 14px; 
  font-weight: 700; font-size: 17px; margin-top: 10px;
  cursor: pointer; transition: transform 0.2s;
  box-shadow: 0 4px 15px rgba(16,185,129,0.3);
}
.login-btn:active { transform: scale(0.98); }
.login-error {
  background: #fee2e2; color: #991b1b; padding: 12px;
  border-radius: 10px; margin-bottom: 15px; font-size: 14px;
}

/* === DASHBOARD === */
.app-header {
  background: linear-gradient(135deg, #059669, #10b981);
  color: white; padding: 20px;
  position: sticky; top: 0; z-index: 100;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}
.app-header-name { font-weight: 700; font-size: 18px; margin: 0; }
.app-header-region { opacity: 0.9; font-size: 14px; margin: 3px 0 0 0; }

/* === HOME CARDS === */
.stat-grid { 
  display: grid; grid-template-columns: 1fr 1fr; 
  gap: 12px; padding: 15px; 
}
.stat-card {
  background: white; padding: 18px; border-radius: 16px;
  text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  border-left: 4px solid #10b981;
}
.stat-card-icon { font-size: 28px; margin-bottom: 8px; }
.stat-card-value { font-size: 26px; font-weight: 800; color: #065f46; }
.stat-card-label { font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; }

/* === ACTION BUTTONS === */
.action-list { padding: 5px 15px 80px 15px; }
.action-btn {
  display: flex; align-items: center; gap: 15px;
  background: white; padding: 18px; border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  margin-bottom: 12px; cursor: pointer; transition: all 0.2s;
  border: none; width: 100%; text-align: left;
}
.action-btn:active { transform: scale(0.98); background: #f0fdf4; }
.action-btn-icon { 
  width: 50px; height: 50px; border-radius: 14px;
  background: #d1fae5; display: flex; align-items: center; 
  justify-content: center; font-size: 24px; flex-shrink: 0;
}
.action-btn-text { flex: 1; }
.action-btn-title { font-weight: 700; color: #065f46; font-size: 16px; margin: 0; }
.action-btn-desc { color: #64748b; font-size: 13px; margin: 3px 0 0 0; }
.action-btn-arrow { color: #94a3b8; font-size: 20px; }

/* === FORMS === */
.form-section { padding: 15px; }
.form-section .form-control,
.form-section .selectize-input,
.form-section textarea {
  font-size: 17px !important; padding: 14px !important;
  border-radius: 12px !important; border: 2px solid #e2e8f0 !important;
}
.form-section label {
  font-weight: 600; color: #334155; font-size: 14px;
  margin-bottom: 6px; display: block;
}
.btn-success-mobile {
  background: linear-gradient(135deg, #059669, #10b981) !important;
  color: white !important; padding: 16px !important;
  width: 100%; border: none !important; border-radius: 14px !important;
  font-weight: 700; font-size: 17px; margin-top: 15px;
  box-shadow: 0 4px 15px rgba(16,185,129,0.3);
}
.btn-secondary-mobile {
  background: white !important; color: #64748b !important;
  padding: 14px !important; width: 100%; 
  border: 2px solid #e2e8f0 !important; border-radius: 14px !important;
  font-weight: 600; margin-top: 10px;
}

/* === BOTTOM NAV === */
.bottom-nav {
  position: fixed; bottom: 0; left: 0; right: 0;
  background: white; box-shadow: 0 -2px 10px rgba(0,0,0,0.08);
  display: flex; padding: 8px 0; z-index: 90;
}
.bottom-nav-item {
  flex: 1; text-align: center; padding: 8px 4px;
  cursor: pointer; transition: all 0.2s;
  border: none; background: transparent;
}
.bottom-nav-item.active { color: #10b981; }
.bottom-nav-item:not(.active) { color: #94a3b8; }
.bottom-nav-icon { font-size: 22px; display: block; }
.bottom-nav-label { font-size: 11px; margin-top: 2px; font-weight: 600; }

/* Spacing */
.page-content { padding-bottom: 80px; }
.section-title { 
  font-weight: 700; color: #0f172a; font-size: 18px;
  padding: 15px 15px 8px; margin: 0;
}

/* DT mobile */
.dataTables_wrapper { font-size: 14px; }
.dataTables_wrapper .dataTables_filter { display: none; }
.dataTables_wrapper .dataTables_length { display: none; }

@media (max-width: 380px) {
  .stat-card-value { font-size: 22px; }
  .action-btn { padding: 14px; }
}
"

# ═══════════════════════════════════════════════════════════════
# UI
# ═══════════════════════════════════════════════════════════════

# LOGIN UI
login_page <- function() {
  fluidPage(
    useShinyjs(),
    tags$head(tags$title("ARTI TTİ — Regional"), tags$style(HTML(mobile_css))),
    div(class = "login-bg",
      div(class = "login-card",
        div(class = "login-icon", "📱"),
        h1("ARTI TTİ", class = "login-title"),
        p("Regional İşçi Paneli", class = "login-sub"),
        uiOutput("login_err"),
        textInput("usr", "👤 İstifadəçi adı", placeholder = "rw_01", width = "100%"),
        passwordInput("pwd", "🔑 Parol", placeholder = "••••••••", width = "100%"),
        actionButton("do_login", "🚀 Daxil ol", class = "login-btn"),
        div(style = "text-align:center; margin-top:20px; color:#94a3b8; font-size:12px;",
          "ARTI TTİ Regional v1.0 · Mobile Edition")
      )
    )
  )
}

# MAIN APP UI
main_app_ui <- function() {
  fluidPage(
    useShinyjs(), useWaiter(),
    tags$head(
      tags$title("ARTI TTİ — Regional"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"),
      tags$style(HTML(mobile_css))
    ),
    
    # Header
    div(class = "app-header",
      div(style = "display:flex; justify-content:space-between; align-items:center;",
        div(
          uiOutput("hdr_name"),
          uiOutput("hdr_region")
        ),
        actionLink("logout", "🚪", style = "color:white; font-size:24px; text-decoration:none;")
      )
    ),
    
    # Page content (dynamic)
    div(class = "page-content",
      uiOutput("page_content")
    ),
    
    # Bottom navigation
    div(class = "bottom-nav",
      actionButton("nav_home", 
        HTML("<span class='bottom-nav-icon'>🏠</span><span class='bottom-nav-label'>Ana</span>"),
        class = "bottom-nav-item active", id = "btn_home"),
      actionButton("nav_projects", 
        HTML("<span class='bottom-nav-icon'>🏗️</span><span class='bottom-nav-label'>Layihələr</span>"),
        class = "bottom-nav-item", id = "btn_projects"),
      actionButton("nav_inspect", 
        HTML("<span class='bottom-nav-icon'>🔍</span><span class='bottom-nav-label'>Yoxlama</span>"),
        class = "bottom-nav-item", id = "btn_inspect"),
      actionButton("nav_complaint", 
        HTML("<span class='bottom-nav-icon'>📧</span><span class='bottom-nav-label'>Şikayət</span>"),
        class = "bottom-nav-item", id = "btn_complaint"),
      actionButton("nav_report", 
        HTML("<span class='bottom-nav-icon'>📋</span><span class='bottom-nav-label'>Hesabat</span>"),
        class = "bottom-nav-item", id = "btn_report")
    )
  )
}

# Router
ui <- function(request) uiOutput("router")

# ═══════════════════════════════════════════════════════════════
# SERVER
# ═══════════════════════════════════════════════════════════════
server <- function(input, output, session) {
  
  # ═══ STATE ═══
  state <- reactiveValues(
    logged_in = FALSE,
    user_id = NULL,
    username = NULL,
    full_name = NULL,
    region_id = NULL,
    region_name = NULL,
    page = "home",
    error_msg = NULL
  )
  
  # ═══ ROUTER ═══
  output$router <- renderUI({
    if (isTRUE(state$logged_in)) main_app_ui()
    else login_page()
  })
  
  # ═══ LOGIN ═══
  output$login_err <- renderUI({
    if (!is.null(state$error_msg)) 
      div(class = "login-error", "⚠️ ", state$error_msg)
  })
  
  observeEvent(input$do_login, {
    req(input$usr, input$pwd)
    
    conn <- get_connection_info(session)
    username <- trimws(input$usr)
    
    result <- authenticate(username, input$pwd)
    
    if (isTRUE(result$is_valid)) {
      # Yalnız regional_worker rolu daxil ola bilər
      if (as.character(result$role) != "regional_worker") {
        state$error_msg <- "Bu app yalnız regional işçilər üçündür. Dashboard-dan istifadə edin."
        dbExecute(pool, "SELECT audit.log_login($1, 'failed', $2::inet, $3, $4, $5)",
                  params = list(username, conn$ip, conn$user_agent, conn$tailscale,
                               "wrong_app_for_role"))
        return()
      }
      
      # Region info al
      region_info <- safe_query("
        SELECT u.region_id, COALESCE(r.name_az, 'Təyin olunmayıb') AS region_name
        FROM audit.users u 
        LEFT JOIN geo.regions r ON u.region_id = r.id 
        WHERE u.id = $1", 
        params = list(result$user_id))
      
      if (nrow(region_info) == 0 || is.na(region_info$region_id[1])) {
        state$error_msg <- "Sizə rayon təyin olunmayıb. Admin ilə əlaqə saxlayın."
        return()
      }
      
      state$logged_in <- TRUE
      state$user_id <- result$user_id
      state$username <- result$username
      state$full_name <- result$full_name
      state$region_id <- region_info$region_id[1]
      state$region_name <- region_info$region_name[1]
      state$error_msg <- NULL
      state$page <- "home"
      
      dbExecute(pool, "SELECT audit.log_login($1, 'success', $2::inet, $3, $4, NULL)",
                params = list(username, conn$ip, conn$user_agent, conn$tailscale))
      
      log_action(result$user_id, "LOGIN", "session", "Mobile login",
                 ip = conn$ip, tailscale = conn$tailscale, user_agent = conn$user_agent)
    } else {
      state$error_msg <- result$error_msg
      dbExecute(pool, "SELECT audit.log_login($1, 'failed', $2::inet, $3, $4, $5)",
                params = list(username, conn$ip, conn$user_agent, conn$tailscale,
                             result$error_msg))
    }
  })
  
  # ═══ LOGOUT ═══
  observeEvent(input$logout, {
    if (!is.null(state$user_id)) {
      conn <- get_connection_info(session)
      log_action(state$user_id, "LOGOUT", "session", "Mobile logout", ip = conn$ip)
    }
    state$logged_in <- FALSE
    state$user_id <- NULL
    state$page <- "home"
    showNotification("👋 Görüşənədək!", duration = 2)
  })
  
  # ═══ HEADER ═══
  output$hdr_name <- renderUI({
    req(state$full_name)
    last_name <- strsplit(state$full_name, " ")[[1]][1]
    h3(paste("👋", last_name), class = "app-header-name")
  })
  
  output$hdr_region <- renderUI({
    req(state$region_name)
    p(paste("📍", state$region_name), class = "app-header-region")
  })
  
  # ═══ NAVIGATION ═══
  observeEvent(input$nav_home,      { state$page <- "home" })
  observeEvent(input$nav_projects,  { state$page <- "projects" })
  observeEvent(input$nav_inspect,   { state$page <- "inspect" })
  observeEvent(input$nav_complaint, { state$page <- "complaint" })
  observeEvent(input$nav_report,    { state$page <- "report" })
  
  # ═══ PAGE CONTENT ROUTER ═══
  output$page_content <- renderUI({
    req(state$logged_in)
    switch(state$page,
      "home"      = page_home(),
      "projects"  = page_projects(),
      "inspect"   = page_inspect(),
      "complaint" = page_complaint(),
      "report"    = page_report()
    )
  })
  
  # ═══ PAGE: HOME ═══
  page_home <- function() {
    region_id <- isolate(state$region_id)
    
    # Statistika
    stats <- safe_query("
      SELECT 
        (SELECT COUNT(*) FROM construction.projects 
         WHERE region_id = $1 AND status = 'in_progress') AS active_projects,
        (SELECT COUNT(*) FROM construction.projects 
         WHERE region_id = $1) AS total_projects,
        (SELECT COUNT(*) FROM construction.inspections ins
         JOIN construction.projects p ON ins.project_id = p.id
         WHERE p.region_id = $1 AND ins.inspection_date >= CURRENT_DATE - 7) AS week_inspections,
        (SELECT COUNT(*) FROM construction.citizen_complaints cc
         LEFT JOIN infra.schools s ON cc.school_id = s.id
         WHERE s.region_id = $1 AND cc.status IN ('new','investigating')) AS pending_complaints
    ", params = list(region_id))
    
    tagList(
      h2("Bu gün", class = "section-title"),
      
      div(class = "stat-grid",
        div(class = "stat-card",
          div(class = "stat-card-icon", "🏗️"),
          div(class = "stat-card-value", stats$active_projects %||% 0),
          div(class = "stat-card-label", "Aktiv layihə")
        ),
        div(class = "stat-card",
          div(class = "stat-card-icon", "📊"),
          div(class = "stat-card-value", stats$total_projects %||% 0),
          div(class = "stat-card-label", "Cəmi layihə")
        ),
        div(class = "stat-card",
          div(class = "stat-card-icon", "🔍"),
          div(class = "stat-card-value", stats$week_inspections %||% 0),
          div(class = "stat-card-label", "Bu həftə yoxlama")
        ),
        div(class = "stat-card",
          div(class = "stat-card-icon", "📧"),
          div(class = "stat-card-value", stats$pending_complaints %||% 0),
          div(class = "stat-card-label", "Açıq şikayət")
        )
      ),
      
      h2("Sürətli əməliyyatlar", class = "section-title"),
      
      div(class = "action-list",
        actionButton("quick_inspect",
          HTML("<div class='action-btn-icon'>🔍</div>
                <div class='action-btn-text'>
                  <p class='action-btn-title'>Yeni Yoxlama</p>
                  <p class='action-btn-desc'>Layihə üzrə keyfiyyət qiymətləndirməsi</p>
                </div>
                <div class='action-btn-arrow'>›</div>"),
          class = "action-btn"),
        
        actionButton("quick_complaint",
          HTML("<div class='action-btn-icon'>📧</div>
                <div class='action-btn-text'>
                  <p class='action-btn-title'>Şikayət Qeydə Al</p>
                  <p class='action-btn-desc'>Vətəndaşdan gələn müraciət</p>
                </div>
                <div class='action-btn-arrow'>›</div>"),
          class = "action-btn"),
        
        actionButton("quick_report",
          HTML("<div class='action-btn-icon'>📋</div>
                <div class='action-btn-text'>
                  <p class='action-btn-title'>Gündəlik Hesabat</p>
                  <p class='action-btn-desc'>Bu günkü iş haqqında</p>
                </div>
                <div class='action-btn-arrow'>›</div>"),
          class = "action-btn"),
        
        actionButton("quick_projects",
          HTML("<div class='action-btn-icon'>🏗️</div>
                <div class='action-btn-text'>
                  <p class='action-btn-title'>Mənim Layihələrim</p>
                  <p class='action-btn-desc'>Region üzrə bütün layihələr</p>
                </div>
                <div class='action-btn-arrow'>›</div>"),
          class = "action-btn")
      )
    )
  }
  
  # Quick action navigation
  observeEvent(input$quick_inspect,   { state$page <- "inspect" })
  observeEvent(input$quick_complaint, { state$page <- "complaint" })
  observeEvent(input$quick_report,    { state$page <- "report" })
  observeEvent(input$quick_projects,  { state$page <- "projects" })
  
  # ═══ PAGE: PROJECTS ═══
  page_projects <- function() {
    region_id <- isolate(state$region_id)
    projects <- safe_query("
      SELECT 
        p.id, p.project_code, p.name,
        s.name AS school_name,
        p.status, p.priority, p.progress_percent,
        p.start_date, p.end_date,
        ROUND(p.planned_budget/1000) AS budget_k
      FROM construction.projects p
      LEFT JOIN infra.schools s ON p.school_id = s.id
      WHERE p.region_id = $1
      ORDER BY 
        CASE p.status 
          WHEN 'in_progress' THEN 1 
          WHEN 'approved' THEN 2 
          WHEN 'planned' THEN 3 
          WHEN 'completed' THEN 4 
          ELSE 5 END,
        p.start_date DESC
    ", params = list(region_id))
    
    tagList(
      h2(paste("Layihələr (", nrow(projects), ")"), class = "section-title"),
      div(class = "form-section",
        if (nrow(projects) == 0) {
          div(style = "text-align:center; padding:40px; color:#94a3b8;",
            div(style = "font-size:48px;", "📭"),
            p("Bu rayonda layihə yoxdur"))
        } else {
          DT::DTOutput("tbl_my_projects")
        }
      )
    )
  }
  
  output$tbl_my_projects <- DT::renderDT({
    req(state$logged_in, state$page == "projects")
    region_id <- isolate(state$region_id)
    
    d <- safe_query("
      SELECT 
        p.project_code AS \"Kod\",
        LEFT(p.name, 40) AS \"Ad\",
        p.status AS \"Status\",
        p.progress_percent AS \"İcra %\",
        ROUND(p.planned_budget/1000) AS \"Büdcə (K)\"
      FROM construction.projects p
      WHERE p.region_id = $1
      ORDER BY p.start_date DESC
    ", params = list(region_id))
    
    DT::datatable(d,
      options = list(pageLength = 10, scrollX = TRUE, dom = 't'),
      rownames = FALSE)
  })
  
  # ═══ PAGE: INSPECT (yeni yoxlama) ═══
  page_inspect <- function() {
    region_id <- isolate(state$region_id)
    
    # Region-dakı aktiv layihələr
    projects <- safe_query("
      SELECT id, project_code || ' — ' || LEFT(name, 35) AS label
      FROM construction.projects 
      WHERE region_id = $1 AND status IN ('in_progress','approved')
      ORDER BY project_code
    ", params = list(region_id))
    
    project_choices <- if (nrow(projects) > 0) 
      setNames(projects$id, projects$label) 
    else c("Heç bir aktiv layihə yoxdur" = "")
    
    tagList(
      h2("🔍 Yeni Yoxlama", class = "section-title"),
      
      div(class = "form-section",
        selectInput("ins_project", "🏗️ Layihə",
                    choices = project_choices, width = "100%"),
        
        selectInput("ins_type", "📋 Yoxlama növü",
                    choices = c("Planlı" = "scheduled",
                               "Plansız" = "unscheduled",
                               "Şikayət əsasında" = "complaint",
                               "Qəbul" = "acceptance",
                               "Yekun" = "final"),
                    width = "100%"),
        
        sliderInput("ins_quality", "⭐ Keyfiyyət balı (0-10)",
                    min = 0, max = 10, value = 7, step = 0.5, width = "100%"),
        
        numericInput("ins_issues_found", "⚠️ Tapılan nöqsan sayı",
                     value = 0, min = 0, max = 50, width = "100%"),
        
        numericInput("ins_issues_resolved", "✅ Həll olunan nöqsan sayı",
                     value = 0, min = 0, max = 50, width = "100%"),
        
        textAreaInput("ins_report", "📝 Hesabat mətni",
                      placeholder = "Yoxlama nəticəsi haqqında qısa məlumat...",
                      rows = 4, width = "100%"),
        
        checkboxInput("ins_followup", "🔄 Təkrar yoxlama tələb olunur"),
        
        actionButton("ins_save", "💾 Yoxlamanı saxla",
                     class = "btn-success-mobile", icon = icon("save")),
        
        actionButton("ins_cancel", "✖️ Ləğv et",
                     class = "btn-secondary-mobile")
      )
    )
  }
  
  observeEvent(input$ins_cancel, { state$page <- "home" })
  
  observeEvent(input$ins_save, {
    req(input$ins_project, input$ins_project != "")
    
    region_id <- isolate(state$region_id)
    user_id <- isolate(state$user_id)
    
    # İnspector ID-sini yoxla — əgər user employee deyilsə, NULL olaraq yaza bilərik
    # Sadə həll: ilk inspector-u götür region-dan
    inspector_id <- safe_query("
      SELECT e.id FROM hr.employees e
      WHERE e.region_id = $1 AND e.position_id IN 
        (SELECT id FROM hr.positions WHERE code IN ('CHIEF_INSP','INSPECTOR'))
      ORDER BY RANDOM() LIMIT 1
    ", params = list(region_id))
    
    inspector_v <- if (nrow(inspector_id) > 0) as.integer(inspector_id$id[1]) else NA_integer_
    
    success <- safe_execute("
      INSERT INTO construction.inspections (
        project_id, inspector_id, inspection_type, inspection_date,
        quality_score, issues_found, issues_resolved,
        requires_followup, followup_date, report_text
      ) VALUES ($1, $2, $3, CURRENT_DATE, $4, $5, $6, $7, $8, $9)
    ", params = list(
      as.integer(input$ins_project), inspector_v, input$ins_type,
      input$ins_quality, as.integer(input$ins_issues_found),
      as.integer(input$ins_issues_resolved),
      isTRUE(input$ins_followup),
      if (isTRUE(input$ins_followup)) Sys.Date() + 14 else as.Date(NA),
      paste0("[Mobile by ", isolate(state$username), "] ", input$ins_report)
    ))
    
    if (success) {
      conn <- get_connection_info(session)
      log_action(user_id, "INSERT", "inspections", 
                 paste("Project:", input$ins_project, "Quality:", input$ins_quality),
                 ip = conn$ip)
      
      showNotification("✅ Yoxlama uğurla saxlandı!", type = "message", duration = 4)
      
      # Form sıfırla
      updateSliderInput(session, "ins_quality", value = 7)
      updateNumericInput(session, "ins_issues_found", value = 0)
      updateNumericInput(session, "ins_issues_resolved", value = 0)
      updateTextAreaInput(session, "ins_report", value = "")
      updateCheckboxInput(session, "ins_followup", value = FALSE)
      
      # Ana səhifəyə qayıt
      state$page <- "home"
    } else {
      showNotification("❌ Xəta baş verdi. Yenidən cəhd edin.", type = "error", duration = 5)
    }
  })
  
  # ═══ PAGE: COMPLAINT ═══
  page_complaint <- function() {
    region_id <- isolate(state$region_id)
    
    schools <- safe_query("
      SELECT id, code || ' — ' || LEFT(name, 30) AS label
      FROM infra.schools 
      WHERE region_id = $1 AND is_active
      ORDER BY code
    ", params = list(region_id))
    
    school_choices <- c("(Konkret məktəb yoxdur)" = "0")
    if (nrow(schools) > 0) {
      school_choices <- c(school_choices, setNames(schools$id, schools$label))
    }
    
    tagList(
      h2("📧 Vətəndaş Şikayəti", class = "section-title"),
      
      div(class = "form-section",
        selectInput("cmp_school", "🏫 Məktəb (opsional)",
                    choices = school_choices, width = "100%"),
        
        selectInput("cmp_channel", "📞 Müraciət kanalı",
                    choices = c("Telefon" = "phone",
                               "ASAN" = "asan",
                               "Email" = "email",
                               "Yazılı müraciət" = "letter",
                               "Veb sayt" = "website"),
                    width = "100%"),
        
        selectInput("cmp_category", "📂 Kateqoriya",
                    choices = c("İstilik" = "heating",
                               "Dam" = "roof",
                               "Təhlükəsizlik" = "safety",
                               "Korrupsiya" = "corruption",
                               "Keyfiyyət" = "quality",
                               "Vaxt çatışmazlığı" = "timeline",
                               "Materiallar" = "materials",
                               "Podratçı" = "contractor",
                               "Sanitariya" = "hygiene",
                               "Əlçatımlılıq" = "accessibility"),
                    width = "100%"),
        
        selectInput("cmp_urgency", "🚨 Təcili dərəcə",
                    choices = c("Aşağı" = "low",
                               "Normal" = "normal",
                               "Yüksək" = "high",
                               "Kritik" = "critical"),
                    selected = "normal", width = "100%"),
        
        textAreaInput("cmp_text", "📝 Şikayət mətni",
                      placeholder = "Vətəndaşın müraciətini ətraflı qeyd edin...",
                      rows = 5, width = "100%"),
        
        actionButton("cmp_save", "💾 Şikayəti qeydə al",
                     class = "btn-success-mobile"),
        
        actionButton("cmp_cancel", "✖️ Ləğv et",
                     class = "btn-secondary-mobile")
      )
    )
  }
  
  observeEvent(input$cmp_cancel, { state$page <- "home" })
  
  observeEvent(input$cmp_save, {
    req(input$cmp_text, nchar(trimws(input$cmp_text)) > 10)
    
    user_id <- isolate(state$user_id)
    school_id_v <- if (input$cmp_school == "0") NA_integer_ else as.integer(input$cmp_school)
    
    success <- safe_execute("
      INSERT INTO construction.citizen_complaints (
        school_id, complaint_date, channel, category,
        urgency, status, text
      ) VALUES ($1, CURRENT_DATE, $2, $3, $4, 'new', $5)
    ", params = list(
      school_id_v, input$cmp_channel, input$cmp_category,
      input$cmp_urgency,
      paste0("[Mobile by ", isolate(state$username), "] ", input$cmp_text)
    ))
    
    if (success) {
      conn <- get_connection_info(session)
      log_action(user_id, "INSERT", "complaints",
                 paste("Category:", input$cmp_category, "Urgency:", input$cmp_urgency),
                 ip = conn$ip)
      
      showNotification("✅ Şikayət uğurla qeydə alındı!", type = "message", duration = 4)
      
      updateTextAreaInput(session, "cmp_text", value = "")
      updateSelectInput(session, "cmp_school", selected = "0")
      
      state$page <- "home"
    } else {
      showNotification("❌ Xəta baş verdi", type = "error", duration = 5)
    }
  })
  
  # ═══ PAGE: REPORT (gündəlik hesabat) ═══
  page_report <- function() {
    region_id <- isolate(state$region_id)
    
    projects <- safe_query("
      SELECT id, project_code || ' — ' || LEFT(name, 35) AS label
      FROM construction.projects 
      WHERE region_id = $1 AND status = 'in_progress'
      ORDER BY project_code
    ", params = list(region_id))
    
    proj_choices <- c("(Konkret layihə yox)" = "0")
    if (nrow(projects) > 0) {
      proj_choices <- c(proj_choices, setNames(projects$id, projects$label))
    }
    
    tagList(
      h2("📋 Gündəlik Hesabat", class = "section-title"),
      
      div(class = "form-section",
        selectInput("rep_project", "🏗️ Layihə",
                    choices = proj_choices, width = "100%"),
        
        selectInput("rep_weather", "☀️ Hava",
                    choices = c("Günəşli ☀️" = "sunny",
                               "Buludlu ⛅" = "cloudy",
                               "Yağışlı 🌧️" = "rainy",
                               "Qarlı ❄️" = "snow"),
                    width = "100%"),
        
        numericInput("rep_temp", "🌡️ Temperatur (°C)",
                     value = 20, min = -30, max = 50, width = "100%"),
        
        numericInput("rep_workers", "👷 İşə gələn işçi sayı",
                     value = 0, min = 0, max = 200, width = "100%"),
        
        numericInput("rep_hours", "⏱️ İş saatı",
                     value = 8, min = 0, max = 24, step = 0.5, width = "100%"),
        
        textAreaInput("rep_done", "✅ Görülən iş",
                      placeholder = "Bu gün nə edildi...",
                      rows = 3, width = "100%"),
        
        textAreaInput("rep_issues", "⚠️ Problemlər",
                      placeholder = "Hansısa maneə oldumu?",
                      rows = 3, width = "100%"),
        
        sliderInput("rep_progress", "📊 Cari icra faizi",
                    min = 0, max = 100, value = 0, step = 5,
                    post = "%", width = "100%"),
        
        actionButton("rep_save", "💾 Hesabatı təqdim et",
                     class = "btn-success-mobile"),
        
        actionButton("rep_cancel", "✖️ Ləğv et",
                     class = "btn-secondary-mobile")
      )
    )
  }
  
  observeEvent(input$rep_cancel, { state$page <- "home" })
  
  observeEvent(input$rep_save, {
    # DİAQNOSTİKA — hər şeyi göstər
    cat("\n═══ HESABAT YARATMA CƏHDİ ═══\n")
    cat("rep_done:", input$rep_done, "\n")
    cat("rep_done uzunluq:", nchar(trimws(input$rep_done %||% "")), "\n")
    cat("rep_project:", input$rep_project, "\n")
    cat("rep_workers:", input$rep_workers, "\n")
    cat("rep_weather:", input$rep_weather, "\n")
    cat("user_id:", isolate(state$user_id), "\n")
    cat("region_id:", isolate(state$region_id), "\n")
    
    # Validation — daha rahat 
    if (is.null(input$rep_done) || nchar(trimws(input$rep_done %||% "")) < 3) {
      showNotification("⚠️ 'Görülən iş' sahəsini doldurun (ən az 3 simvol)", 
                       type = "warning", duration = 5)
      return()
    }
    
    user_id <- isolate(state$user_id)
    region_id <- isolate(state$region_id)
    proj_id <- if (input$rep_project == "0" || input$rep_project == "") NA_integer_ else as.integer(input$rep_project)
    
    cat("Final proj_id:", ifelse(is.na(proj_id), "NA", as.character(proj_id)), "\n")
    
    # SQL-i ayrıca dəyişəndə hazırla
    sql_query <- "
      INSERT INTO construction.daily_reports (
        worker_id, region_id, project_id, report_date,
        weather, temperature, workers_count, hours_worked,
        work_done, issues, progress_after
      ) VALUES ($1, $2, $3, CURRENT_DATE, $4, $5, $6, $7, $8, $9, $10)
      RETURNING id"
    
    result <- tryCatch({
      dbGetQuery(pool, sql_query, params = list(
        as.integer(user_id), 
        as.integer(region_id), 
        proj_id,
        input$rep_weather, 
        as.numeric(input$rep_temp),
        as.integer(input$rep_workers), 
        as.numeric(input$rep_hours),
        input$rep_done, 
        input$rep_issues %||% "", 
        as.numeric(input$rep_progress)
      ))
    }, error = function(e) {
      cat("❌ SQL XƏTA:", e$message, "\n")
      showNotification(paste("❌ Xəta:", e$message), type = "error", duration = 8)
      NULL
    })
    
    if (!is.null(result) && nrow(result) > 0) {
      cat("✅ Hesabat ID:", result$id, "\n")
      
      conn <- get_connection_info(session)
      log_action(user_id, "INSERT", "daily_report",
                 paste("Workers:", input$rep_workers, "Hours:", input$rep_hours),
                 ip = conn$ip)
      
      showNotification(paste0("✅ Hesabat #", result$id, " təqdim edildi!"), 
                       type = "message", duration = 4)
      
      updateTextAreaInput(session, "rep_done", value = "")
      updateTextAreaInput(session, "rep_issues", value = "")
      updateSliderInput(session, "rep_progress", value = 0)
      updateNumericInput(session, "rep_workers", value = 0)
      
      state$page <- "home"
    }
  })
  
  # Sessiya bağlananda log
  session$onSessionEnded(function() {
    if (!is.null(isolate(state$user_id))) {
      tryCatch({
        log_action(isolate(state$user_id), "LOGOUT", "session", "Session ended")
      }, error = function(e) NULL)
    }
    cat("[INFO] Regional sessiya bağlandı\n")
  })
  
  cat("[INFO] Regional app başladı:", session$token, "\n")
}

shinyApp(ui, server)
