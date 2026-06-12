# Decision Companion - AI Decision Making System

A Django REST Framework backend for an AI-powered decision making application.

## Features

- **Authentication**: JWT-based authentication with user registration, login, guest login, and logout
- **Decision Management**: Create, update, delete decisions with options and factors
- **Factor System**: PRO/CON factors with weights, templates, and scoring
- **AI Analysis**: Weighted scoring algorithm with confidence levels and recommendations
- **Journal**: Track analyzed decisions with satisfaction ratings and reflection notes
- **Feedback**: User feedback system with ratings and admin analytics
- **Admin APIs**: User management, analytics, factor templates, and AI parameters

## Tech Stack

- Django 5+
- Django REST Framework
- SimpleJWT for authentication
- CORS support for Flutter mobile app
- SQLite (development) / PostgreSQL (production)

## Project Structure

```
decision_companion/
├── apps/
│   ├── core/              # User management & authentication
│   │   ├── models.py      # User, UserSettings, ActivityLog
│   │   ├── serializers.py # Auth & profile serializers
│   │   ├── views.py       # Auth & profile views
│   │   ├── urls.py        # Auth & profile routes
│   │   └── admin.py       # Admin configuration
│   │
│   ├── decisions/         # Decision management
│   │   ├── models.py      # Decision, Option, Factor, Result
│   │   ├── serializers.py # Decision serializers
│   │   ├── views.py       # Decision viewsets
│   │   ├── services.py    # AI analysis logic
│   │   └── urls.py        # Decision routes
│   │
│   ├── feedback/          # User feedback
│   │   ├── models.py      # Feedback model
│   │   ├── views.py       # Feedback views
│   │   └── urls.py        # Feedback routes
│   │
│   └── admin_panel/       # Admin-specific APIs
│       ├── views.py       # Admin analytics & management
│       └── urls.py        # Admin routes
│
├── decision_companion/    # Django project settings
│   ├── settings.py        # Configuration
│   ├── urls.py            # Root URL configuration
│   └── wsgi.py            # WSGI application
│
├── manage.py
├── requirements.txt
└── postman_collection.json
```

## Quick Start

### 1. Install Dependencies

```bash
cd decision_companion
pip install -r requirements.txt
```

### 2. Run Migrations

```bash
python manage.py migrate
```

### 3. Seed Initial Data (Optional)

```bash
python manage.py seed_data
```

This creates:
- Admin user: `admin@example.com` / `admin123`
- Default factor templates
- Default AI parameters

### 4. Run Development Server

```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000/api/v1/`

### 5. Access Django Admin

Visit `http://localhost:8000/admin/` and login with admin credentials.

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login user |
| POST | `/api/v1/auth/guest` | Guest login |
| GET | `/api/v1/auth/me` | Get current user |
| POST | `/api/v1/auth/logout` | Logout (blacklist token) |
| POST | `/api/v1/auth/token/refresh` | Refresh access token |

### User Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/me` | Get profile |
| PUT | `/api/v1/users/me` | Update profile |
| GET | `/api/v1/users/me/stats` | Get user statistics |
| GET | `/api/v1/users/me/settings` | Get settings |
| PUT | `/api/v1/users/me/settings` | Update settings |

### Decisions
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/decisions` | List decisions |
| POST | `/api/v1/decisions` | Create decision |
| GET | `/api/v1/decisions/{id}` | Get decision |
| PUT | `/api/v1/decisions/{id}` | Update decision |
| DELETE | `/api/v1/decisions/{id}` | Delete decision |

### Options (Nested)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/decisions/{id}/options` | List options |
| POST | `/api/v1/decisions/{id}/options` | Create option |
| PUT | `/api/v1/decisions/{id}/options/{optionId}` | Update option |
| DELETE | `/api/v1/decisions/{id}/options/{optionId}` | Delete option |

### Factors
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/decisions/{id}/factors` | List factors |
| POST | `/api/v1/decisions/{id}/factors` | Create factor |
| POST | `/api/v1/decisions/{id}/factors/from-template` | Create from template |
| PUT | `/api/v1/decisions/{id}/factors/{factorId}` | Update factor |
| DELETE | `/api/v1/decisions/{id}/factors/{factorId}` | Delete factor |
| POST | `/api/v1/decisions/{id}/factors/{factorId}/scores` | Update scores |

### AI Analysis
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/decisions/{id}/ai/suggestions` | Get AI suggestions |
| POST | `/api/v1/decisions/{id}/ai/analyze` | Run analysis |
| GET | `/api/v1/decisions/{id}/result` | Get result |

### Journal
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/journal` | List journal entries |
| PATCH | `/api/v1/decisions/{id}/journal` | Update journal |

### Feedback
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/feedback` | Submit feedback |
| GET | `/api/v1/feedback/my` | Get my feedback |

### Admin (Requires ADMIN role)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/users` | List users |
| GET | `/api/v1/admin/users/{id}` | Get user details |
| GET | `/api/v1/admin/analytics/usage` | Usage analytics |
| GET | `/api/v1/admin/analytics/feedback` | Feedback analytics |
| GET/POST | `/api/v1/admin/factor-templates` | Factor templates |
| PUT/DELETE | `/api/v1/admin/factor-templates/{id}` | Manage templates |
| GET | `/api/v1/admin/ai-parameters` | List AI parameters |
| PATCH | `/api/v1/admin/ai-parameters/{key}` | Update parameter |
| GET | `/api/v1/admin/logs` | Activity logs |

## Example API Usage

### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "password_confirm": "SecurePassword123!",
    "name": "John Doe"
}
```

Response:
```json
{
    "success": true,
    "message": "Registration successful",
    "data": {
        "access_token": "eyJ...",
        "refresh_token": "eyJ...",
        "user": {
            "id": "uuid",
            "email": "user@example.com",
            "name": "John Doe",
            "role": "USER"
        }
    }
}
```

### Create Decision with Options
```http
POST /api/v1/decisions
Authorization: Bearer {access_token}
Content-Type: application/json

{
    "title": "Which laptop to buy?",
    "description": "Deciding between laptops",
    "options": [
        {"name": "MacBook Pro", "description": "Apple laptop"},
        {"name": "Dell XPS", "description": "Windows laptop"}
    ]
}
```

### Add Factor and Score
```http
POST /api/v1/decisions/{id}/factors
Content-Type: application/json

{
    "name": "Price",
    "category": "CON",
    "weight": 8
}
```

```http
POST /api/v1/decisions/{id}/factors/{factorId}/scores
Content-Type: application/json

{
    "scores": [
        {"option_id": "uuid1", "score": 4},
        {"option_id": "uuid2", "score": 8}
    ]
}
```

### Run AI Analysis
```http
POST /api/v1/decisions/{id}/ai/analyze
Authorization: Bearer {access_token}
```

Response:
```json
{
    "success": true,
    "data": {
        "decision_id": "uuid",
        "recommended_option": {
            "id": "uuid",
            "name": "Dell XPS",
            "score": 85.5
        },
        "confidence_level": 72.3,
        "explanation": "Based on weighted analysis...",
        "scoring_breakdown": {...}
    }
}
```

## PostgreSQL Configuration (Production)

Update `settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'decision_companion'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'password'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SECRET_KEY | Django secret key | (dev key) |
| DEBUG | Debug mode | True |
| ALLOWED_HOSTS | Allowed hosts | * |
| DB_NAME | Database name | decision_companion |
| DB_USER | Database user | postgres |
| DB_PASSWORD | Database password | - |
| DB_HOST | Database host | localhost |
| DB_PORT | Database port | 5432 |

## Postman Collection

Import `postman_collection.json` into Postman to test all API endpoints.

The collection includes:
- Auto-saving of tokens after login
- Pre-configured variables for IDs
- All endpoint examples with sample data

## License

MIT License
