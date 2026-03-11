# 🧁 CHAMPS BAKESHOP PAYROLL SYSTEM
## Feature-Based MVVM Architecture — Flutter

---

### Quick Start

```bash
# 1. Create a new Flutter project
flutter create champs_bakeshop
cd champs_bakeshop

# 2. Replace lib/ folder and pubspec.yaml with the ones from this zip

# 3. Install dependencies
flutter pub get

# 4. Run on emulator
flutter run
```

---

### Architecture: Feature-Based MVVM

```
lib/
│
├── main.dart                                    # Entry point + Provider wiring
│
├── core/                                        # ══ SHARED (all features) ══
│   ├── models/
│   │   ├── user_model.dart                      # UserModel (shared)
│   │   ├── product_model.dart                   # ProductModel (shared)
│   │   ├── production_model.dart                # ProductionModel + ProductionItem
│   │   └── payroll_model.dart                   # PayrollEntry, DeductionModel, DailySalaryResult
│   ├── services/
│   │   ├── database_service.dart                # SQLite CRUD + seed data
│   │   └── payroll_service.dart                 # Salary computation engine
│   ├── widgets/
│   │   └── common_widgets.dart                  # StatCard, RoleBadge, WeekSelector, etc.
│   └── utils/
│       ├── constants.dart                       # AppColors, AppTheme, AppConstants
│       └── helpers.dart                         # formatCurrency, getWeekStart, generateId
│
├── features/
│   │
│   ├── auth/                                    # ══ AUTH FEATURE ══
│   │   ├── view/
│   │   │   └── login_screen.dart                # Role dropdown → email → password
│   │   └── viewmodel/
│   │       └── auth_viewmodel.dart              # Login/logout state
│   │
│   ├── admin/                                   # ══ ADMIN FEATURE ══
│   │   ├── view/
│   │   │   └── screens/
│   │   │       ├── admin_dashboard.dart          # Shell + bottom nav (5 tabs)
│   │   │       ├── admin_home_screen.dart         # Overview stats + quick actions
│   │   │       ├── manage_users_screen.dart       # Add/Edit/Delete users
│   │   │       ├── manage_products_screen.dart    # Add/Edit/Delete products
│   │   │       ├── production_reports_screen.dart  # View all production history
│   │   │       └── payroll_screen.dart            # Weekly payroll + deductions
│   │   └── viewmodel/
│   │       ├── admin_user_viewmodel.dart          # User CRUD (admin-only)
│   │       ├── admin_product_viewmodel.dart       # Product CRUD (admin-only)
│   │       ├── admin_production_viewmodel.dart    # Production reports
│   │       └── admin_payroll_viewmodel.dart       # Payroll computation + deductions
│   │
│   ├── master_baker/                             # ══ MASTER BAKER FEATURE ══
│   │   ├── view/
│   │   │   └── screens/
│   │   │       ├── master_baker_dashboard.dart    # Shell + bottom nav (4 tabs)
│   │   │       ├── baker_home_screen.dart          # Dashboard stats
│   │   │       ├── baker_production_input_screen.dart # Select helpers + add production
│   │   │       ├── baker_history_screen.dart       # Production history
│   │   │       └── baker_salary_screen.dart        # Weekly salary breakdown
│   │   └── viewmodel/
│   │       ├── baker_production_viewmodel.dart     # Production input + history
│   │       └── baker_salary_viewmodel.dart         # Salary computation
│   │
│   └── helper/                                    # ══ HELPER FEATURE ══
│       ├── view/
│       │   └── screens/
│       │       ├── helper_dashboard.dart           # Shell + bottom nav (2 tabs)
│       │       ├── helper_daily_screen.dart         # Daily salary (view-only)
│       │       └── helper_weekly_screen.dart        # Weekly salary + deductions
│       └── viewmodel/
│           └── helper_salary_viewmodel.dart        # Daily + weekly salary data
```

---

### Why Feature-Based MVVM?

| Benefit | Explanation |
|---------|-------------|
| **Separation of Concerns** | Admin, Baker, Helper code never touch each other |
| **Independent Development** | Each feature can be developed/tested alone |
| **Scalability** | Adding a new feature = new folder, no touching old code |
| **Clear Ownership** | Every file belongs to ONE feature |
| **Easier Navigation** | Looking for baker salary? → `features/master_baker/` |
| **Reduced Merge Conflicts** | Team members work in different folders |

vs. the old flat MVVM:
```
# OLD (flat) — everything mixed together
lib/viewmodels/user_viewmodel.dart    ← used by admin AND baker?
lib/views/payroll_screen.dart          ← which role uses this?

# NEW (feature-based) — crystal clear
lib/features/admin/viewmodel/admin_user_viewmodel.dart     ← admin only
lib/features/admin/view/screens/payroll_screen.dart        ← admin only
lib/features/master_baker/viewmodel/baker_salary_viewmodel.dart ← baker only
```

---

### Demo Credentials

| Role         | Email              | Password  |
|--------------|--------------------|-----------|
| Admin        | admin@champs.com   | admin123  |
| Master Baker | jeje@champs.com    | jeje123   |
| Helper       | talyo@champs.com   | pass123   |

---

### Dependencies

```yaml
provider: ^6.1.1      # State management (MVVM)
sqflite: ^2.3.0       # Local SQLite database
path: ^1.8.3          # Path utilities
intl: ^0.19.0         # Date/number formatting
```

---

### Payroll Business Rules

- **Equal split**: `total_production_value ÷ total_workers`
- **Master Baker bonus**: `₱100 × total_sacks_produced`
- **Helper oven deduction**: `₱15 × days_worked` (auto-calculated)
- **Master Baker EXEMPTED** from oven deduction
- **Admin inputs**: Gas, Vale, Wifi deductions per worker per week
- **Weekly payroll**: Auto-sums all daily salaries for the week
