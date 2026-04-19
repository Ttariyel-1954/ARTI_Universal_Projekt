-- ═══════════════════════════════════════════════════════════════
-- ARTI Construction Management — Enterprise Schema
-- Database: arti_construction
-- Author: Talıbov Tariyel İsmayıl oğlu, ARTI
-- Version: 1.0.0
-- ═══════════════════════════════════════════════════════════════

-- ─── Schema-ları yaradırıq ───
CREATE SCHEMA IF NOT EXISTS geo;
CREATE SCHEMA IF NOT EXISTS infra;
CREATE SCHEMA IF NOT EXISTS construction;
CREATE SCHEMA IF NOT EXISTS finance;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS hr;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS reporting;

-- ═══════════════════════════════════════════════════════════════
-- 1️⃣ geo — Coğrafi data
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE geo.region_types (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(20) UNIQUE NOT NULL,
    name_az     VARCHAR(100) NOT NULL,
    priority    SMALLINT DEFAULT 5 CHECK (priority BETWEEN 1 AND 10)
);

CREATE TABLE geo.regions (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(10) UNIQUE NOT NULL,
    name_az         VARCHAR(100) NOT NULL,
    type_id         INT NOT NULL REFERENCES geo.region_types(id),
    population      INT CHECK (population > 0),
    area_km2        NUMERIC(10,2),
    center_lat      NUMERIC(9,6) CHECK (center_lat BETWEEN 38.0 AND 42.0),
    center_lng      NUMERIC(9,6) CHECK (center_lng BETWEEN 44.0 AND 51.0),
    is_active       BOOLEAN DEFAULT TRUE,
    school_count    INT DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE geo.settlements (
    id              SERIAL PRIMARY KEY,
    region_id       INT NOT NULL REFERENCES geo.regions(id) ON DELETE CASCADE,
    name_az         VARCHAR(150) NOT NULL,
    settlement_type VARCHAR(30) CHECK (settlement_type IN ('city','town','village','settlement')),
    population      INT,
    is_district_center BOOLEAN DEFAULT FALSE
);

-- ═══════════════════════════════════════════════════════════════
-- 2️⃣ infra — İnfrastruktur (məktəblər, binalar)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE infra.school_types (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(30) UNIQUE NOT NULL,
    name_az     VARCHAR(100) NOT NULL,
    level       VARCHAR(20) CHECK (level IN ('primary','secondary','high','mixed','special'))
);

CREATE TABLE infra.schools (
    id                  SERIAL PRIMARY KEY,
    code                VARCHAR(20) UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    region_id           INT NOT NULL REFERENCES geo.regions(id),
    type_id             INT REFERENCES infra.school_types(id),
    settlement_id       INT REFERENCES geo.settlements(id),
    address             VARCHAR(300),
    student_count       INT CHECK (student_count >= 0),
    teacher_count       INT CHECK (teacher_count >= 0),
    total_area_m2       NUMERIC(10,2),
    built_year          SMALLINT CHECK (built_year BETWEEN 1900 AND 2030),
    last_major_repair   DATE,
    condition           VARCHAR(20) CHECK (condition IN ('excellent','good','satisfactory','poor','critical')),
    has_heating         BOOLEAN DEFAULT FALSE,
    has_canteen         BOOLEAN DEFAULT FALSE,
    has_gym             BOOLEAN DEFAULT FALSE,
    has_library         BOOLEAN DEFAULT FALSE,
    has_computer_lab    BOOLEAN DEFAULT FALSE,
    director_name       VARCHAR(200),
    phone               VARCHAR(20),
    email               VARCHAR(100),
    lat                 NUMERIC(9,6),
    lng                 NUMERIC(9,6),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE infra.buildings (
    id                    SERIAL PRIMARY KEY,
    school_id             INT NOT NULL REFERENCES infra.schools(id) ON DELETE CASCADE,
    building_type         VARCHAR(30) CHECK (building_type IN ('main','annex','dormitory','gym','canteen','boiler','workshop')),
    floors                SMALLINT CHECK (floors BETWEEN 1 AND 10),
    area_m2               NUMERIC(10,2),
    year_built            SMALLINT,
    classroom_count       SMALLINT,
    structural_condition  NUMERIC(3,1) CHECK (structural_condition BETWEEN 0 AND 10),
    created_at            TIMESTAMP DEFAULT NOW()
);

CREATE TABLE infra.condition_assessments (
    id                  SERIAL PRIMARY KEY,
    building_id         INT NOT NULL REFERENCES infra.buildings(id),
    assessment_date     DATE NOT NULL,
    inspector_id        INT,  -- FK əlavə olunacaq sonra
    overall_score       NUMERIC(3,1) CHECK (overall_score BETWEEN 0 AND 10),
    roof_score          NUMERIC(3,1),
    walls_score         NUMERIC(3,1),
    heating_score       NUMERIC(3,1),
    electrical_score    NUMERIC(3,1),
    plumbing_score      NUMERIC(3,1),
    urgency             VARCHAR(20) CHECK (urgency IN ('low','normal','high','urgent')),
    estimated_cost      NUMERIC(14,2),
    recommendations     TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════
-- 3️⃣ hr — İşçi heyət və podratçılar
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE hr.departments (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(20) UNIQUE NOT NULL,
    name_az     VARCHAR(200) NOT NULL,
    parent_id   INT REFERENCES hr.departments(id)
);

CREATE TABLE hr.positions (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(30) UNIQUE NOT NULL,
    name_az         VARCHAR(150) NOT NULL,
    category        VARCHAR(30) CHECK (category IN ('management','engineering','construction','admin','inspection','finance')),
    salary_min      NUMERIC(10,2),
    salary_max      NUMERIC(10,2)
);

CREATE TABLE hr.employees (
    id                      SERIAL PRIMARY KEY,
    full_name               VARCHAR(200) NOT NULL,
    position_id             INT REFERENCES hr.positions(id),
    department_id           INT REFERENCES hr.departments(id),
    region_id               INT REFERENCES geo.regions(id),
    birth_date              DATE,
    gender                  CHAR(1) CHECK (gender IN ('M','F')),
    phone                   VARCHAR(20),
    email                   VARCHAR(100),
    hire_date               DATE,
    monthly_salary          NUMERIC(10,2) CHECK (monthly_salary >= 0),
    qualification_level     SMALLINT CHECK (qualification_level BETWEEN 1 AND 5),
    certifications          TEXT[],
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMP DEFAULT NOW()
);

CREATE TABLE hr.contractors (
    id                      SERIAL PRIMARY KEY,
    name                    VARCHAR(200) NOT NULL,
    tin                     VARCHAR(15) UNIQUE NOT NULL,
    category                VARCHAR(50) CHECK (category IN ('general','electrical','plumbing','hvac','roofing','finishing','specialized')),
    registration_date       DATE,
    address                 VARCHAR(300),
    phone                   VARCHAR(20),
    email                   VARCHAR(100),
    director_name           VARCHAR(200),
    employee_count          INT,
    rating                  NUMERIC(3,1) CHECK (rating BETWEEN 0 AND 10),
    completed_projects      INT DEFAULT 0,
    total_revenue           NUMERIC(14,2) DEFAULT 0,
    is_blacklisted          BOOLEAN DEFAULT FALSE,
    blacklist_reason        TEXT,
    created_at              TIMESTAMP DEFAULT NOW()
);

CREATE TABLE hr.teams (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    team_type       VARCHAR(30) CHECK (team_type IN ('masonry','electrical','plumbing','roofing','finishing','general')),
    leader_id       INT REFERENCES hr.employees(id),
    member_count    SMALLINT DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE
);

-- infra.condition_assessments-ə FK əlavə edirik (teaşer yarandı)
ALTER TABLE infra.condition_assessments
    ADD CONSTRAINT fk_cond_inspector
    FOREIGN KEY (inspector_id) REFERENCES hr.employees(id);

-- ═══════════════════════════════════════════════════════════════
-- 4️⃣ inventory — Maddi-texniki baza
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE inventory.material_categories (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(30) UNIQUE NOT NULL,
    name_az     VARCHAR(100) NOT NULL,
    icon        VARCHAR(10)
);

CREATE TABLE inventory.materials (
    id                  SERIAL PRIMARY KEY,
    code                VARCHAR(30) UNIQUE NOT NULL,
    name_az             VARCHAR(200) NOT NULL,
    category_id         INT REFERENCES inventory.material_categories(id),
    unit                VARCHAR(20) CHECK (unit IN ('kg','ton','m','m2','m3','adet','litr','kub_metr','rulon','qutu')),
    standard_price      NUMERIC(10,2) CHECK (standard_price >= 0),
    min_stock_level     NUMERIC(10,2) DEFAULT 0,
    typical_supplier    VARCHAR(200),
    is_active           BOOLEAN DEFAULT TRUE
);

CREATE TABLE inventory.warehouses (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(20) UNIQUE NOT NULL,
    name        VARCHAR(200) NOT NULL,
    region_id   INT REFERENCES geo.regions(id),
    address     VARCHAR(300),
    area_m2     NUMERIC(10,2),
    manager_id  INT REFERENCES hr.employees(id),
    is_central  BOOLEAN DEFAULT FALSE,
    is_active   BOOLEAN DEFAULT TRUE
);

CREATE TABLE inventory.stock_levels (
    warehouse_id    INT REFERENCES inventory.warehouses(id),
    material_id     INT REFERENCES inventory.materials(id),
    quantity        NUMERIC(12,3) DEFAULT 0,
    last_updated    TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (warehouse_id, material_id)
);

CREATE TABLE inventory.equipment (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(30) UNIQUE NOT NULL,
    name            VARCHAR(200) NOT NULL,
    equipment_type  VARCHAR(50),
    warehouse_id    INT REFERENCES inventory.warehouses(id),
    purchase_date   DATE,
    purchase_price  NUMERIC(12,2),
    status          VARCHAR(20) CHECK (status IN ('active','maintenance','broken','retired')),
    assigned_to     INT REFERENCES hr.employees(id)
);

-- ═══════════════════════════════════════════════════════════════
-- 5️⃣ construction — Layihələr (MƏRKƏZ!)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE construction.project_types (
    id                      SERIAL PRIMARY KEY,
    code                    VARCHAR(30) UNIQUE NOT NULL,
    name_az                 VARCHAR(100) NOT NULL,
    typical_duration_days   SMALLINT,
    requires_inspection     BOOLEAN DEFAULT TRUE,
    icon                    VARCHAR(10)
);

CREATE TABLE construction.projects (
    id                  SERIAL PRIMARY KEY,
    project_code        VARCHAR(30) UNIQUE NOT NULL,
    name                VARCHAR(300) NOT NULL,
    type_id             INT NOT NULL REFERENCES construction.project_types(id),
    region_id           INT NOT NULL REFERENCES geo.regions(id),
    school_id           INT REFERENCES infra.schools(id),
    building_id         INT REFERENCES infra.buildings(id),
    manager_id          INT REFERENCES hr.employees(id),
    contractor_id       INT REFERENCES hr.contractors(id),
    status              VARCHAR(30) DEFAULT 'planned' 
                        CHECK (status IN ('planned','approved','in_progress','on_hold','completed','cancelled')),
    priority            SMALLINT DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
    start_date          DATE,
    end_date            DATE,
    actual_start        DATE,
    actual_end          DATE,
    planned_budget      NUMERIC(14,2) CHECK (planned_budget > 0),
    actual_cost         NUMERIC(14,2) DEFAULT 0,
    progress_percent    SMALLINT DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    description         TEXT,
    approval_doc_ref    VARCHAR(100),
    approved_by         VARCHAR(200),
    approved_date       DATE,
    expected_impact     TEXT,
    notes               TEXT,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE construction.project_phases (
    id              SERIAL PRIMARY KEY,
    project_id      INT NOT NULL REFERENCES construction.projects(id) ON DELETE CASCADE,
    phase_number    SMALLINT CHECK (phase_number BETWEEN 1 AND 10),
    name            VARCHAR(100) NOT NULL,
    start_date      DATE,
    end_date        DATE,
    status          VARCHAR(20) DEFAULT 'pending' 
                    CHECK (status IN ('pending','in_progress','completed','skipped')),
    completion_pct  SMALLINT DEFAULT 0 CHECK (completion_pct BETWEEN 0 AND 100),
    notes           TEXT
);

CREATE TABLE construction.inspections (
    id                  SERIAL PRIMARY KEY,
    project_id          INT NOT NULL REFERENCES construction.projects(id),
    inspector_id        INT REFERENCES hr.employees(id),
    inspection_type     VARCHAR(30) CHECK (inspection_type IN ('scheduled','unscheduled','complaint','acceptance','final')),
    inspection_date     DATE NOT NULL,
    quality_score       NUMERIC(3,1) CHECK (quality_score BETWEEN 0 AND 10),
    issues_found        SMALLINT DEFAULT 0,
    issues_resolved     SMALLINT DEFAULT 0,
    requires_followup   BOOLEAN DEFAULT FALSE,
    followup_date       DATE,
    report_text         TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE construction.acts (
    id                      SERIAL PRIMARY KEY,
    project_id              INT NOT NULL REFERENCES construction.projects(id),
    act_number              VARCHAR(50) UNIQUE NOT NULL,
    act_type                VARCHAR(30) CHECK (act_type IN ('intermediate','final','correction','preliminary')),
    act_date                DATE NOT NULL,
    amount                  NUMERIC(14,2),
    signed_by_contractor    BOOLEAN DEFAULT FALSE,
    signed_by_manager       BOOLEAN DEFAULT FALSE,
    signed_by_inspector     BOOLEAN DEFAULT FALSE,
    is_paid                 BOOLEAN DEFAULT FALSE,
    notes                   TEXT,
    created_at              TIMESTAMP DEFAULT NOW()
);

CREATE TABLE construction.citizen_complaints (
    id                  SERIAL PRIMARY KEY,
    school_id           INT REFERENCES infra.schools(id),
    project_id          INT REFERENCES construction.projects(id),
    complaint_date      DATE NOT NULL,
    channel             VARCHAR(20) CHECK (channel IN ('asan','phone','email','letter','website')),
    category            VARCHAR(50),
    urgency             VARCHAR(20) CHECK (urgency IN ('low','normal','high','critical')),
    status              VARCHAR(20) DEFAULT 'new' 
                        CHECK (status IN ('new','investigating','resolved','closed')),
    resolution_date     DATE,
    resolution_days     SMALLINT,
    text                TEXT,
    response_text       TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════
-- 6️⃣ finance — Maliyyə
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE finance.budgets (
    id                  SERIAL PRIMARY KEY,
    fiscal_year         SMALLINT NOT NULL CHECK (fiscal_year BETWEEN 2020 AND 2030),
    region_id           INT REFERENCES geo.regions(id),
    category            VARCHAR(50) CHECK (category IN ('current','capital','construction','emergency','salaries')),
    allocated_amount    NUMERIC(14,2) CHECK (allocated_amount >= 0),
    spent_amount        NUMERIC(14,2) DEFAULT 0,
    reserved_amount     NUMERIC(14,2) DEFAULT 0,
    source              VARCHAR(50) CHECK (source IN ('state','municipal','grant','partner')),
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE finance.expenses (
    id                  SERIAL PRIMARY KEY,
    project_id          INT REFERENCES construction.projects(id),
    expense_date        DATE NOT NULL,
    category            VARCHAR(50) CHECK (category IN ('material','labor','transport','utility','equipment','other')),
    subcategory         VARCHAR(100),
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    vat_included        BOOLEAN DEFAULT TRUE,
    description         TEXT,
    approved_by         INT REFERENCES hr.employees(id),
    invoice_number      VARCHAR(50),
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE TABLE finance.invoices (
    id                  SERIAL PRIMARY KEY,
    invoice_number      VARCHAR(50) UNIQUE NOT NULL,
    contractor_id       INT REFERENCES hr.contractors(id),
    project_id          INT REFERENCES construction.projects(id),
    issue_date          DATE NOT NULL,
    due_date            DATE,
    amount              NUMERIC(14,2) NOT NULL,
    status              VARCHAR(20) DEFAULT 'pending' 
                        CHECK (status IN ('pending','approved','paid','rejected','overdue')),
    notes               TEXT
);

CREATE TABLE finance.payments (
    id                  SERIAL PRIMARY KEY,
    invoice_id          INT REFERENCES finance.invoices(id),
    contractor_id       INT REFERENCES hr.contractors(id),
    payment_date        DATE NOT NULL,
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    method              VARCHAR(30) CHECK (method IN ('bank_transfer','cash','cheque','card')),
    status              VARCHAR(20) DEFAULT 'completed' 
                        CHECK (status IN ('pending','completed','rejected','refunded')),
    reference_number    VARCHAR(100)
);

-- inventory.material_transactions-i sonra əlavə edirik (FK-lər dolu)
CREATE TABLE inventory.material_transactions (
    id                  SERIAL PRIMARY KEY,
    transaction_type    VARCHAR(20) CHECK (transaction_type IN ('in','out','transfer','waste','return')),
    warehouse_id        INT NOT NULL REFERENCES inventory.warehouses(id),
    project_id          INT REFERENCES construction.projects(id),
    material_id         INT NOT NULL REFERENCES inventory.materials(id),
    quantity            NUMERIC(12,3) NOT NULL,
    unit_price          NUMERIC(10,2),
    total_amount        NUMERIC(14,2),
    transaction_date    TIMESTAMP DEFAULT NOW(),
    performed_by        INT REFERENCES hr.employees(id),
    reference_number    VARCHAR(100),
    notes               TEXT
);

-- ═══════════════════════════════════════════════════════════════
-- 7️⃣ audit — Log və izləmə
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE audit.activity_log (
    id              SERIAL PRIMARY KEY,
    user_id         INT,
    action          VARCHAR(50),
    entity_type     VARCHAR(50),
    entity_id       INT,
    ip_address      INET,
    user_agent      TEXT,
    details         JSONB,
    timestamp       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit.notifications (
    id          SERIAL PRIMARY KEY,
    user_id     INT REFERENCES hr.employees(id),
    type        VARCHAR(30),
    severity    VARCHAR(20) CHECK (severity IN ('info','warning','critical')),
    title       VARCHAR(200),
    message     TEXT,
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════
-- 8️⃣ İNDEKSLƏR
-- ═══════════════════════════════════════════════════════════════

-- Projects (ən çox sorğulanan)
CREATE INDEX idx_projects_region      ON construction.projects(region_id);
CREATE INDEX idx_projects_status      ON construction.projects(status);
CREATE INDEX idx_projects_dates       ON construction.projects(start_date, end_date);
CREATE INDEX idx_projects_contractor  ON construction.projects(contractor_id);
CREATE INDEX idx_projects_school      ON construction.projects(school_id);
CREATE INDEX idx_projects_type        ON construction.projects(type_id);

-- Expenses
CREATE INDEX idx_expenses_project   ON finance.expenses(project_id);
CREATE INDEX idx_expenses_date      ON finance.expenses(expense_date);
CREATE INDEX idx_expenses_category  ON finance.expenses(category);

-- Material transactions
CREATE INDEX idx_mat_trans_date      ON inventory.material_transactions(transaction_date);
CREATE INDEX idx_mat_trans_warehouse ON inventory.material_transactions(warehouse_id);
CREATE INDEX idx_mat_trans_project   ON inventory.material_transactions(project_id);

-- Schools
CREATE INDEX idx_schools_region     ON infra.schools(region_id);
CREATE INDEX idx_schools_condition  ON infra.schools(condition);

-- Inspections
CREATE INDEX idx_inspections_project ON construction.inspections(project_id);
CREATE INDEX idx_inspections_date    ON construction.inspections(inspection_date);

-- Complaints
CREATE INDEX idx_complaints_status  ON construction.citizen_complaints(status);
CREATE INDEX idx_complaints_date    ON construction.citizen_complaints(complaint_date);

-- Audit
CREATE INDEX idx_activity_timestamp ON audit.activity_log(timestamp);
CREATE INDEX idx_activity_entity    ON audit.activity_log(entity_type, entity_id);

-- ═══════════════════════════════════════════════════════════════
-- YOXLAMA
-- ═══════════════════════════════════════════════════════════════

\echo '═══════════════════════════════════════════════════════════════'
\echo '✅ Schema yaradıldı. Cədvəl sayı:'
\echo '═══════════════════════════════════════════════════════════════'

SELECT schemaname, COUNT(*) AS table_count
FROM pg_tables
WHERE schemaname IN ('geo','infra','construction','finance','inventory','hr','audit')
GROUP BY schemaname
ORDER BY schemaname;

SELECT '✅ Toplam cədvəl: ' || COUNT(*)::text AS status
FROM pg_tables
WHERE schemaname IN ('geo','infra','construction','finance','inventory','hr','audit');
