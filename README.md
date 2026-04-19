# 🎓 ARTI Universal AI Agent Platform

## Konsept
Eyni skelet (Backend + Frontend + Shiny + AI) ilə müxtəlif domenlər üçün 
enterprise sistemlər qurmaq. 

## Domenlər

### 1. schools_analytics (mövcud)
- PostgreSQL: `arti_schools`
- 2 məktəb, 108 şagird, 40 müəllim
- Qiymət və davamiyyət analitikası

### 2. construction_management (yeni) 
- PostgreSQL: `arti_construction`
- 77 rayon, 120+ layihə
- Tikinti-təmir işlərinin idarə edilməsi

## Paylaşılan kompanentlər
- `shared/backend/` — Node.js API (invariant)
- `shared/frontend/` — React UI (invariant)

## İşlətmə
Hər domen ayrıca işləyə bilər və ya 
hamısı eyni backend-dən idarə oluna bilər.

Author: Talıbov Tariyel İsmayıl oğlu, ARTI
