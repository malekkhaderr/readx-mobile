# Readora — Full Project Context Document

> Use this document to understand the project's concept, architecture, features, and technical details. Ideal for AI agents generating posters, videos, presentations, or documentation.

---

## 1. Project Overview

**Readora** is a full-stack mobile EPUB reading platform that transforms solitary digital reading into an engaging, gamified, and social experience. Built as a graduation project, it combines a feature-rich Flutter mobile app with a robust ASP.NET Core 8 backend, offering a complete end-to-end reading ecosystem.

### The Problem
Digital readers face low consistency, isolation, and lack of motivation. Unlike physical book clubs, mobile reading apps rarely incentivize daily habits or create community around the reading experience.

### The Solution
Readora introduces:
- **Gamification** — streaks, tokens, and reader levels that reward consistent reading
- **Social features** — community quotes, ratings, discussions, and public reader profiles
- **AI assistance** — an in-app intelligent owl assistant that discusses books with readers
- **Author tools** — a self-service dashboard for authors to publish, manage, and track their books

### Target Users
- **Readers** — anyone who wants to build a reading habit with motivation and social connection
- **Authors** — writers who want to self-publish EPUBs and track engagement
- **Administrators** — platform managers who configure settings, moderate content, and manage users

---

## 2. Tech Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart 3.10) | Cross-platform, Clean Architecture, BLoC state management |
| **Backend API** | ASP.NET Core 8 | REST API, 19 controllers, CQRS-style handlers, EF Core |
| **Database** | SQL Server | 30+ entities, 20+ migrations, Code-First approach |
| **AI Service** | Google Gemini 1.5 Flash | Multi-turn chat with book-focused persona |
| **File Storage** | Supabase Storage | EPUB files + book cover images |
| **Hosting** | Render.com | Auto-deploy from GitHub on push to main |
| **Auth** | JWT Bearer + BCrypt | Token blacklisting on logout, role-based access |
| **Email** | MailKit SMTP | OTP verification, password reset, notifications |

---

## 3. Architecture

### Frontend (Flutter)
```
lib/
├── core/          (DI, networking, routing, theme, widgets, services)
├── features/
│   ├── auth/      (login, register, OTP, forgot/reset password)
│   ├── home/      (book feed, book details, ratings, comments)
│   ├── library/   (user's book collection with status management)
│   ├── search/    (real-time search with category filters)
│   ├── quotes/    (community quotes feed + personal quotes)
│   ├── reader/    (EPUB reader + legacy reader + reading sessions)
│   ├── profile/   (reader dashboard, levels, settings)
│   ├── notifications/ (real-time notification system)
│   ├── author_dashboard/ (author books, stats, publisher requests)
│   ├── reports/   (support tickets system)
│   ├── ai_chat/   (AI owl assistant)
│   ├── levels/    (reader progression roadmap)
│   ├── focus_timer/ (Pomodoro-style reading timer)
│   └── shop/      (book purchase with USD/tokens)
```

### Backend (ASP.NET Core 8)
```
├── API/           (Controllers, Middleware, Program.cs)
├── Application/   (Handlers, DTOs, Use Cases per feature)
├── Infrastructure/(Repositories, EF DbContext, Services, Migrations)
├── Domain/        (Entities, Enums, Value Objects)
```

### Data Flow
```
User Action → Flutter UI → BLoC Event → Use Case → Repository → Dio HTTP
    → ASP.NET Controller → Handler → EF Repository → SQL Server
    → Response ← Controller ← Handler ← Repository
    ← Dio Response ← Repository ← Use Case ← BLoC State ← UI Update
```

---

## 4. Complete Feature List

### 4.1 Authentication & Security
- Email/password registration with OTP email verification
- Login with JWT (24-hour expiry, includes role claim)
- Forgot password → OTP → reset flow
- JWT logout blacklist (server-side invalidation)
- 401 interceptor with automatic redirect to login
- Role-based authorization (Reader, Author, Admin)
- Anti-screenshot protection in EPUB reader (Android FLAG_SECURE)

### 4.2 EPUB Reader
- Full EPUB rendering with `epub_view` package
- Automatic page progress tracking (every 30 seconds)
- Delta-based reading time submission (prevents double-counting)
- Token earning: configurable rate (default 10 tokens/hour)
- Streak advancement on daily reading
- Auto-completion detection when last page is reached
- Book status auto-updates ("Currently Reading" on open, "Read" on finish)
- Font size/family/theme customization (ivory, ebony, sepia)
- Text selection with "Save as Quote" action
- Books with incomplete TOC are patched from spine automatically
- Sound effects (page turn, session complete, tokens earned)
- Progress resume on re-open (jumps to last saved paragraph)

### 4.3 Gamification System
- **Tokens**: Earned by reading (rate configurable by admin)
- **Streaks**: Daily reading tracked; broken after 48h of inactivity; streak warning notifications
- **Reader Levels** (5 mythological owl tiers):
  - Level 1: The Glaucus (Novice) — 0-9,999 tokens
  - Level 2: The Moche Guardian (Voyager) — 10,000-49,999
  - Level 3: The Uluka (Scholar) — 50,000-99,999
  - Level 4: Chikap Kamuy (Overseer) — 100,000-249,999
  - Level 5: Prince Stolas (Oracle) — 250,000+
- **Focus Timer**: Pomodoro-style reading sessions with token rewards
- **Level Roadmap**: Visual progression with owl illustrations per level

### 4.4 Social & Community
- **Ratings & Reviews**: 0.5-step star rating + optional text review per book. One review per user. Edit/delete supported.
- **Discussion Comments**: Threaded discussion per book with upvote/downvote voting
- **Community Quotes**: Save highlighted passages from books, vote on others' quotes, filter by book/category/date
- **Public Reader Profiles**: View other readers' stats, level, streak, completed books
- **Notifications**: Real-time system (streak warnings, publisher request approvals, new books) with unread badge counter

### 4.5 Library Management
- Add books to personal library with status: Want to Read / Currently Reading / Read
- Status auto-updates based on reading actions
- Filter by status, pull-to-refresh, paginated
- "Owned" badge on book cards across the app

### 4.6 Search & Discovery
- Real-time search against backend `/api/books/search` (debounced 350ms)
- Category chip filters from `/api/categories`
- Browse mode (no query): shows all books paginated
- Infinite scroll pagination
- Empty/error states for every scenario

### 4.7 Book Purchase System
- Dual pricing: USD and Tokens (feathers)
- `POST /api/books/{id}/buyUSD` and `POST /api/books/{id}/buyTokens`
- Admin-configurable `TokensPerUSD` exchange rate
- EPUB access gated to purchasers (free books open to all)
- Purchase confirmation with library + profile refresh

### 4.8 AI Reading Assistant
- In-app chat with "Hootie" the owl (Google Gemini 1.5 Flash)
- Book-focused persona with reading recommendations
- Markdown rendering in chat bubbles
- Typing indicator animation
- Suggestion chips for quick prompts
- Draggable floating action button (FAB) for quick access

### 4.9 Author Dashboard
- Book performance metrics (views, reads, ratings)
- Publisher request system (submit new book, modify, remove)
- Per-book comments and reviews sheets
- Statistics page with detailed analytics
- Profile page with author-specific info grid

### 4.10 Admin Features
- Platform dashboard (total users, books, pending requests)
- App settings management (TokensPerHour, TokensPerUSD)
- User activation/deactivation
- Report resolution with admin notes
- Reader level CRUD

### 4.11 Support & Reports
- Submit support tickets with predefined reasons or custom text
- View ticket history with status badges (Waiting, InReview, Done, Canceled)
- Admin feedback displayed prominently per ticket

### 4.12 UI/UX Polish
- Light/dark theme with smooth toggle (all pages rebuild cleanly)
- Sound effects throughout (tab clicks, level up, tokens, session complete, etc.)
- Animated owl mascot with 6 moods (happy, reading, celebrating, sad, sleeping, waving)
- Streak fire animation on profile
- Book-opening animation before reader launches
- Daily quote splash screen with 50+ curated quotes
- Shimmer loading placeholders
- Pull-to-refresh on every page
- Empty states with illustrations and CTAs

---

## 5. API Endpoints Summary (19 Controllers, 90+ Endpoints)

| Controller | Key Endpoints |
|-----------|--------------|
| Users | login, register, forgot/reset password, me, profile edit, logout |
| OTP | send, verify (email verification, password reset, email change) |
| Books | CRUD, search, home aggregate, publish/unpublish, buyUSD, buyTokens |
| ReadingSessions | start, progress (delta-based), get session, list sessions |
| BookReviews (Ratings) | upsert rating+text, get paged, get mine, delete |
| BookComments | CRUD with voting (upvote/downvote) |
| Library | add, update status, remove, list with filter |
| Quotes | add, delete, get (community + my), vote |
| Notifications | list, mark-all-read, mark-one-read |
| Categories | CRUD, list with book counts |
| Languages | CRUD, list |
| Reports | submit, get reasons, get my reports, admin review |
| PublisherRequests | submit (new/modify/remove), list, admin review |
| AuthorDashboard | dashboard stats, books, detailed statistics |
| Admin | dashboard, settings, user activation, user sessions |
| ReaderLevels | CRUD, set default |
| Avatars | list active, admin add/update/deactivate |
| AI | chat (multi-turn with Gemini) |
| ReaderProfile | public profile view |

---

## 6. Database Schema Highlights

- **30+ entities** including: User, ReaderProfile, AuthorProfile, Book, Category, Language, ReadingSession, BookReview, BookComment, Quote, QuoteVote, Notification, Report, PublisherRequest, UserFavoriteBook, OtpCode, AppSetting, Avatar, ReaderLevel, ReadingLog, Discount, TokenBlacklist
- **Composite keys**: UserFavoriteBook (ReaderProfileId + BookId)
- **Encapsulated domain logic**: entities expose named methods (e.g. `Book.AddRating()`, `ReaderProfile.AddReadingTime()`, `ReadingSession.UpdateProgress()`)
- **Background jobs**: StreakMonitorService (hourly), DiscountLifecycleService

---

## 7. Deployment & DevOps

- **Backend**: Auto-deploys to Render.com from GitHub `main` branch
- **Database**: SQL Server hosted (connection string in Render env vars)
- **EPUB Storage**: Supabase Storage buckets (public read URLs)
- **Frontend**: APK built via `flutter build apk`, distributed directly
- **CI**: Manual (push to main → Render detects → builds .NET → deploys)

---

## 8. Project Team & Timeline

- **Duration**: ~4 months (design → implementation → polish)
- **Team**: 3 developers (frontend lead, backend lead, full-stack support)
- **Methodology**: Agile sprints, feature branches, code reviews via GitHub PRs

---

## 9. What Makes Readora Special

1. **Complete end-to-end**: Not a prototype — real authentication, real payments, real data persistence, real AI integration
2. **Gamification that works**: The token + streak + level system creates genuine motivation loops
3. **Production-quality code**: Clean Architecture on both sides, proper error handling, 401 interceptors, optimistic UI updates
4. **Accessibility**: Dark mode, adjustable fonts, sound toggles, responsive layouts
5. **AI integration**: Not just a gimmick — contextual book discussions that enhance comprehension
6. **Social layer**: Quotes, ratings, discussions, and profiles make reading communal
7. **Author empowerment**: Self-service publishing pipeline with analytics
8. **Polished UX**: Animations, sound effects, loading states, empty states — feels like a shipped product

---

## 10. Keywords for AI Context

`Flutter`, `Dart`, `ASP.NET Core 8`, `C#`, `Entity Framework Core`, `SQL Server`, `REST API`, `JWT Authentication`, `BLoC Pattern`, `Clean Architecture`, `EPUB Reader`, `Gamification`, `Reading Streaks`, `Token Economy`, `AI Chatbot`, `Google Gemini`, `Supabase`, `Render.com`, `Mobile App`, `Cross-platform`, `Book Platform`, `Social Reading`, `Author Dashboard`, `Admin Panel`, `OTP Verification`, `Real-time Notifications`, `Dark Mode`, `Sound Effects`, `Graduation Project`

---

## 11. Usage Instructions for AI Agents

When using this document to generate content:

- **For a poster**: Focus on Sections 1 (overview), 4 (features list), 3 (architecture diagram), and 9 (differentiators)
- **For a video script**: Use Section 1 (problem/solution), then walk through Section 4 features with screen recordings
- **For a presentation**: Use all sections, emphasizing the architecture (Section 3) and technical highlights
- **For documentation**: Use Sections 5 (API), 6 (database), and 7 (deployment)
- **For a README**: Condense Sections 1, 2, 4, and 7

---

*Generated: 2026-05-31 | Project: Readora (Graduation Project)*
