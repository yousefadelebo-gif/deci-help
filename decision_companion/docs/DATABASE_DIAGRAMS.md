# Decision Companion - Database Diagrams

## Entity Relationship Diagram (ERD)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    DECISION COMPANION - ERD                                          │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐         ┌──────────────────────┐
│        USER          │         │    USER_SETTINGS     │         │    ACTIVITY_LOG      │
├──────────────────────┤         ├──────────────────────┤         ├──────────────────────┤
│ PK id (UUID)         │◄───┐    │ PK id (UUID)         │         │ PK id (UUID)         │
│    email (unique)    │    │    │ FK user_id ──────────┼────────►│ FK user_id ──────────┼──┐
│    name              │    │    │    theme             │         │    action            │  │
│    password          │    │    │    notifications_    │         │    description       │  │
│    role (USER/ADMIN) │    │    │      enabled         │         │    ip_address        │  │
│    is_guest          │    │    │    email_notif       │         │    user_agent        │  │
│    is_active         │    │    │    push_notif        │         │    metadata (JSON)   │  │
│    is_staff          │    │    │    language          │         │    created_at        │  │
│    created_at        │    │    │    created_at        │         └──────────────────────┘  │
│    updated_at        │    │    │    updated_at        │                                   │
└──────────────────────┘    │    └──────────────────────┘                                   │
          │                 │              1:1                                              │
          │                 └──────────────────────────────────────────────────────────────┘
          │ 1:N
          ▼
┌──────────────────────┐         ┌──────────────────────┐         ┌──────────────────────┐
│      DECISION        │         │   DECISION_OPTION    │         │       RESULT         │
├──────────────────────┤         ├──────────────────────┤         ├──────────────────────┤
│ PK id (UUID)         │◄───┐    │ PK id (UUID)         │◄───┐    │ PK id (UUID)         │
│ FK user_id ──────────┼────┘    │ FK decision_id ──────┼────┘    │ FK decision_id ──────┼──┐
│    title             │◄────────┼─FK chosen_option_id  │         │ FK recommended_      │  │
│    description       │    │    │    name              │◄────────┼─   option_id         │  │
│    status            │    │    │    description       │         │    confidence_level  │  │
│    confidence_level  │    │    │    sort_order        │         │    explanation       │  │
│    satisfaction_     │    │    │    created_at        │         │    scoring_breakdown │  │
│      rating          │    │    │    updated_at        │         │      (JSON)          │  │
│    reflection_notes  │    │    └──────────────────────┘         │    created_at        │  │
│    created_at        │    │              │                      │    updated_at        │  │
│    updated_at        │    │              │ 1:N                  └──────────────────────┘  │
│    analyzed_at       │    │              ▼                               1:1              │
└──────────────────────┘    │    ┌──────────────────────┐                                   │
          │                 │    │    FACTOR_SCORE      │                                   │
          │ 1:N             │    ├──────────────────────┤                                   │
          ▼                 │    │ PK id (UUID)         │                                   │
┌──────────────────────┐    │    │ FK factor_id ────────┼──┐                                │
│       FACTOR         │    │    │ FK option_id ────────┼──┼───────────────────────────────┘
├──────────────────────┤    │    │    score (1-10)      │  │
│ PK id (UUID)         │◄───┼────┤    notes             │  │
│ FK decision_id ──────┼────┘    │    created_at        │  │
│    name              │         │    updated_at        │  │
│    description       │         └──────────────────────┘  │
│    category          │                   │               │
│      (PRO/CON)       │                   │               │
│    weight (1-10)     │                   │               │
│    is_from_template  │         UNIQUE(factor_id,        │
│    template_key      │                option_id)        │
│    sort_order        │                                   │
│    created_at        │                                   │
│    updated_at        │                                   │
└──────────────────────┘                                   │
          │                                                │
          └────────────────────────────────────────────────┘


┌──────────────────────┐         ┌──────────────────────┐
│   FACTOR_TEMPLATE    │         │    AI_PARAMETERS     │
├──────────────────────┤         ├──────────────────────┤
│ PK id (UUID)         │         │ PK id (UUID)         │
│    key (unique)      │         │    key (unique)      │
│    name              │         │    value             │
│    description       │         │    value_type        │
│    default_category  │         │    description       │
│    default_weight    │         │    is_active         │
│    icon              │         │    created_at        │
│    is_active         │         │    updated_at        │
│    sort_order        │         └──────────────────────┘
│    created_at        │
│    updated_at        │
└──────────────────────┘


┌──────────────────────┐
│      FEEDBACK        │
├──────────────────────┤
│ PK id (UUID)         │
│ FK user_id ──────────┼─────► USER
│ FK decision_id ──────┼─────► DECISION (optional)
│    feedback_type     │
│    rating (1-5)      │
│    title             │
│    message           │
│    is_resolved       │
│    admin_response    │
│    created_at        │
│    updated_at        │
└──────────────────────┘
```

---

## Enhanced Entity Relationship Diagram (EERD)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                              DECISION COMPANION - ENHANCED ERD                                       │
│                                  (with Cardinality & Attributes)                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘


                                    ┌─────────────────┐
                                    │   <<abstract>>  │
                                    │   BaseModel     │
                                    ├─────────────────┤
                                    │ + id: UUID [PK] │
                                    │ + created_at    │
                                    │ + updated_at    │
                                    └────────┬────────┘
                                             │
              ┌──────────────────────────────┼──────────────────────────────┐
              │                              │                              │
              ▼                              ▼                              ▼
    ┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
    │      USER       │          │    DECISION     │          │    FEEDBACK     │
    │  <<entity>>     │          │   <<entity>>    │          │   <<entity>>    │
    ├─────────────────┤          ├─────────────────┤          ├─────────────────┤
    │ email: varchar  │          │ title: varchar  │          │ type: enum      │
    │   [unique]      │          │ description:    │          │ rating: int     │
    │ name: varchar   │          │   text          │          │   [1-5]         │
    │ password: hash  │          │ status: enum    │          │ title: varchar  │
    │ role: enum      │◄─────────┤   [DRAFT/       │          │ message: text   │
    │   [USER/ADMIN]  │    1  N  │   ANALYZED/     │◄─────────┤ is_resolved:    │
    │ is_guest: bool  │          │   ARCHIVED]     │    0..1  │   boolean       │
    │ is_active: bool │          │ confidence:     │          │ admin_response: │
    │ is_staff: bool  │          │   float [0-100] │          │   text          │
    └────────┬────────┘          │ satisfaction:   │          └─────────────────┘
             │                   │   int [1-5]     │
             │ 1                 │ reflection:     │
             │                   │   text          │
             ▼                   │ analyzed_at:    │
    ┌─────────────────┐          │   datetime      │
    │  USER_SETTINGS  │          └────────┬────────┘
    │  <<dependent>>  │                   │
    ├─────────────────┤                   │
    │ theme: enum     │          ┌────────┼────────┐
    │   [light/dark/  │          │        │        │
    │    system]      │          │ 1    1 │ N      │ 1
    │ notifications:  │          ▼        ▼        ▼
    │   boolean       │  ┌───────────┐ ┌───────────┐ ┌───────────┐
    │ email_notif:    │  │  RESULT   │ │  OPTION   │ │  FACTOR   │
    │   boolean       │  │<<depend>> │ │<<entity>> │ │<<entity>> │
    │ push_notif:     │  ├───────────┤ ├───────────┤ ├───────────┤
    │   boolean       │  │ recommend │ │ name:     │ │ name:     │
    │ language: enum  │  │   option  │ │   varchar │ │   varchar │
    │   [en/es/fr/    │  │ confidence│ │ descript: │ │ descript: │
    │    de/ar]       │  │   : float │ │   text    │ │   text    │
    └─────────────────┘  │ explanat: │ │ sort_ord: │ │ category: │
                         │   text    │ │   int     │ │   enum    │
                         │ breakdown │ └─────┬─────┘ │   [PRO/   │
                         │   : JSON  │       │       │    CON]   │
                         └───────────┘       │       │ weight:   │
                                             │       │   int     │
                                             │       │   [1-10]  │
                                             │       │ from_tmpl:│
                                             │ N     │   boolean │
                                             │       │ tmpl_key: │
                                             │       │   varchar │
                                             ▼       └─────┬─────┘
                                    ┌─────────────────┐    │
                                    │  FACTOR_SCORE   │    │
                                    │ <<associative>> │◄───┘
                                    ├─────────────────┤    N
                                    │ score: int      │
                                    │   [1-10]        │
                                    │ notes: text     │
                                    └─────────────────┘


    ┌─────────────────┐          ┌─────────────────┐
    │ FACTOR_TEMPLATE │          │  AI_PARAMETERS  │
    │   <<lookup>>    │          │   <<config>>    │
    ├─────────────────┤          ├─────────────────┤
    │ key: varchar    │          │ key: varchar    │
    │   [unique]      │          │   [unique]      │
    │ name: varchar   │          │ value: text     │
    │ description:    │          │ value_type:     │
    │   text          │          │   enum [string/ │
    │ default_cat:    │          │   int/float/    │
    │   enum          │          │   bool/json]    │
    │ default_weight: │          │ description:    │
    │   int [1-10]    │          │   text          │
    │ icon: varchar   │          │ is_active:      │
    │ is_active: bool │          │   boolean       │
    │ sort_order: int │          └─────────────────┘
    └─────────────────┘


    ┌─────────────────┐
    │  ACTIVITY_LOG   │
    │   <<audit>>     │
    ├─────────────────┤
    │ user: FK        │
    │ action: enum    │
    │   [LOGIN/       │
    │    LOGOUT/      │
    │    REGISTER/    │
    │    CREATE_DEC/  │
    │    UPDATE_DEC/  │
    │    DELETE_DEC/  │
    │    AI_ANALYZE/  │
    │    etc.]        │
    │ description:    │
    │   text          │
    │ ip_address:     │
    │   inet          │
    │ user_agent:     │
    │   text          │
    │ metadata: JSON  │
    └─────────────────┘


═══════════════════════════════════════════════════════════════════════════════════════════════════════
                                        RELATIONSHIP SUMMARY
═══════════════════════════════════════════════════════════════════════════════════════════════════════

    RELATIONSHIP                    CARDINALITY         DESCRIPTION
    ─────────────────────────────────────────────────────────────────────────────────────────────────
    User ─────► UserSettings        1:1                 Each user has exactly one settings record
    User ─────► Decision            1:N                 A user can have many decisions
    User ─────► Feedback            1:N                 A user can submit many feedback items
    User ─────► ActivityLog         1:N                 A user generates many activity logs
    
    Decision ─► DecisionOption      1:N                 A decision has many options
    Decision ─► Factor              1:N                 A decision has many factors
    Decision ─► Result              1:1                 A decision has one analysis result
    Decision ◄─ Feedback            N:0..1              Feedback may reference a decision
    Decision ─► DecisionOption      N:0..1              chosen_option (nullable FK)
    
    Factor ────► FactorScore        1:N                 A factor has scores for each option
    Option ────► FactorScore        1:N                 An option has scores for each factor
    
    Result ────► DecisionOption     N:0..1              recommended_option (nullable FK)
    
    FactorTemplate (standalone)     -                   Lookup table for factor templates
    AIParameters (standalone)       -                   Configuration parameters

═══════════════════════════════════════════════════════════════════════════════════════════════════════
```

---

## Database Schema (SQL)

```sql
-- ============================================================
-- DECISION COMPANION DATABASE SCHEMA
-- ============================================================

-- USER TABLE
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL DEFAULT '',
    password VARCHAR(255) NOT NULL,
    role VARCHAR(10) NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
    is_guest BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- USER SETTINGS TABLE
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    theme VARCHAR(10) NOT NULL DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    language VARCHAR(5) NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'es', 'fr', 'de', 'ar')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ACTIVITY LOG TABLE
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT DEFAULT '',
    ip_address INET,
    user_agent TEXT DEFAULT '',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- FACTOR TEMPLATE TABLE
CREATE TABLE factor_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT DEFAULT '',
    default_category VARCHAR(10) NOT NULL DEFAULT 'NEUTRAL' CHECK (default_category IN ('PRO', 'CON', 'NEUTRAL')),
    default_weight INTEGER NOT NULL DEFAULT 5 CHECK (default_weight BETWEEN 1 AND 10),
    icon VARCHAR(50) DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- AI PARAMETERS TABLE
CREATE TABLE ai_parameters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key VARCHAR(50) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    value_type VARCHAR(20) NOT NULL DEFAULT 'string',
    description TEXT DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- DECISION TABLE
CREATE TABLE decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    status VARCHAR(10) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ANALYZED', 'ARCHIVED')),
    chosen_option_id UUID,  -- FK added after decision_options table
    confidence_level FLOAT CHECK (confidence_level BETWEEN 0 AND 100),
    satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
    reflection_notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    analyzed_at TIMESTAMP WITH TIME ZONE
);

-- DECISION OPTION TABLE
CREATE TABLE decision_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id UUID NOT NULL REFERENCES decisions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add FK constraint for chosen_option
ALTER TABLE decisions ADD CONSTRAINT fk_chosen_option 
    FOREIGN KEY (chosen_option_id) REFERENCES decision_options(id) ON DELETE SET NULL;

-- FACTOR TABLE
CREATE TABLE factors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id UUID NOT NULL REFERENCES decisions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    category VARCHAR(5) NOT NULL CHECK (category IN ('PRO', 'CON')),
    weight INTEGER NOT NULL DEFAULT 5 CHECK (weight BETWEEN 1 AND 10),
    is_from_template BOOLEAN NOT NULL DEFAULT FALSE,
    template_key VARCHAR(50) DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- FACTOR SCORE TABLE
CREATE TABLE factor_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    factor_id UUID NOT NULL REFERENCES factors(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES decision_options(id) ON DELETE CASCADE,
    score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 10),
    notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(factor_id, option_id)
);

-- RESULT TABLE
CREATE TABLE results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id UUID UNIQUE NOT NULL REFERENCES decisions(id) ON DELETE CASCADE,
    recommended_option_id UUID REFERENCES decision_options(id) ON DELETE SET NULL,
    confidence_level FLOAT NOT NULL CHECK (confidence_level BETWEEN 0 AND 100),
    explanation TEXT NOT NULL,
    scoring_breakdown JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- FEEDBACK TABLE
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    decision_id UUID REFERENCES decisions(id) ON DELETE SET NULL,
    feedback_type VARCHAR(20) NOT NULL DEFAULT 'GENERAL' CHECK (feedback_type IN ('GENERAL', 'BUG', 'FEATURE', 'DECISION')),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    admin_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_decisions_user ON decisions(user_id);
CREATE INDEX idx_decisions_status ON decisions(status);
CREATE INDEX idx_decisions_created ON decisions(created_at);
CREATE INDEX idx_options_decision ON decision_options(decision_id);
CREATE INDEX idx_factors_decision ON factors(decision_id);
CREATE INDEX idx_factor_scores_factor ON factor_scores(factor_id);
CREATE INDEX idx_factor_scores_option ON factor_scores(option_id);
CREATE INDEX idx_feedback_user ON feedback(user_id);
CREATE INDEX idx_feedback_resolved ON feedback(is_resolved);
CREATE INDEX idx_activity_user ON activity_logs(user_id);
CREATE INDEX idx_activity_action ON activity_logs(action);
CREATE INDEX idx_activity_created ON activity_logs(created_at);
```

---

## Entity Descriptions

### Core Entities

| Entity | Description |
|--------|-------------|
| **User** | System users with authentication and role-based access |
| **UserSettings** | User preferences (theme, notifications, language) |
| **ActivityLog** | Audit trail for user actions |

### Decision Entities

| Entity | Description |
|--------|-------------|
| **Decision** | Main decision record with title, description, status |
| **DecisionOption** | Options/choices within a decision |
| **Factor** | Criteria for evaluating options (PRO or CON) |
| **FactorScore** | Score (1-10) for a factor-option combination |
| **Result** | AI analysis result with recommendation |

### Support Entities

| Entity | Description |
|--------|-------------|
| **FactorTemplate** | Predefined factor templates (admin-managed) |
| **AIParameters** | AI algorithm configuration |
| **Feedback** | User feedback and ratings |
