# **Technical Specification (TS) for “Music Library” Web Application**

## **1. General Information**

* **Project Name:** Music Library

* **Project Type:** Full-stack web application (client–server architecture)

* **Goal:**
  Develop an intelligent and user-friendly web application for organizing, uploading, and streaming local FLAC music libraries with real-time metadata extraction, user isolation, and dynamic synchronization.

* **Target Platforms:**
  Desktop and mobile web browsers (responsive design).

* **Technology Stack:**

  * **Backend:** Go (Gin framework)
  * **Frontend:** Vue 3 + TypeScript
  * **Database:** PostgreSQL
  * **Additional Tools:** /flac/meta for metadata extraction, tailwind styles


## **2. Functional Requirements**

### **2.1 Backend (Server-Side)**

**Core Features:**

* Serve RESTful API endpoints for frontend communication.
* Manage persistent database storage for:

  * Users, roles, and authentication tokens
  * Music albums, artists, and songs
  * Upload metadata and user activity history

**Music Upload System:**

* Support drag-and-drop uploads of FLAC files.
* Real-time extraction of:

  * Artist name
  * Album name
  * Track title
  * Duration and year
  * Album cover (base64-encoded, db stored)
* Automatic linking of uploaded songs to users’ private libraries.
* On-the-fly library updates visible in frontend during upload progress.

**Metadata Management:**

* Intelligent processing of song duplicates based on metadata.
* Optional manual editing of incorrect metadata (for admins).
* API for re-parsing metadata using file tags or filename inference.

**Guest Access:**

* Temporary guest users with isolated library spaces.
* Encrypted access links for sharing personal library in guest access.
* Auto-cascade-cleanup of guest data after inactivity.


**API Endpoints (examples):**

| Method | Endpoint            | Description                        |
| ------ | ------------------- | ---------------------------------- |
| `POST` | `/upload`           | Upload FLAC files                  |
| `GET`  | `/library`          | Get user’s music library           |
| `GET`  | `/upload/status`    | Check live parsing progress        |
| `GET`  | `/upload/tree`      | Retrieve tree view of parsed files |
| `POST` | `/api/login`        | Authenticate user                  |
| `POST` | `/api/register`     | Create new user                    |
| `GET`  | `/api/user/profile` | Get profile data                   |

---

### **2.2 Frontend (Client-Side)**

**Main Components:**

* **Library View**

  * Displays albums with cover art, artist name, and release year.
  * Grid layout with dynamic search and filtering.
  * Base64 cover images or fallback default cover.

* **Upload Interface**

  * Drag-and-drop zone for uploading FLAC files.
  * Real-time progress list - Displays and filter artist–title relations as they are parsed
  * ASCII-style tree visualization after parsing completes.
  * Upload popup automatically clears when user closes it.

* **User Interface**

  * Responsive design (desktop/mobile).
  * Theme switching (light/dark).
  * Profile & preferences (SFTP settings, storage path).
  * Constaant styling for Chrome, Firefox based browsers

**Interactivity:**

* Real-time updates via polling or WebSocket connection.
* Automatic library refresh as new files finish processing.
* Smooth animations and transitions for UI updates.

## **3. Advanced Features (Recommended Enhancements)**

* **WebSocket Integration:** Replace polling with event-based live updates for uploads, progress, and metadata tree rendering.
* **API Metadata Correction:** Suggest correct artist or album names by matching metadata with online databases (e.g., MusicBrainz API).
* **Smart Search:** Full-text search and filtering by tags, artist, album, or duration.
* **SFTP / Remote Integration:** Allow connecting to external servers for reading existing music collections.
* **Global Metadata Edit Queue:** Admin moderation system for community-submitted metadata corrections.
* **Offline Mode:** Cache albums and metadata for offline listening using IndexedDB.
* **Audio Player:** Integrated FLAC-capable web player with waveform visualization.
* **Batch Metadata Editor:** Interface for mass renaming and tag editing.


## **4. Non-Functional Requirements**

* **Performance:**

  * Handle up to **100 concurrent uploads** efficiently.
  * Response times under **400 ms** for standard API queries.
  * Stream FLAC with minimal latency via chunked responses.

* **Security:**

  * Password hashing with on client side.
  * Encrypted access tokens (JWT).
  * Input validation and XSS/SQL injection prevention.
  * User data isolation and unique file namespace per user.

* **Scalability:**

  * Modular service-oriented architecture.
  * Ready for horizontal scaling (e.g., containerized deployment via Docker).

* **Maintainability:**

  * Clean, modular Go code with layered structure (`handlers`, `models`, `services`).
  * Frontend organized via Vue components and Pinia state management.

## **5. Deliverables**

* Fully working web application (backend + frontend).
* PostgreSQL database schema with migration scripts.
* Documentation for API routes and deployment.
* Demo dataset with test music library.
* Docker setup for local development and production.

---