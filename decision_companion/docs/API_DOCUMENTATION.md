# Decision Companion API Documentation

## Overview

**Base URL**: `http://localhost:8000/api/v1/`

**Authentication**: JWT Bearer Token

**Content-Type**: `application/json`

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [User Profile](#2-user-profile)
3. [Decisions](#3-decisions)
4. [Decision Options](#4-decision-options)
5. [Factors](#5-factors)
6. [AI Analysis](#6-ai-analysis)
7. [Journal](#7-journal)
8. [Feedback](#8-feedback)
9. [Admin APIs](#9-admin-apis)
10. [Error Handling](#10-error-handling)

---

## 1. Authentication

### 1.1 Register User

Creates a new user account.

**Endpoint**: `POST /auth/register`

**Authentication**: None

**Request Body**:
```json
{
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "password_confirm": "SecurePassword123!",
    "name": "John Doe"
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "message": "Registration successful",
    "data": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "user@example.com",
            "name": "John Doe",
            "role": "USER",
            "is_guest": false,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    }
}
```

**Error Response** (400 Bad Request):
```json
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Registration failed",
        "details": {
            "email": ["A user with this email already exists."]
        }
    }
}
```

---

### 1.2 Login

Authenticates user and returns JWT tokens.

**Endpoint**: `POST /auth/login`

**Authentication**: None

**Request Body**:
```json
{
    "email": "user@example.com",
    "password": "SecurePassword123!"
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "user@example.com",
            "name": "John Doe",
            "role": "USER",
            "is_guest": false,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    }
}
```

---

### 1.3 Guest Login

Creates a temporary guest account.

**Endpoint**: `POST /auth/guest`

**Authentication**: None

**Request Body**: None

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Guest login successful",
    "data": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
            "id": "550e8400-e29b-41d4-a716-446655440001",
            "email": "guest_abc12345@guest.local",
            "name": "Guest User",
            "role": "USER",
            "is_guest": true,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    }
}
```

---

### 1.4 Get Current User

Returns the authenticated user's information.

**Endpoint**: `GET /auth/me`

**Authentication**: Required

**Headers**:
```
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "user@example.com",
        "name": "John Doe",
        "role": "USER",
        "is_guest": false,
        "created_at": "2025-12-08T10:30:00Z",
        "updated_at": "2025-12-08T10:30:00Z",
        "settings": {
            "id": "660e8400-e29b-41d4-a716-446655440000",
            "theme": "system",
            "notifications_enabled": true,
            "email_notifications": true,
            "push_notifications": true,
            "language": "en",
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    }
}
```

---

### 1.5 Logout

Invalidates the refresh token.

**Endpoint**: `POST /auth/logout`

**Authentication**: Required

**Request Body**:
```json
{
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Logout successful"
}
```

---

### 1.6 Refresh Token

Gets a new access token using refresh token.

**Endpoint**: `POST /auth/token/refresh`

**Authentication**: None

**Request Body**:
```json
{
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response** (200 OK):
```json
{
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 2. User Profile

### 2.1 Get Profile

**Endpoint**: `GET /users/me`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "user@example.com",
        "name": "John Doe",
        "role": "USER",
        "is_guest": false,
        "created_at": "2025-12-08T10:30:00Z",
        "updated_at": "2025-12-08T10:30:00Z",
        "settings": {...}
    }
}
```

---

### 2.2 Update Profile

**Endpoint**: `PUT /users/me`

**Authentication**: Required

**Request Body**:
```json
{
    "name": "John Updated"
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Profile updated successfully",
    "data": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "email": "user@example.com",
        "name": "John Updated",
        ...
    }
}
```

---

### 2.3 Get User Statistics

**Endpoint**: `GET /users/me/stats`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "total_decisions": 15,
        "analyzed_decisions": 10,
        "archived_decisions": 3,
        "draft_decisions": 2,
        "average_satisfaction": 4.2,
        "total_feedback_submitted": 5,
        "member_since": "2025-12-01T10:30:00Z"
    }
}
```

---

### 2.4 Get Settings

**Endpoint**: `GET /users/me/settings`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "id": "660e8400-e29b-41d4-a716-446655440000",
        "theme": "dark",
        "notifications_enabled": true,
        "email_notifications": true,
        "push_notifications": false,
        "language": "en",
        "created_at": "2025-12-08T10:30:00Z",
        "updated_at": "2025-12-08T10:30:00Z"
    }
}
```

---

### 2.5 Update Settings

**Endpoint**: `PUT /users/me/settings`

**Authentication**: Required

**Request Body**:
```json
{
    "theme": "dark",
    "language": "en",
    "notifications_enabled": true,
    "email_notifications": true,
    "push_notifications": false
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Settings updated successfully",
    "data": {...}
}
```

---

## 3. Decisions

### 3.1 List Decisions

**Endpoint**: `GET /decisions`

**Authentication**: Required

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| status | string | Filter by status: DRAFT, ANALYZED, ARCHIVED |
| page | integer | Page number for pagination |

**Response** (200 OK):
```json
{
    "success": true,
    "data": [
        {
            "id": "770e8400-e29b-41d4-a716-446655440000",
            "title": "Which laptop to buy?",
            "description": "Deciding between different laptops",
            "status": "DRAFT",
            "confidence_level": null,
            "satisfaction_rating": null,
            "options_count": 3,
            "factors_count": 5,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z",
            "analyzed_at": null
        }
    ]
}
```

---

### 3.2 Create Decision

**Endpoint**: `POST /decisions`

**Authentication**: Required

**Request Body**:
```json
{
    "title": "Which laptop to buy?",
    "description": "I need to decide between MacBook Pro and Dell XPS",
    "options": [
        {
            "name": "MacBook Pro M3",
            "description": "Apple's latest laptop with M3 chip"
        },
        {
            "name": "Dell XPS 15",
            "description": "High-end Windows laptop"
        },
        {
            "name": "ThinkPad X1 Carbon",
            "description": "Business-focused laptop"
        }
    ]
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "message": "Decision created successfully",
    "data": {
        "id": "770e8400-e29b-41d4-a716-446655440000",
        "title": "Which laptop to buy?",
        "description": "I need to decide between MacBook Pro and Dell XPS",
        "status": "DRAFT",
        "chosen_option": null,
        "chosen_option_name": null,
        "confidence_level": null,
        "satisfaction_rating": null,
        "reflection_notes": "",
        "options": [
            {
                "id": "880e8400-e29b-41d4-a716-446655440000",
                "name": "MacBook Pro M3",
                "description": "Apple's latest laptop with M3 chip",
                "sort_order": 0,
                "factor_scores": [],
                "total_score": null,
                "created_at": "2025-12-08T10:30:00Z",
                "updated_at": "2025-12-08T10:30:00Z"
            },
            ...
        ],
        "factors": [],
        "result": null,
        "created_at": "2025-12-08T10:30:00Z",
        "updated_at": "2025-12-08T10:30:00Z",
        "analyzed_at": null
    }
}
```

---

### 3.3 Get Decision

**Endpoint**: `GET /decisions/{id}`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "id": "770e8400-e29b-41d4-a716-446655440000",
        "title": "Which laptop to buy?",
        "description": "...",
        "status": "ANALYZED",
        "chosen_option": "880e8400-e29b-41d4-a716-446655440000",
        "chosen_option_name": "MacBook Pro M3",
        "confidence_level": 78.5,
        "satisfaction_rating": 4,
        "reflection_notes": "Great choice!",
        "options": [...],
        "factors": [...],
        "result": {
            "id": "990e8400-e29b-41d4-a716-446655440000",
            "recommended_option": "880e8400-e29b-41d4-a716-446655440000",
            "recommended_option_name": "MacBook Pro M3",
            "confidence_level": 78.5,
            "explanation": "Based on weighted analysis...",
            "scoring_breakdown": {...}
        },
        "created_at": "2025-12-08T10:30:00Z",
        "updated_at": "2025-12-08T12:30:00Z",
        "analyzed_at": "2025-12-08T11:30:00Z"
    }
}
```

---

### 3.4 Update Decision

**Endpoint**: `PUT /decisions/{id}`

**Authentication**: Required

**Request Body**:
```json
{
    "title": "Which laptop to buy? (Updated)",
    "description": "Updated description",
    "status": "ARCHIVED",
    "satisfaction_rating": 5,
    "reflection_notes": "Very happy with this decision!"
}
```

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Decision updated successfully",
    "data": {...}
}
```

---

### 3.5 Delete Decision

**Endpoint**: `DELETE /decisions/{id}`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Decision deleted successfully"
}
```

---

## 4. Decision Options

### 4.1 List Options

**Endpoint**: `GET /decisions/{id}/options`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": [
        {
            "id": "880e8400-e29b-41d4-a716-446655440000",
            "name": "MacBook Pro M3",
            "description": "Apple's latest laptop",
            "sort_order": 0,
            "factor_scores": [
                {
                    "id": "aa0e8400-e29b-41d4-a716-446655440000",
                    "factor": "bb0e8400-e29b-41d4-a716-446655440000",
                    "factor_name": "Price",
                    "option": "880e8400-e29b-41d4-a716-446655440000",
                    "option_name": "MacBook Pro M3",
                    "score": 6,
                    "notes": "Expensive but worth it"
                }
            ],
            "total_score": 7.5,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    ]
}
```

---

### 4.2 Create Option

**Endpoint**: `POST /decisions/{id}/options`

**Authentication**: Required

**Request Body**:
```json
{
    "name": "New Option",
    "description": "A new option for the decision",
    "sort_order": 3
}
```

**Response** (201 Created):
```json
{
    "success": true,
    "message": "Option created successfully",
    "data": {...}
}
```

---

### 4.3 Update Option

**Endpoint**: `PUT /decisions/{id}/options/{optionId}`

**Authentication**: Required

**Request Body**:
```json
{
    "name": "Updated Option Name",
    "description": "Updated description"
}
```

---

### 4.4 Delete Option

**Endpoint**: `DELETE /decisions/{id}/options/{optionId}`

**Authentication**: Required

---

## 5. Factors

### 5.1 List Factors

**Endpoint**: `GET /decisions/{id}/factors`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": [
        {
            "id": "bb0e8400-e29b-41d4-a716-446655440000",
            "decision": "770e8400-e29b-41d4-a716-446655440000",
            "name": "Price",
            "description": "The cost of the option",
            "category": "CON",
            "weight": 8,
            "is_from_template": true,
            "template_key": "COST",
            "sort_order": 0,
            "scores": [
                {
                    "id": "aa0e8400-e29b-41d4-a716-446655440000",
                    "factor": "bb0e8400-e29b-41d4-a716-446655440000",
                    "factor_name": "Price",
                    "option": "880e8400-e29b-41d4-a716-446655440000",
                    "option_name": "MacBook Pro M3",
                    "score": 6,
                    "notes": ""
                }
            ],
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    ]
}
```

---

### 5.2 Create Factor

**Endpoint**: `POST /decisions/{id}/factors`

**Authentication**: Required

**Request Body**:
```json
{
    "name": "Build Quality",
    "description": "How well the laptop is built",
    "category": "PRO",
    "weight": 7
}
```

**Validation**:
- `category`: Must be "PRO" or "CON"
- `weight`: Must be 1-10

---

### 5.3 Create Factor from Template

**Endpoint**: `POST /decisions/{id}/factors/from-template`

**Authentication**: Required

**Request Body**:
```json
{
    "template_key": "QUALITY",
    "category": "PRO",
    "weight": 9
}
```

**Note**: `category` and `weight` are optional. If not provided, defaults from template are used.

---

### 5.4 Update Factor

**Endpoint**: `PUT /decisions/{id}/factors/{factorId}`

**Authentication**: Required

**Request Body**:
```json
{
    "name": "Updated Factor Name",
    "weight": 8,
    "category": "PRO"
}
```

---

### 5.5 Delete Factor

**Endpoint**: `DELETE /decisions/{id}/factors/{factorId}`

**Authentication**: Required

---

### 5.6 Update Factor Scores

**Endpoint**: `POST /decisions/{id}/factors/{factorId}/scores`

**Authentication**: Required

**Request Body**:
```json
{
    "scores": [
        {
            "option_id": "880e8400-e29b-41d4-a716-446655440000",
            "score": 8,
            "notes": "Good value for money"
        },
        {
            "option_id": "880e8400-e29b-41d4-a716-446655440001",
            "score": 6,
            "notes": "A bit expensive"
        }
    ]
}
```

**Validation**:
- `score`: Must be 1-10

---

## 6. AI Analysis

### 6.1 Get AI Suggestions

Returns suggested factors based on templates.

**Endpoint**: `POST /decisions/{id}/ai/suggestions`

**Authentication**: Required

**Request Body**: None

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "suggested_factors": [
            {
                "key": "COST",
                "name": "Cost",
                "description": "Financial cost or price of the option",
                "category": "CON",
                "weight": 7,
                "icon": "money",
                "from_template": true
            },
            {
                "key": "QUALITY",
                "name": "Quality",
                "description": "Overall quality and reliability",
                "category": "PRO",
                "weight": 8,
                "icon": "star",
                "from_template": true
            }
        ],
        "decision_id": "770e8400-e29b-41d4-a716-446655440000",
        "message": "Found 6 suggested factors for your decision."
    }
}
```

---

### 6.2 Run AI Analysis

Analyzes the decision and generates recommendation.

**Endpoint**: `POST /decisions/{id}/ai/analyze`

**Authentication**: Required

**Request Body**: None

**Prerequisites**:
- Decision must have at least 1 option
- Decision must have at least 1 factor

**Response** (200 OK):
```json
{
    "success": true,
    "message": "Analysis completed successfully",
    "data": {
        "decision_id": "770e8400-e29b-41d4-a716-446655440000",
        "recommended_option": {
            "id": "880e8400-e29b-41d4-a716-446655440000",
            "name": "MacBook Pro M3",
            "score": 85.5
        },
        "confidence_level": 78.5,
        "explanation": "Based on the weighted analysis of all factors, 'MacBook Pro M3' is recommended with a score of 85.5/100. Key strengths include: Quality, Long-term Benefit, Satisfaction. Consider these concerns: Cost, Time Required. This recommendation has high confidence based on clear score differentiation.",
        "scoring_breakdown": {
            "options": [
                {
                    "option_id": "880e8400-e29b-41d4-a716-446655440000",
                    "option_name": "MacBook Pro M3",
                    "raw_score": 125,
                    "normalized_score": 85.5,
                    "factors": [
                        {
                            "factor_id": "bb0e8400-e29b-41d4-a716-446655440000",
                            "name": "Quality",
                            "category": "PRO",
                            "score": 9,
                            "weight": 8,
                            "weighted": 72
                        }
                    ]
                }
            ],
            "analysis_method": "weighted_average",
            "metadata": {
                "total_factors": 5,
                "total_options": 3,
                "pro_factors": 3,
                "con_factors": 2,
                "analyzed_at": "2025-12-08T11:30:00Z"
            }
        }
    }
}
```

---

### 6.3 Get Decision Result

**Endpoint**: `GET /decisions/{id}/result`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "id": "990e8400-e29b-41d4-a716-446655440000",
        "decision": "770e8400-e29b-41d4-a716-446655440000",
        "recommended_option": "880e8400-e29b-41d4-a716-446655440000",
        "recommended_option_name": "MacBook Pro M3",
        "confidence_level": 78.5,
        "explanation": "Based on weighted analysis...",
        "scoring_breakdown": {...},
        "created_at": "2025-12-08T11:30:00Z",
        "updated_at": "2025-12-08T11:30:00Z"
    }
}
```

**Error Response** (404 Not Found):
```json
{
    "success": false,
    "error": {
        "code": "NOT_FOUND",
        "message": "No analysis result found. Run AI analysis first."
    }
}
```

---

## 7. Journal

### 7.1 List Journal Entries

Returns analyzed/archived decisions with journal information.

**Endpoint**: `GET /journal`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": [
        {
            "id": "770e8400-e29b-41d4-a716-446655440000",
            "title": "Which laptop to buy?",
            "description": "...",
            "status": "ANALYZED",
            "chosen_option": "880e8400-e29b-41d4-a716-446655440000",
            "chosen_option_name": "MacBook Pro M3",
            "confidence_level": 78.5,
            "satisfaction_rating": 4,
            "reflection_notes": "Great choice! Very happy with the MacBook.",
            "created_at": "2025-12-08T10:30:00Z",
            "analyzed_at": "2025-12-08T11:30:00Z"
        }
    ]
}
```

---

### 7.2 Update Journal Entry

**Endpoint**: `PATCH /decisions/{id}/journal`

**Authentication**: Required

**Request Body**:
```json
{
    "satisfaction_rating": 5,
    "reflection_notes": "I'm very happy with this decision. The MacBook Pro exceeded my expectations."
}
```

**Validation**:
- `satisfaction_rating`: 1-5

---

## 8. Feedback

### 8.1 Submit Feedback

**Endpoint**: `POST /feedback`

**Authentication**: Required

**Request Body**:
```json
{
    "feedback_type": "GENERAL",
    "rating": 5,
    "title": "Great app!",
    "message": "This app has helped me make better decisions.",
    "decision": "770e8400-e29b-41d4-a716-446655440000"
}
```

**Feedback Types**: `GENERAL`, `BUG`, `FEATURE`, `DECISION`

**Validation**:
- `rating`: 1-5
- `decision`: Optional, link to specific decision

---

### 8.2 Get My Feedback

**Endpoint**: `GET /feedback/my`

**Authentication**: Required

**Response** (200 OK):
```json
{
    "success": true,
    "data": [
        {
            "id": "cc0e8400-e29b-41d4-a716-446655440000",
            "user": "550e8400-e29b-41d4-a716-446655440000",
            "user_email": "user@example.com",
            "user_name": "John Doe",
            "feedback_type": "GENERAL",
            "rating": 5,
            "title": "Great app!",
            "message": "This app has helped me make better decisions.",
            "decision": "770e8400-e29b-41d4-a716-446655440000",
            "decision_title": "Which laptop to buy?",
            "is_resolved": false,
            "admin_response": null,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z"
        }
    ]
}
```

---

## 9. Admin APIs

**Note**: All admin endpoints require `ADMIN` role.

### 9.1 List Users

**Endpoint**: `GET /admin/users`

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| role | string | Filter by role: USER, ADMIN |
| is_guest | boolean | Filter guest users |
| is_active | boolean | Filter active users |

**Response** (200 OK):
```json
{
    "success": true,
    "data": [
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "email": "user@example.com",
            "name": "John Doe",
            "role": "USER",
            "is_guest": false,
            "is_active": true,
            "is_staff": false,
            "decisions_count": 15,
            "created_at": "2025-12-08T10:30:00Z",
            "updated_at": "2025-12-08T10:30:00Z",
            "last_login": "2025-12-08T12:30:00Z"
        }
    ]
}
```

---

### 9.2 Get User Details

**Endpoint**: `GET /admin/users/{id}`

---

### 9.3 Usage Analytics

**Endpoint**: `GET /admin/analytics/usage`

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "total_users": 150,
        "active_users": 120,
        "guest_users": 30,
        "total_decisions": 500,
        "decisions_by_status": {
            "DRAFT": 100,
            "ANALYZED": 350,
            "ARCHIVED": 50
        },
        "total_analyses": 350,
        "average_confidence": 72.5,
        "decisions_this_week": 45,
        "decisions_this_month": 180,
        "most_active_users": [
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "power@user.com",
                "name": "Power User",
                "decision_count": 50
            }
        ]
    }
}
```

---

### 9.4 Feedback Analytics

**Endpoint**: `GET /admin/analytics/feedback`

**Response** (200 OK):
```json
{
    "success": true,
    "data": {
        "total_feedback": 100,
        "resolved_feedback": 80,
        "pending_feedback": 20,
        "average_rating": 4.2,
        "feedback_by_type": {
            "GENERAL": 50,
            "BUG": 20,
            "FEATURE": 25,
            "DECISION": 5
        },
        "rating_distribution": {
            "1": 5,
            "2": 10,
            "3": 15,
            "4": 30,
            "5": 40
        },
        "recent_feedback": [...]
    }
}
```

---

### 9.5 Factor Templates CRUD

**List**: `GET /admin/factor-templates`

**Create**: `POST /admin/factor-templates`
```json
{
    "key": "SUSTAINABILITY",
    "name": "Sustainability",
    "description": "Environmental impact",
    "default_category": "PRO",
    "default_weight": 6,
    "icon": "eco",
    "sort_order": 11
}
```

**Update**: `PUT /admin/factor-templates/{id}`

**Delete**: `DELETE /admin/factor-templates/{id}`

---

### 9.6 AI Parameters

**List**: `GET /admin/ai-parameters`

**Get**: `GET /admin/ai-parameters/{key}`

**Update**: `PATCH /admin/ai-parameters/{key}`
```json
{
    "value": "35",
    "description": "Updated minimum confidence threshold"
}
```

---

### 9.7 Activity Logs

**Endpoint**: `GET /admin/logs`

**Query Parameters**:
| Parameter | Type | Description |
|-----------|------|-------------|
| action | string | Filter by action type |
| user_id | uuid | Filter by user |
| date_from | datetime | Start date |
| date_to | datetime | End date |

---

## 10. Error Handling

### Standard Error Response

```json
{
    "success": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "Human readable message",
        "details": {
            "field_name": ["Error description"]
        }
    }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| BAD_REQUEST | 400 | Invalid request data |
| UNAUTHORIZED | 401 | Authentication required |
| FORBIDDEN | 403 | Permission denied |
| NOT_FOUND | 404 | Resource not found |
| VALIDATION_ERROR | 400 | Input validation failed |
| CONFLICT | 409 | Resource conflict |
| TOO_MANY_REQUESTS | 429 | Rate limit exceeded |
| INTERNAL_SERVER_ERROR | 500 | Server error |

---

## Rate Limiting

- Anonymous: 100 requests/day
- Authenticated: 1000 requests/day

---

## Pagination

Paginated responses include:

```json
{
    "count": 100,
    "next": "http://localhost:8000/api/v1/decisions?page=2",
    "previous": null,
    "results": [...]
}
```

Default page size: 20 items
