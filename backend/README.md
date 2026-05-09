# Vision Attendance Backend

Node.js + Express backend that connects:
- **Flutter Mobile App** (Vision Attendance)
- **React Dashboard** (final_project)
- **Python AI** (face_app — YOLOv8 + InsightFace)
- **MySQL Database**

---

## ⚡ Quick Start

### 1. Install dependencies
```bash
cd backend
npm install
```

### 2. Setup Database
```bash
# Create DB and tables
mysql -u root -p < schema.sql
```

### 3. Configure environment
Edit `.env`:
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=vision_attendance
DB_USER=root
DB_PASSWORD=YOUR_PASSWORD

JWT_SECRET=change_this_to_a_long_random_string
JWT_EXPIRES_IN=7d

AI_BASE_URL=http://192.168.1.5:5000
PORT=3001
```

### 4. Make sure face_app Python is running
```bash
cd face_app
python api/app.py   # starts on port 5000
```

### 5. Start the backend
```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

---

## 📁 Folder Structure

```
backend/
├── server.js                  ← Entry point
├── schema.sql                 ← Run once to create MySQL tables
├── .env                       ← Environment variables
├── package.json
└── src/
    ├── app.js                 ← Express setup + all routes mounted
    ├── config/
    │   └── db.js              ← MySQL connection pool
    ├── middleware/
    │   ├── auth.js            ← JWT verify + role guards
    │   ├── upload.js          ← Multer (images → memory buffer)
    │   └── errorHandler.js    ← Global error handler
    ├── routes/
    │   ├── auth.routes.js
    │   ├── users.routes.js
    │   ├── attendance.routes.js
    │   ├── rooms.routes.js
    │   ├── vacations.routes.js
    │   ├── dashboard.routes.js
    │   ├── ai.routes.js
    │   ├── notifications.routes.js
    │   └── settings.routes.js
    └── controllers/
        ├── auth.controller.js
        ├── users.controller.js
        ├── attendance.controller.js
        ├── rooms.controller.js
        ├── vacations.controller.js
        ├── dashboard.controller.js
        ├── ai.controller.js
        ├── notifications.controller.js
        └── settings.controller.js
```

---

## 🔌 Full API Reference

http://192.168.1.5:3001

All protected routes require: `Authorization: Bearer <token>`

---

### 🔐 Auth  `/api/auth`
| Method | Endpoint              | Auth | Who uses it              |
|--------|-----------------------|------|--------------------------|
| POST   | `/login`              | ❌   | Flutter + React Dashboard |
| POST   | `/register`           | ❌   | Flutter (self-register)   |
| GET    | `/me`                 | ✅   | Flutter + React Dashboard |
| PUT    | `/change-password`    | ✅   | Flutter + React Dashboard |

**Login request:**
```json
{ "username": "admin", "password": "admin123" }
```
**Login response:**
```json
{
  "success": true,
  "token": "eyJ...",
  "user": { "id": 1, "role": "admin", "full_name_en": "Administrator", ... }
}
```

---

### 👤 Users  `/api/users`
| Method | Endpoint                       | Auth   | Role    | Who uses it       |
|--------|--------------------------------|--------|---------|-------------------|
| GET    | `/`                            | ✅     | admin   | React Dashboard   |
| GET    | `/:id`                         | ✅     | any     | both              |
| GET    | `/:id/attendance-summary`      | ✅     | any     | Flutter           |
| POST   | `/`                            | ✅     | admin   | React Dashboard   |
| PUT    | `/:id`                         | ✅     | admin   | React Dashboard   |
| DELETE | `/:id`                         | ✅     | admin   | React Dashboard   |

---

### 🤖 AI (face_app proxy)  `/api/ai`
| Method | Endpoint      | Auth | Role  | Who uses it              |
|--------|---------------|------|-------|--------------------------|
| GET    | `/status`     | ❌   | -     | any (health check)       |
| POST   | `/recognize`  | ✅   | any   | Flutter (face check-in)  |
| POST   | `/enroll`     | ✅   | admin | React Dashboard          |
| POST   | `/quality`    | ✅   | any   | Flutter                  |
| POST   | `/liveness`   | ✅   | any   | Flutter                  |

**Face check-in (multipart/form-data):**
```
POST /api/ai/recognize
Content-Type: multipart/form-data

image: <file>
room_id: 1   (optional)
```
**Response:**
```json
{
  "success": true,
  "ai_result": {
    "matched": true,
    "person_id": "user_5",
    "similarity": 0.87,
    "spoof_passed": true,
    "liveness_ok": true,
    "fraud_risk": 0.02
  },
  "attendance": {
    "type": "checkin",
    "id": 42,
    "user": { "full_name_en": "Ahmed Ali", "department": "Engineering" },
    "status": "present"
  }
}
```

---

### 📊 Attendance  `/api/attendance`
| Method | Endpoint     | Auth | Role  | Who uses it     |
|--------|--------------|------|-------|-----------------|
| GET    | `/`          | ✅   | admin | React Dashboard |
| GET    | `/my-logs`   | ✅   | any   | Flutter         |
| GET    | `/today`     | ✅   | any   | Flutter home    |
| DELETE | `/:id`       | ✅   | admin | React Dashboard |

---

### 🏢 Rooms  `/api/rooms`
| Method | Endpoint     | Auth | Role  | Who uses it           |
|--------|--------------|------|-------|-----------------------|
| GET    | `/`          | ✅   | any   | Flutter + Dashboard   |
| GET    | `/:id`       | ✅   | any   | both                  |
| GET    | `/:id/stats` | ✅   | admin | React Dashboard       |
| POST   | `/`          | ✅   | admin | React Dashboard       |
| PUT    | `/:id`       | ✅   | admin | React Dashboard       |
| DELETE | `/:id`       | ✅   | admin | React Dashboard       |

---

### 🏖️ Vacations  `/api/vacations`
| Method | Endpoint          | Auth | Role  | Who uses it     |
|--------|-------------------|------|-------|-----------------|
| GET    | `/`               | ✅   | admin | React Dashboard |
| GET    | `/my-requests`    | ✅   | any   | Flutter         |
| POST   | `/`               | ✅   | any   | Flutter         |
| PUT    | `/:id/review`     | ✅   | admin | React Dashboard |
| DELETE | `/:id`            | ✅   | any   | Flutter         |

---

### 📈 Dashboard  `/api/dashboard`
| Method | Endpoint    | Auth | Role  | Who uses it     |
|--------|-------------|------|-------|-----------------|
| GET    | `/stats`    | ✅   | admin | React Dashboard |
| GET    | `/reports`  | ✅   | admin | React Dashboard |

---

### 🔔 Notifications  `/api/notifications`
| Method | Endpoint      | Auth | Who uses it |
|--------|---------------|------|-------------|
| GET    | `/`           | ✅   | Flutter     |
| PUT    | `/read-all`   | ✅   | Flutter     |
| PUT    | `/:id/read`   | ✅   | Flutter     |

---

### ⚙️ Settings  `/api/settings`
| Method | Endpoint    | Auth | Role  | Who uses it     |
|--------|-------------|------|-------|-----------------|
| GET    | `/`         | ✅   | admin | React Dashboard |
| PUT    | `/`         | ✅   | admin | React Dashboard |
| PUT    | `/profile`  | ✅   | any   | React Dashboard |

---

## 🔗 How Everything Connects

```
Flutter Mobile App
  ↓ POST /api/auth/login
  ↓ GET  /api/attendance/today
  ↓ POST /api/ai/recognize  (sends face image)
  ↓ GET  /api/vacations/my-requests
  ↓ GET  /api/notifications

React Dashboard
  ↓ POST /api/auth/login
  ↓ GET  /api/dashboard/stats
  ↓ POST /api/ai/enroll       (register new face)
  ↓ GET  /api/users
  ↓ GET  /api/rooms
  ↓ PUT  /api/vacations/:id/review

Node.js Backend  (this server)
  ↓ forwards image to face_app
  ↓ saves result to MySQL
  ↓ returns combined response

face_app (Python Flask — port 5000)
  ← receives image from /api/ai/recognize
  → returns { matched, similarity, spoof_passed, liveness_ok, fraud_risk }
```

---

## 🛡️ Default Admin Login
```
username: admin
password: password
```
**Change this immediately after first login!**
