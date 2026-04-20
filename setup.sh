#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# ARTI Universal Platform — Quraşdırma skripti (macOS)
# ═══════════════════════════════════════════════════════════════

set -e  # Xəta olarsa dayan

echo "╔═══════════════════════════════════════════════════╗"
echo "║   ARTI Universal Platform — Setup                 ║"
echo "║   v2.0 · $(date +%Y-%m-%d)                               ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# ═══ 1. Sistem yoxla ═══
echo "═══ 1. Sistem yoxlanılır ═══"

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ Bu skript yalnız macOS üçündür"
  exit 1
fi
echo "✅ macOS aşkarlandı"

# ═══ 2. Homebrew yoxla ═══
echo ""
echo "═══ 2. Homebrew ═══"
if ! command -v brew &> /dev/null; then
  echo "⚠️ Homebrew yoxdur — quraşdırılır..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✅ Homebrew mövcuddur"
fi

# ═══ 3. PostgreSQL 18 yoxla ═══
echo ""
echo "═══ 3. PostgreSQL 18 ═══"
if ! brew list postgresql@18 &> /dev/null; then
  echo "⚠️ PostgreSQL yoxdur — quraşdırılır..."
  brew install postgresql@18
  brew services start postgresql@18
  sleep 5
else
  echo "✅ PostgreSQL@18 quraşdırılıb"
  brew services start postgresql@18 2>/dev/null || true
  sleep 3
fi

# Yoxla işləyirmi
if ! pg_isready -h localhost -p 5432 &> /dev/null; then
  echo "❌ PostgreSQL başlamadı — manual yoxlayın"
  exit 1
fi
echo "✅ PostgreSQL işləyir (port 5432)"

# ═══ 4. Database yarat ═══
echo ""
echo "═══ 4. Database yaradılır ═══"

DB_NAME="arti_construction"
DB_USER="$USER"

# Əvvəl varsa sil (təmiz başlamaq üçün)
if psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  echo "⚠️ $DB_NAME artıq mövcuddur"
  read -p "Silmək istəyirsiniz? (y/n): " answer
  if [[ "$answer" == "y" ]]; then
    dropdb $DB_NAME
    echo "✅ Silindi"
  fi
fi

if ! psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  createdb $DB_NAME
  echo "✅ Database yaradıldı: $DB_NAME"
  
  # Dump-dan bərpa et
  echo "⏳ Database bərpa olunur (2-3 dəqiqə)..."
  psql $DB_NAME < database_backup/arti_construction_full.sql > /tmp/restore.log 2>&1
  
  # Yoxla
  USER_COUNT=$(psql $DB_NAME -t -c "SELECT COUNT(*) FROM audit.users")
  echo "✅ Database bərpa olundu ($USER_COUNT istifadəçi)"
fi

# ═══ 5. R yoxla ═══
echo ""
echo "═══ 5. R və RStudio ═══"
if ! command -v R &> /dev/null; then
  echo "⚠️ R yoxdur — quraşdırılır..."
  brew install --cask r
else
  echo "✅ R mövcuddur ($(R --version | head -1))"
fi

if ! command -v rstudio &> /dev/null && [ ! -d "/Applications/RStudio.app" ]; then
  echo "⚠️ RStudio yoxdur — quraşdırılır..."
  brew install --cask rstudio
else
  echo "✅ RStudio quraşdırılıb"
fi

# ═══ 6. R paketləri qur ═══
echo ""
echo "═══ 6. R paketləri quraşdırılır (5-10 dəqiqə)... ═══"

Rscript -e '
packages <- c(
  "shiny", "bs4Dash", "DBI", "RPostgres", "pool",
  "dplyr", "plotly", "DT", "leaflet", "httr2",
  "jsonlite", "shinyjs", "waiter", "shinycssloaders",
  "digest", "bcrypt", "yaml"
)

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Quraşdırılır:", pkg, "\n")
    install.packages(pkg, repos = "https://cran.r-project.org")
  } else {
    cat("✅", pkg, "\n")
  }
}
cat("\n✅ Bütün paketlər hazırdır\n")
'

# ═══ 7. Config faylı yoxla ═══
echo ""
echo "═══ 7. Konfiqurasiya ═══"

if [ ! -f "shared/config.yml" ]; then
  echo "⚠️ config.yml yoxdur — yaradılır..."
  # config.yml template yarat
  cp shared/config.yml.template shared/config.yml 2>/dev/null || {
    echo "⚠️ config.yml.template yoxdur"
  }
fi
echo "✅ config.yml hazırdır"

# ═══ 8. Uploads qovluqları yarat ═══
echo ""
echo "═══ 8. Uploads qovluqları ═══"
mkdir -p uploads/{inspections,complaints,daily_reports,material_movements,thumbnails}
echo "✅ Uploads qovluqları yaradıldı"

# ═══ YEKUN ═══
echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║   ✅ QURAŞDIRMA TAMAMLANDI                        ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
echo "🚀 İndi RStudio-da:"
echo "  1. File → Open: $(pwd)/domains/construction_management/shiny/app.R"
echo "  2. Run App ▶"
echo ""
echo "  Dashboard: http://127.0.0.1:3838"
echo ""
echo "🔐 Test giriş:"
echo "  admin  — no password"
echo "  rw_01  / regional123"
echo ""
echo "📚 Əlavə məlumat: README.md və docs/ARTI_Istifade_Telimati.html"
