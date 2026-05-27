# Readora / ReadX — Graduation Project Plan

**Author:** Huthifa
**Date created:** 2026-05-25
**Deadline:** 3–4 days from today
**Goal:** Ship a defensible, demo-ready graduation project. Frontend (Flutter) is the primary concern; backend touches are limited to what unblocks the frontend or fixes hard security/data leaks.

---

## 0. How to Read This Document

The plan is split into 4 prioritized buckets:

| Priority | When to do it | What's in it |
|---|---|---|
| **P0 — BLOCKERS** | Day 1 morning | Without these, the app cannot even be demoed: register/login flow, security leaks, runtime crashes. |
| **P1 — CORE FEATURES** | Day 1 afternoon → Day 2 | The features the demo will actually show: library, quotes, reader, search, profile. |
| **P2 — POLISH** | Day 3 | Things that make the demo look finished: error states, empty states, hardcoded text, broken images. |
| **P3 — NICE TO HAVE** | Day 4 (only if time) | Push notifications, refresh tokens, CORS for web, admin/author dashboards. Skip if behind. |

Every task has:
- **What** — one sentence on what to do
- **Where** — exact file paths and line numbers
- **Why** — what bug/gap it fixes
- **Time (AI-assisted)** — estimate assuming you're working with Claude Code

**Total estimate with AI assistance: ~22–28 working hours.** That fits in 3 days @ 8h/day with margin.

---

## 1. Project State Summary

### 1.1 Backend (`graduation-project-backend`)
- **Stack:** ASP.NET Core 8, EF Core, SQL Server, JWT, BCrypt, MailKit SMTP.
- **Endpoints:** 60 HTTP routes across 14 controllers. Already deployed at `https://graduation-project-backend-j3bw.onrender.com/api`.
- **Domain:** 19 entities (Books, Users, Reviews, ReadingSessions, Quotes, Notifications, Reports, PublisherRequests, OTP, etc).
- **Status:** Functionally complete. Has security gaps and one integration bug (missing role claim in JWT).

### 1.2 Frontend (`readx-mobile`)
- **Stack:** Flutter 3.44, Bloc + GetIt + Dio + go_router. Clean Architecture per feature.
- **Features present:** auth, home, profile, search, shop, reader, quotes, notifications.
- **Real API integration:** auth, profile, home, book details, comments, reading sessions, notifications.
- **Mocked / disconnected:** library page, quotes page, shop (entire), reader chapter content, OTP/forgot/reset password flows.
- **Status:** Runs on Android emulator. Home + book details + login work end-to-end.

### 1.3 The Top-Level Gap
```
Backend has 60 endpoints. Frontend uses 17.
Of the 43 unused backend endpoints, ~10 are needed for the demo
(library, quotes, reviews, OTP, search, password reset, publisher requests).
The other ~33 are admin/author/CRUD routes we can ignore for the demo.
```

---

## 2. P0 — BLOCKERS (Day 1, ~6 hours)

These MUST be done first. Without them, the app cannot pass the simplest demo path: "register → verify email → login → see books → open one → log out".

### P0-1. Wire OTP verification (registration flow)
- **What:** Replace the `Future.delayed(1s)` placeholders in `otp_page.dart` with real calls to `POST /api/otp/verify`. Same for resend (`POST /api/otp/send`).
- **Where:** `lib/features/auth/presentation/pages/otp_page.dart` lines 74, 84, 94.
- **Why:** Currently OTP screen is fake — any 4 digits "succeed" but the user is never actually verified. The backend has `OtpController` ready (`/api/otp/send`, `/api/otp/verify`).
- **Backend note:** `OtpPurpose` is sent as integer (1=EmailVerification, 2=ForgotPassword, 3=ChangeEmail). OTP expires after 1 minute.
- **Time:** ~1.5h.

### P0-2. Wire forgot-password and reset-password
- **What:** Replace fake delays with real API calls. `forgot_password_page.dart` → `POST /api/users/forgot-password`. `new_password_page.dart` → `POST /api/users/reset-password`.
- **Where:**
  - `lib/features/auth/presentation/pages/forgot_password_page.dart:39`
  - `lib/features/auth/presentation/pages/new_password_page.dart:70`
- **Why:** Users can't recover lost passwords today. Both endpoints exist on the backend.
- **Time:** ~1h.

### P0-3. Fix post-registration navigation
- **What:** After OTP success on registration path, navigate to `/login` (not stay on the OTP page). The TODO at `otp_page.dart:84`.
- **Why:** User completes registration but the app does nothing.
- **Time:** ~10min.

### P0-4. Add 401 interceptor → auto-redirect to login
- **What:** In `DioClient`, add an `InterceptorsWrapper` that on 401: clears `CACHED_AUTH_TOKEN`, clears the auth header, and uses a router callback to push `/welcome`.
- **Where:** `lib/core/network/dio_client.dart`.
- **Why:** Today, expired tokens cause profile/library to silently fail; user gets stuck on a broken screen.
- **Time:** ~45min.

### P0-5. Backend security: do not return password hashes
- **What:** Remove `HashPassword` field from `UserResponse` in `Application/User/.../UserResponse.cs` (or stop returning it from `getbyid`/`getall`).
- **Where:** Backend, `Application/User/` folder.
- **Why:** `GET /api/users/getall` and `GET /api/users/getbyid/{id}` currently leak BCrypt hashes. Even if not exploited, this WILL be flagged by an examiner reading the code.
- **Time:** ~30min.

### P0-6. Backend security: add `[Authorize]` to mutating endpoints
- **What:** Add `[Authorize]` at the controller level for: `BooksController` (POST/PUT/DELETE), `CategoriesController` (POST/PUT/DELETE), `LanguageController` (POST/DELETE), `LibraryController`, `BookReviewsController`, `ReadingSessionsController`, `QuotesController`, `NotificationsController`. Use `[AllowAnonymous]` to override on read-only routes that need it (home, book list, book detail, search, etc).
- **Where:** Backend `API/Controlers/*.cs`.
- **Why:** Today anyone can delete any book or category without logging in. Easy fix, high impact for a graduation defense.
- **Time:** ~45min.

### P0-7. Backend: add role claim to JWT
- **What:** In `Infrastructure/Security/JwtProvider.cs`, add `new Claim(ClaimTypes.Role, user.Role.ToString())` to the claims list.
- **Where:** Backend, `Infrastructure/Security/JwtProvider.cs`.
- **Why:** Backend uses `[Authorize(Roles="Admin")]` but never issues a role claim. Admin/author endpoints are effectively unreachable to legitimate admins.
- **Time:** ~15min.

### P0-8. Smoke-test the registration → OTP → login → home loop
- **What:** Manually run the full flow on the emulator, fix anything broken.
- **Why:** Confidence check before moving to features.
- **Time:** ~1h (debug buffer).

**P0 total: ~6 hours.**

---

## 3. P1 — CORE FEATURES (Day 1 PM → Day 2, ~10 hours)

These are the features the demo will showcase. Each one moves a screen from "mocked" to "real".

### P1-1. Library page → real API
- **What:** Replace the static `BookRepository` usage with real calls. Reads: `GET /api/library?status=&pageNumber=&pageSize=`. Add: `POST /api/library/{bookId}?status=`. Remove: `DELETE /api/library/{bookId}`. Build a `LibraryBloc` (events: `LoadLibrary`, `AddBook`, `RemoveBook`, `ChangeStatus`; states: `LibraryLoading`, `LibraryLoaded`, `LibraryError`).
- **Where:** `lib/features/home/presentation/pages/library_page.dart`. New folder: `lib/features/library/` (move out of `home`).
- **Why:** Library is the second-most-visible tab (Tab 1) and is currently 100% offline mock data.
- **Backend gotcha:** `status` is a query param `?status=0|1|2`, not body. `bookId` is in the route.
- **Time:** ~3h.

### P1-2. Quotes page → real API
- **What:** Replace `QuotesRepository` (in-memory) with calls to `GET /api/quotes/my/{readerProfileId}`, `POST /api/quotes`, `DELETE /api/quotes/{id}?readerProfileId=`. Build a small `QuotesBloc`. Save `readerProfileId` in app state when profile loads.
- **Where:** `lib/features/quotes/`. Currently has only a page — add `data/`, `domain/`, `presentation/bloc/`.
- **Why:** Quotes is Tab 3, fully offline today. Backend already supports it.
- **Backend gotcha:** Frontend has no `readerProfileId` yet. Get it from `/users/me` (currently the response only includes user id, NOT readerProfileId — see backend gap below).
- **Time:** ~3h.

### P1-3. Search page → real API
- **What:** Replace in-memory filtering with `GET /api/books/search?searchTerm=&categoryId=&languageId=&minimumRating=&pageNumber=&pageSize=`. Build a `SearchBloc` with debounced query input.
- **Where:** `lib/features/search/`. Currently has no bloc — add it.
- **Why:** Search currently only filters whatever happens to be on the home page. Real users will search the full catalog.
- **Backend gotcha:** Search term must be ≥ 2 characters (backend validates).
- **Time:** ~2h.

### P1-4. Reviews on book details (clarified)
- **Current state:** `BookDetailsPage` ALREADY has a "Reviews" UI section with "Post Review", "Delete Review", "Update Review" buttons. BUT the code underneath calls the **comments** endpoints (`/books/{id}/comments`), not the actual reviews endpoints. The UI just renamed comments → reviews in the SnackBar text. There is also no star-rating input.
- **What to do:**
  1. Add a star-rating widget (0.5–5.0 step 0.5) above the review text input.
  2. Create a separate "Reviews" section that calls the real review endpoints, distinct from comments.
  3. Decide with your team: keep BOTH (comments = casual chat, reviews = star-rated review) OR replace comments with reviews entirely.
- **Real endpoints to wire:**
  - `POST /api/books/{bookId}/reviews` body `{rating: decimal, reviewText: string?}`
  - `GET /api/books/{bookId}/reviews?pageNumber=&pageSize=`
  - `GET /api/books/{bookId}/reviews/me` (current user's review or 404)
  - `DELETE /api/books/{bookId}/reviews`
- **Where:** `lib/features/home/presentation/pages/book_details_page.dart` — the existing `_buildReviewsSection` (~line 791) and `_submitComment`/`_updateComment`/`_deleteComment` (lines 170–259).
- **Backend gotcha 1:** A review can only be left **after a completed reading session** (`POST /reviews` handler enforces).
- **Backend gotcha 2:** Today the SnackBars say "Review submitted/updated/deleted" but the underlying code is calling `BooksService.addComment/updateComment/deleteComment`. Either rename UI back to "Comment" OR finish wiring real reviews.
- **Time:** ~2h.

**P1 total: ~10 hours.**

---

## 4. P2 — POLISH (Day 3, ~6 hours)

These don't add features. They make the existing app feel finished and demo well.

### P2-1. Replace hardcoded daily tip with backend value (or rotate locally)
- **What:** Either ship 5 hardcoded tips and rotate by day-of-week, OR add `GET /api/admin/settings/DailyTip` and pipe through. Local rotation is simpler and looks just as good.
- **Where:** `home_page.dart` `_DailyTipBanner` widget.
- **Time:** ~30min.

### P2-2. Replace hardcoded "12 DAY STREAK / 850 XP / Next Reward" in readers
- **What:** Pull `currentStreak`, `tokenBalance`, `totalTokensEarned` from `ProfileBloc` (already loaded). Drop the "Next Reward" line until reward system is wired.
- **Where:** `epub_reader_page.dart`, `reading_page.dart`.
- **Time:** ~1h.

### P2-3. Empty states + error states everywhere
- **What:** Library empty: "Your library is empty. Add a book from search." Quotes empty: "Save your first quote while reading." Notifications empty: already done. Search no results: already partial. Generic API error: SnackBar with "Couldn't load. Try again."
- **Where:** All five tab pages.
- **Time:** ~1h.

### P2-4. Fix broken book covers (`coverImageUrl` containing test garbage like "1234", "fadsfadsf")
- **What:** Backend has test data with broken cover URLs. `cached_network_image` already shows an error widget, but it's a small icon. Replace with a nicer placeholder (gradient + book icon + title).
- **Where:** `home_page.dart` `_BookListCard.errorWidget`, similar in `library_page.dart`.
- **Why:** Demo will look amateur with little broken-image icons everywhere.
- **Time:** ~30min.

### P2-5. Hide / remove `DEV SKIP` button from welcome page
- **What:** Either delete it or guard it with `kDebugMode`.
- **Where:** `lib/features/auth/presentation/pages/welcome_page.dart`.
- **Why:** A literal "DEV SKIP — bypass login" button is a red flag in a graduation demo.
- **Time:** ~5min.

### P2-6. Email verification banner: hook the "Verify" button
- **What:** When `isEmailVerified == false`, the banner shows "Verify Email". Tapping should send an OTP and route to `/otp`.
- **Where:** `profile_page.dart`.
- **Time:** ~30min.

### P2-7. Pull-to-refresh on Profile and Search
- **What:** Wrap each page in `RefreshIndicator` dispatching the relevant `Refresh*Event`. Home and Notifications already do this.
- **Time:** ~30min.

### P2-8. Fix the `flutter_html` / `universal_file` / `html` undeclared imports
- **What:** Add them to `pubspec.yaml` explicitly. They currently work via transitive deps from `epub_view`, which is fragile.
- **Where:** `pubspec.yaml`.
- **Time:** ~10min.

### P2-9. Replace `print(...)` debug logs with `debugPrint(...)`
- **What:** Search-and-replace. `home_remote_datasource.dart` is the worst offender.
- **Time:** ~10min.

### P2-10. Manual end-to-end QA pass
- **What:** Run every screen on the emulator. Click every button. Note crashes / weird text / overflow / missing back button.
- **Time:** ~1.5h.

**P2 total: ~6 hours.**

---

## 5. P3 — NICE TO HAVE (Day 4, only if time, ~6+ hours)

Skip these if behind schedule. They're impressive but not necessary for a passing grade.

### P3-1. Backend: add CORS so the app can run on Flutter Web (for desktop demo)
- **What:** In `API/Program.cs`, register a CORS policy allowing `http://localhost:*` and add `app.UseCors(...)` before `UseAuthentication`.
- **Where:** Backend `API/Program.cs`.
- **Why:** Lets you run `flutter run -d chrome` for the live demo without `--disable-web-security`.
- **Time:** ~30min.

### P3-2. Refresh-token flow
- **What:** Add a refresh token entity, an endpoint, and a Dio interceptor that retries on 401.
- **Why:** Today, after 24h, every user gets logged out. Not critical for a demo (the demo runs in 30 minutes), but a senior reviewer will ask.
- **Time:** ~3h.

### P3-3. Push notifications via FCM
- **What:** Wire `firebase_messaging`, register device tokens with the backend, broadcast `BookPublished` notifications.
- **Why:** The backend already creates `Notification` rows for events. Pushing them is straightforward but adds 2–3h of platform setup (Firebase project, Android plist).
- **Time:** ~3h.

### P3-4. Publisher request flow (for Author role)
- **What:** Build screens to submit a NewBook / ModifyBook / RemoveBook request. Backend already supports all three.
- **Where:** New feature `lib/features/publisher/`.
- **Time:** ~3h.

### P3-5. Admin dashboard
- **What:** Tiny admin tab visible only when `role == Admin`. Lists `/api/admin/dashboard` stats.
- **Time:** ~2h.

### P3-6. Author dashboard
- **What:** Same idea, but for `role == Author`. Lists `/api/authordashboard/dashboard`.
- **Time:** ~2h.

### P3-7. Disable Swagger UI in production (or guard it)
- **What:** Move `app.UseSwagger()` / `app.UseSwaggerUI()` inside `if (app.Environment.IsDevelopment())`.
- **Where:** Backend `API/Program.cs`.
- **Time:** ~10min.

### P3-8. Wire reports
- **What:** "Report this book" / "Report this comment" buttons that hit `POST /api/reports`. Backend already supports it.
- **Time:** ~1h.

### P3-9. Wire the unreachable `BookShopPage` and `CubeShopPage` into the router (or delete them)
- **What:** Decide: are these features part of the demo? If yes, route them. If no, delete the files to reduce dead code (your reviewers will read the codebase).
- **Where:** `lib/core/router/app_router.dart`.
- **Time:** ~30min.

---

## 6. Backend Gaps That Affect the Frontend

Things the frontend wants that the backend doesn't currently provide. These are **not all blockers** — most can be worked around frontend-side. Listed in priority order.

| # | Gap | Frontend impact | Recommended fix | Time |
|---|---|---|---|---|
| B-1 | `/users/me` does NOT return `readerProfileId` (only user id). | Quotes can't filter by reader. Library uses user id directly which the backend handler then resolves — works. | Add `ReaderProfileId` to `UserMeResponse`. | 30min |
| B-2 | No bulk "mark notification as read" for a single notification (only mark-all). | Tap-to-mark-read won't be possible. | Add `PUT /api/notifications/{id}/read`. | 30min |
| B-3 | No book-purchase / wallet endpoint. | Shop is mocked; no way to actually buy. | Skip for graduation demo (treat shop as a future feature). | 0 |
| B-4 | No "verify email after registration" trigger. The `users/create` endpoint has the OTP send call commented out. | Frontend has to manually call `/otp/send` after register. | Either uncomment in `Application/User/Create User/CreateUserHandler.cs` OR have frontend call `/otp/send` after registration. | 15min |
| B-5 | Enums serialize as integers (no `JsonStringEnumConverter`). | Frontend must send/expect ints for `ReadingStatus`, `OtpPurpose`, etc. | Already handled — frontend uses ints. Document this. | 0 |
| B-6 | No CORS. | Flutter Web blocked. Mobile fine. | See P3-1 if you want web demo. | 30min |
| B-7 | `LibraryController` returns `bookId` but no current `currentPage` from any active reading session. | Library "Continue Reading" can't show progress %. | Either add a sub-query in the handler, OR frontend hits `/reading-sessions/{bookId}` per book (slow). Skip for v1. | 0 |
| B-8 | Search term must be ≥ 2 chars (silent 400 otherwise). | Frontend validation needed. | Add a guard in `SearchBloc` (don't dispatch < 2 chars). | included in P1-3 |
| B-9 | `UserResponse` leaks password hash. | None (frontend ignores it) but it's a security defect. | See P0-5. | 30min |

---

## 7. Risks and How to Handle Them

| Risk | Likelihood | Mitigation |
|---|---|---|
| Backend goes down on Render's free tier (cold start = 30s+ first request). | High | First request after a long pause will look slow. Add a loading skeleton. Mention "render free tier cold start" if asked. |
| OTP emails don't arrive (SMTP misconfig). | Medium | Check `appsettings.json` SMTP creds. Test before demo. Have a fallback: the OTP is logged in the backend Render logs for debugging. |
| Emulator runs slow on Mac. | Low | Already up. If laggy, reduce graphics quality in AVD settings. |
| One of the P1 features breaks at the last minute. | Medium | Always commit working code before starting next feature. Use git tags after each P0 / P1 / P2 done. |
| Frontend leader returns and wants to "rebase" the work. | Medium | Push to a feature branch (`huthifa/sprint`), not main. |
| Time pressure → tempted to skip P0 security fixes. | High | DON'T. Examiners read the code. The fixes are 15–45 min each. |
| Loss of work due to local-only changes. | Medium | `git push` after every completed task. |

---

## 8. Day-by-Day Schedule (suggested)

### Day 1 (today) — 8 hours
- **Morning (4h):** P0-1, P0-2, P0-3, P0-4 (auth flows + interceptor).
- **Afternoon (4h):** P0-5, P0-6, P0-7 backend security; P0-8 smoke test; start P1-1 (library API).

### Day 2 — 8 hours
- **Morning (4h):** Finish P1-1 (library); P1-2 (quotes).
- **Afternoon (4h):** P1-3 (search); P1-4 (reviews).

### Day 3 — 8 hours
- **Morning (4h):** P2-1 → P2-7 (polish).
- **Afternoon (4h):** P2-8, P2-9, P2-10 (manual QA + last fixes).

### Day 4 (buffer / nice-to-have) — 6 hours
- Pick 2 from P3 if time. Otherwise: more QA, write a one-page README for the demo, prepare the live presentation script.

---

## 9. Demo Script (memorize this for the defense)

1. **Open the app on the emulator.** Land on welcome.
2. **Register a new user.** Show the OTP arriving by email. Verify.
3. **Log in.** Show the home page with categories, trending, recommended.
4. **Open a book.** Show details, comments, reviews, average rating.
5. **Add to library** with status "Want to Read".
6. **Switch to the Library tab.** Show the book is there.
7. **Open the EPUB reader.** Read for ~10 seconds. Show progress saving.
8. **Save a quote.** Switch to Quotes tab, show it.
9. **Search.** Type a book title.
10. **Profile.** Show streak, tokens, level.
11. **Notifications.** Show the bell, mark all read.
12. **Log out.**

Total: ~5–7 minutes. Practice it twice before the real defense.

---

## 10. Useful Commands

```bash
# Run on Android emulator
cd /Users/huthifa/Documents/GitHub/readx-mobile
flutter run -d emulator-5554

# Hot reload while running
# Press 'r' in the terminal

# Hot restart (full reload)
# Press 'R'

# Get fresh dependencies
flutter pub get

# Clean build (when stuck)
flutter clean && flutter pub get && flutter run -d emulator-5554

# Test backend endpoint directly
curl -s "https://graduation-project-backend-j3bw.onrender.com/api/books/home"

# Check git status
git status
git log --oneline -10

# Commit work-in-progress (do this often)
git add .
git commit -m "wip: <what you just did>"
git push
```

---

## 11. Reference Documents

- **Full backend map:** `/Users/huthifa/BACKEND_MAP.md` (60 endpoints, all DTOs, all entities)
- **Full frontend map:** `/Users/huthifa/FRONTEND_MAP.md` (every feature, page, bloc, model, mock flag)

These are the source of truth for any "what does X do?" question.

---

## 12. What "Done" Looks Like

By end of Day 3, the app should:
- Register, OTP-verify, login a new user end-to-end against the live backend.
- Show home / library / search / quotes / profile, all with real data.
- Open a book, read it (EPUB), save progress, save a quote.
- Rate a book and see the rating reflected on the book card.
- Show notifications and mark them read.
- Have no obviously fake "12 DAY STREAK" / dev-skip / mock-data UI elements visible.
- Pass a manual QA pass (no crashes, no obvious overflow / red error screens).
- Deploy and run on the demo Android emulator without `--disable-web-security` or any dev shortcut.

That's a pass.
