# Decision Companion - Django Backend

A full-featured Django REST API backend for the Decision Companion mobile app.

## Features

- 🔐 **JWT Authentication** - Secure token-based authentication
- 🧠 **AI-Powered Analysis** - OpenAI GPT-4 integration for decision recommendations
- 📊 **Decision Management** - Full CRUD for decisions, options, factors, and ratings
- 📝 **Journal Entries** - Reflect on decisions after making them
- 💬 **Feedback System** - User feedback, app ratings, and AI feedback
- 🏷️ **Factor Templates** - Pre-built and custom decision factors
- 📈 **Analytics** - Decision statistics and insights
- 🔧 **Admin Panel** - Full Django admin interface

## Tech Stack

- Django 4.2+
- Django REST Framework
- Simple JWT for authentication
- OpenAI API (GPT-4)
- SQLite (dev) / PostgreSQL (production)
- Django CORS Headers
- drf-yasg (Swagger docs)

## Quick Start

### 1. Create Virtual Environment

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Environment Setup

Copy `.env.example` to `.env` and update values:

```bash
cp .env.example .env
```

Key settings:
- `SECRET_KEY` - Django secret key
- `OPENAI_API_KEY` - Your OpenAI API key (required for AI features)

### 4. Run Migrations

```bash
python manage.py migrate
```

### 5. Seed Admin + Demo Data

```bash
python manage.py seed_demo_data
```

This creates:
- **Admin:** `admin@decehelp.com` / `Admin123!` (Django admin + Swagger API admin)
- **30 demo users:** `demo1@decehelp.test` … / `Demo123!`
- Factor templates, decisions, journals, and feedback

Options: `--users 50 --decisions-per-user 8 --flush`

### 6. Create Superuser (optional manual alternative)

```bash
python manage.py createsuperuser
```

### 7. Run Server

```bash
python manage.py runserver
```

The API will be available at `http://127.0.0.1:8000/api/v1/`

## API Endpoints

### Authentication (`/api/v1/auth/`)
- `POST /register/` - Register new user
- `POST /login/` - Login and get tokens
- `POST /logout/` - Logout (blacklist token)
- `GET/PATCH /profile/` - User profile
- `POST /change-password/` - Change password
- `POST /token/refresh/` - Refresh access token

### Decisions (`/api/v1/decisions/`)
- `GET/POST /` - List/Create decisions
- `GET/PUT/DELETE /{id}/` - Decision detail
- `GET/POST /{id}/options/` - Decision options
- `GET/POST /{id}/factors/` - Decision factors
- `POST /{id}/ratings/` - Save factor ratings
- `POST /{id}/choose/` - Choose final option
- `GET/POST /{id}/journal/` - Journal entry
- `GET /analytics/` - User decision stats
- `GET /recent/` - Recent decisions

### Factors (`/api/v1/factors/`)
- `GET /categories/` - Factor categories
- `GET /templates/` - Factor templates
- `GET /suggested/` - AI-suggested factors
- `GET /popular/` - Popular factors
- `GET/POST /custom/` - User custom factors

### AI Service (`/api/v1/ai/`)
- `GET /status/` - AI availability
- `POST /analyze/{id}/` - Full AI analysis
- `POST /quick-analyze/` - Quick analysis (no save)
- `POST /suggest-factors/{id}/` - Suggest factors
- `POST /generate-pros-cons/{id}/{option_id}/` - Generate pros/cons
- `GET /insights/{id}/` - Get decision insights

### Feedback (`/api/v1/feedback/`)
- `GET/POST /` - User feedback
- `POST /rating/` - App rating
- `POST /ai/decision/{id}/` - AI feedback

## API Documentation

- Swagger UI: `http://127.0.0.1:8000/swagger/`
  1. `POST /api/v1/auth/login/` with admin credentials
  2. Click **Authorize** → enter `Bearer <access_token>`
  3. Call admin endpoints like `/api/v1/auth/admin/stats/`
- ReDoc: `http://127.0.0.1:8000/redoc/`

## Project Structure

```
backend/
├── config/                 # Django project settings
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── accounts/          # User authentication
│   ├── decisions/         # Decision management
│   ├── factors/           # Factor templates
│   ├── feedback/          # User feedback
│   └── ai_service/        # OpenAI integration
├── seeds/                 # Seed data scripts
├── manage.py
├── requirements.txt
└── .env.example
```

## Models

### User
- Custom user model with email authentication
- User settings (theme, notifications, etc.)

### Decision
- Title, description, category, status
- AI recommendation, confidence, explanation
- Chosen option, deadline

### DecisionOption
- Name, description
- Pros/cons lists
- AI score

### DecisionFactor
- Name, weight (0-1)
- Factor template reference

### FactorRating
- Factor + Option combination
- Score (1-10)

### JournalEntry
- Post-decision reflection
- Satisfaction rating, lessons learned

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SECRET_KEY | Django secret key | (insecure default) |
| DEBUG | Debug mode | True |
| ALLOWED_HOSTS | Allowed hosts | localhost,127.0.0.1,10.0.2.2 |
| DB_ENGINE | Database engine | sqlite3 |
| DB_NAME | Database name | db.sqlite3 |
| OPENAI_API_KEY | OpenAI API key | (none) |
| OPENAI_MODEL | OpenAI model | gpt-4o-mini |
| OPENROUTER_API_KEY | OpenRouter API key | (none) |
| OPENROUTER_MODEL | OpenRouter model | openai/gpt-4o-mini |
| OPENROUTER_BASE_URL | OpenRouter base URL | https://openrouter.ai/api/v1 |

## Production Deployment

1. Set `DEBUG=False`
2. Generate strong `SECRET_KEY`
3. Configure PostgreSQL database
4. Set up proper `ALLOWED_HOSTS`
5. Configure HTTPS
6. Use gunicorn/uvicorn with nginx
7. Set up static file serving

## License

MIT License
