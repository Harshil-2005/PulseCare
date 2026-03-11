# PulseCare Architecture Audit

Date: 2026-03-11
Scope: Full architecture audit of the Flutter project in `pulsecare/`
Audit mode: Read-only analysis, no production code changes made

## 1. Executive Summary

PulseCare has a recognizable layered structure built around Flutter, Riverpod, repositories, and datasource abstractions. The core product flows are present: authentication, patient onboarding, doctor onboarding, doctor discovery, appointment booking, doctor scheduling, report upload, reviews, and an AI-assisted intake flow.

The architecture is partially production-oriented but still mixed in practice.

Strengths:

- Clear separation between UI, repositories, models, and data sources.
- Firebase Auth and Firestore are integrated for major business entities.
- Scheduling logic is centralized in a dedicated domain layer.
- Most screens use repositories instead of talking directly to Firestore.
- Riverpod is used consistently for dependency wiring and many reactive flows.

Primary risks:

- Appointment conflict prevention is enforced only on the client.
- AI summaries are not durably persisted across devices or app restarts.
- Report metadata is stored remotely, but report files remain local to the device.
- Some flows bypass the intended architecture through direct session and SDK access.
- Doctor-side appointment state updates are not fully wired through detail-screen actions.

Bottom line:

- The app is structurally ahead of a prototype.
- It is not yet production-safe for appointment integrity, report durability, or AI persistence.

## 2. Project Structure

### Workspace-Level Folders

| Folder | Role |
|---|---|
| `pulsecare/` | Main Flutter application and actual runtime codebase |
| `backend/` | Not a backend service in its current state; contains Python environment/cache only |
| `_temp_untracked/` | Scratch or temporary notes/files, not part of runtime architecture |

### Flutter App Structure

| Path | Role |
|---|---|
| `pulsecare/lib/` | Main application source root |
| `pulsecare/lib/model/` | Domain entities and value models |
| `pulsecare/lib/repositories/` | Repository layer used by UI and business flows |
| `pulsecare/lib/data/` | Datasources, local/Firebase implementations, helpers |
| `pulsecare/lib/data/datasources/firebase/` | Firestore/Firebase-backed datasource implementations |
| `pulsecare/lib/data/datasources/api/` | Placeholder API datasources, currently unimplemented |
| `pulsecare/lib/providers/` | Riverpod provider wiring and session state |
| `pulsecare/lib/domain/` | Business/domain logic, especially availability generation |
| `pulsecare/lib/services/` | Service-style logic, currently mock AI intake service |
| `pulsecare/lib/auth/` | Authentication UI |
| `pulsecare/lib/accountsetup/` | Post-auth patient onboarding/setup flow |
| `pulsecare/lib/onboarding/` | Intro onboarding screens |
| `pulsecare/lib/user/` | Patient-facing application screens |
| `pulsecare/lib/doctor/` | Doctor-facing application screens |
| `pulsecare/lib/appointment_screens/` | Patient appointment list tabs |
| `pulsecare/lib/constrains/` | Shared UI widgets/components; functionally a common UI folder |
| `pulsecare/lib/utils/` | Formatting and input utilities |
| `pulsecare/assets/` | Fonts, icons, images, sample reports |
| `pulsecare/test/` | Minimal default test coverage only |
| `pulsecare/build/` | Generated build output, not architectural source |

### Structure Assessment

The codebase follows a reasonable application layering pattern. The main structural issue is not folder design but inconsistent runtime discipline: some parts respect repository boundaries well, while others take shortcuts through singletons, local mutable shell state, or direct SDK/session access.

## 3. Domain Models

### Core Models

#### User
Path: `pulsecare/lib/model/user_model.dart`

Fields:

- `id`
- `createdAt`
- `updatedAt`
- `fullName`
- `firstName`
- `lastName`
- `email`
- `phone`
- `dateOfBirth`
- `age`
- `gender`
- `role`
- `avatarPath`

Relationships:

- Parent identity model for both patient and doctor accounts.
- Doctor profile links back to user via `Doctor.userId`.

Assessment:

- Adequate for current profile needs.
- Avatar support exists at model level but is not architecturally completed end to end.

#### Doctor
Path: `pulsecare/lib/model/doctor_model.dart`

Fields:

- `id`
- `userId`
- `createdAt`
- `updatedAt`
- `name`
- `speciality`
- `address`
- `experience`
- `rating`
- `reviews`
- `patients`
- `image`
- `email`
- `about`
- `consultationFee`
- `slotDuration`
- `isAvailableForBooking`
- `schedule`
- `overrides`

Relationships:

- References `User` through `userId`.
- Owns `List<DaySchedule>` and `List<DateOverride>`.
- Referenced by appointments through `doctorId`.

Assessment:

- Strong enough for current scheduling and listing flows.
- Contains embedded denormalized metrics like `rating`, `reviews`, `patients`.
- Firebase rating updates also use `ratingTotal`, but that field is not represented on the model.

#### Appointment
Path: `pulsecare/lib/model/appointment_model.dart`

Fields:

- `doctor`
- `patientName`
- `age`
- `gender`
- `scheduledAt`
- `status`
- `id`
- `createdAt`
- `updatedAt`
- `userId`
- `doctorId`
- `symptoms`
- `reports`
- `aiSummaryId`
- `reviewSubmitted`

Relationships:

- Connects a patient user to a doctor.
- Contains embedded doctor snapshot plus authoritative `doctorId`.
- Can attach multiple `ReportModel` items.
- Can reference an AI summary via `aiSummaryId`.

Assessment:

- Good coverage for the booking flow.
- Embedded doctor snapshot is useful for display but can become stale.
- No patient model snapshot beyond copied primitive fields.

#### DaySchedule
Path: `pulsecare/lib/model/day_schedule.dart`

Fields:

- `id`
- `createdAt`
- `updatedAt`
- `day`
- `morningEnabled`
- `morningStart`
- `morningEnd`
- `afternoonEnabled`
- `afternoonStart`
- `afternoonEnd`

Relationships:

- Owned by `Doctor.schedule`.
- Can also be embedded inside `DateOverride.customSchedule`.

Assessment:

- Central to scheduling.
- Time parsing logic lives in-model, which is acceptable but blends value-object behavior with parsing concerns.

#### DateOverride
Path: `pulsecare/lib/model/date_override.dart`

Fields:

- `id`
- `createdAt`
- `updatedAt`
- `startDate`
- `endDate`
- `customSchedule`

Relationships:

- Owned by `Doctor.overrides`.
- Uses `customSchedule == null` to represent full-day leave.

Assessment:

- Practical and compact.
- Works for both leave blocks and custom date-specific schedules.

#### ReportModel
Path: `pulsecare/lib/model/report_model.dart`

Fields:

- `id`
- `userId`
- `appointmentId`
- `doctorId`
- `createdAt`
- `updatedAt`
- `title`
- `uploadedAt`
- `icon`
- `pdfPath`

Relationships:

- Owned by a user.
- Optionally linked to an appointment and/or doctor.

Assessment:

- Sufficient for local file flows.
- Incomplete for cloud storage architecture because it lacks remote URL, storage path, content type, or checksum metadata.

#### DoctorReview
Path: `pulsecare/lib/model/doctor_review_model.dart`

Fields:

- `id`
- `doctorId`
- `userId`
- `appointmentId`
- `rating`
- `comment`
- `createdAt`

Relationships:

- Belongs to a doctor.
- Belongs to a user.
- Intended to be anchored to one appointment.

Assessment:

- Correct minimal review model.
- No server-side uniqueness guarantee is visible.

### AI and Chat Models

#### ChatMessage
Path: `pulsecare/lib/model/chat_message.dart`

Fields:

- `id`
- `createdAt`
- `updatedAt`
- `isUser`
- `message`
- `sentAt`

Assessment:

- Fine for transcript items.
- Not durably persisted in current architecture.

#### ChatHistoryEntry
Path: `pulsecare/lib/model/chat_history_entry.dart`

Fields:

- `id`
- `title`
- `subtitle`
- `tags`
- `createdAt`
- `updatedAt`

Assessment:

- This is only a chat summary record, not a recoverable conversation.

#### AIResponse
Path: `pulsecare/lib/model/ai_response_model.dart`

Fields:

- `rawText`
- `detectedSymptoms`
- `recommendedSpecialty`
- `triageLevel`
- `confidence`
- `generatedAt`
- `stage`
- `duration`
- `medications`
- `severity`
- `temperature`
- `summaryId`

Assessment:

- Good transport model for staged AI responses.

#### AISummaryModel
Path: `pulsecare/lib/model/ai_summary_model.dart`

Fields:

- `id`
- `userId`
- `symptoms`
- `duration`
- `medications`
- `severity`
- `temperature`
- `recommendedSpecialty`
- `triageLevel`
- `confidence`
- `generatedAt`

Assessment:

- Important architectural gap: no persistence beyond in-memory local datasource.
- Missing `conversationId` and `appointmentId`, which would improve traceability.

#### IntakeSession
Path: `pulsecare/lib/model/intake_session_model.dart`

Fields:

- `conversationId`
- `stage`
- `symptoms`
- `duration`
- `medications`
- `severity`
- `temperature`

Assessment:

- Useful for the staged intake engine.
- No persistence or serialization, so it is strictly runtime state.

### UI/Support Models

#### DoctorAvailability / TimeSlot / AvailabilitySlotsResult
Path: `pulsecare/lib/model/doctor_availability.dart`

Assessment:

- These are value/helper models for schedule calculation and rendering.

#### RatingModel
Path: `pulsecare/lib/model/rating_model.dart`

Assessment:

- Pure UI helper for star rendering, not a domain entity.

### Model Completeness Summary

Complete enough for current flows:

- User
- Doctor
- Appointment
- DaySchedule
- DateOverride
- DoctorReview

Architecturally incomplete:

- ReportModel
- AISummaryModel
- IntakeSession
- ChatHistoryEntry

## 4. Data Sources and Persistence Classification

### Repository-Driven Systems

Most feature flows are repository-driven through providers in `pulsecare/lib/providers/repository_providers.dart`.

This is true for:

- Authentication
- Users
- Doctors
- Appointments
- Reports
- Reviews
- Availability generation
- Chat orchestration
- AI summary access

### Firebase Firestore Systems

#### Firebase Auth
- Active
- Implemented in `pulsecare/lib/data/datasources/firebase/firebase_auth_datasource.dart`

#### Firestore Collections in Active Use
- `users`
- `doctors`
- `appointments`
- `reports`
- `doctor_reviews`

Implemented in:

- `firebase_user_datasource.dart`
- `firebase_doctor_datasource.dart`
- `firebase_appointment_datasource.dart`
- `firebase_report_datasource.dart`
- `firebase_doctor_review_datasource.dart`

### Local Static or Local-Only Systems

#### Local Static / Seed / Placeholder
- Onboarding slide content in `pulsecare/lib/data/onboarding_data.dart`
- Mock symptom extraction and intake logic in `pulsecare/lib/services/ai_service.dart`
- Placeholder local datasources still present for users, doctors, appointments, reports, and reviews
- Hardcoded report preview “Key Vitals” in `pulsecare/lib/user/medical_report_preview_screen.dart`

#### Local Persistent But Not Cloud-Synced
- Chat history summary entries stored in SharedPreferences
- Session ids stored in SharedPreferences

#### Local In-Memory Only
- Active AI conversation messages
- AI summaries
- Intake session progression

### Mixed Systems

#### Reports: Mixed
- Firestore stores metadata
- The actual file is only stored locally on the device
- No Firebase Storage upload is implemented

#### AI: Mixed
- UI and repositories exist
- AI summary IDs can be attached to appointments
- But the summary store itself is local/in-memory only

#### Appointments: Mixed Strength
- Persistence uses Firestore
- Conflict prevention remains client-side

### Features Still Using Static or Local-Only Data

- AI symptom extraction and staged response generation
- Full chat transcript persistence
- AI summary persistence
- Report binary storage
- Report preview medical insight section

## 5. Reactive vs Non-Reactive Architecture

### Reactive Mechanisms in Use

- Riverpod providers
- ChangeNotifier-based repositories
- StreamProvider
- Firestore snapshot streams
- Some local manual invalidation patterns

### Non-Reactive Mechanisms in Use

- `setState` for extensive UI/local form state
- One-time async loads in initState for several screens
- Manual refresh behavior in some doctor flows

### Riverpod Usage Assessment

Riverpod is present across the app and is the main dependency injection layer. However, it is not the sole state system.

The real architecture is:

- Riverpod for dependency wiring and many data subscriptions
- ChangeNotifier repositories for mutable data events
- setState for screen-local interaction state

### Screens That Are Meaningfully Reactive

- `pulsecare/lib/user/home_screen.dart`
- `pulsecare/lib/user/profile_screen.dart`
- `pulsecare/lib/user/my_report_screen.dart`
- `pulsecare/lib/user/all_reports_screen.dart`
- `pulsecare/lib/appointment_screens/upcoming_tab.dart`
- `pulsecare/lib/appointment_screens/past_tab.dart`
- `pulsecare/lib/appointment_screens/cancelled_tab.dart`
- `pulsecare/lib/doctor/screens/doctor_schedule_screen.dart`
- `pulsecare/lib/doctor/screens/doctor_profile_screen.dart`
- `pulsecare/lib/doctor/screens/doctor_dashboard_screen.dart` for doctor/user identity only

### Screens That Are Weakly Reactive or Snapshot-Driven

- `pulsecare/lib/user/doctor_detail_screen.dart`
- `pulsecare/lib/user/patient_detail_screen.dart`
- `pulsecare/lib/user/ai_chat_screen.dart`
- `pulsecare/lib/doctor/doctor_app_shell.dart`
- `pulsecare/lib/doctor/screens/doctor_appointments_screen.dart`
- `pulsecare/lib/user/new_ai_chat_screen.dart`

### Key Observation

The patient side is more reactive than the doctor side. The doctor shell caches appointments and doctor state more aggressively, which creates correctness and freshness risks.

## 6. Repository Layer Audit

### AuthRepository
Path: `pulsecare/lib/repositories/auth_repository.dart`

Responsibilities:

- Register user
- Login user
- Google sign-in
- Logout
- Get current auth user id
- Delete auth account
- Cascade account deletion through reports, doctor profile, user profile, and session

Assessment:

- Reasonable orchestration point.
- Still contains direct FirebaseAuth usage internally.

### UserRepository
Path: `pulsecare/lib/repositories/user_repository.dart`

Responsibilities:

- Create user profile
- Fetch user by id
- Watch user by id
- Update user profile
- Delete user profile

Assessment:

- Clean and focused.
- Implemented as a singleton-style factory plus ChangeNotifier, which is workable but inconsistent with other repositories.

### DoctorRepository
Path: `pulsecare/lib/repositories/doctor_repository.dart`

Responsibilities:

- Create/fetch/watch/update doctor profiles
- Increment patient counts
- Delete doctor profile for a user
- Add/remove date overrides
- Normalize day keys
- Generate default editable schedules
- Update weekly schedule day collections

Assessment:

- Central business repository for doctor scheduling.
- Override overlap validation exists here, which is correct.

### AppointmentRepository
Path: `pulsecare/lib/repositories/appointment_repository.dart`

Responsibilities:

- Fetch appointments for user or doctor
- Hydrate embedded doctor snapshot for view consistency
- Watch appointments
- Create appointments
- Reschedule appointments
- Update full appointment record
- Update appointment status with transition rules
- Remove appointments

Assessment:

- Contains important booking rules.
- Duplicate prevention is not authoritative because it is purely client-side.

### ReportRepository
Path: `pulsecare/lib/repositories/report_repository.dart`

Responsibilities:

- Watch reports by user
- Upload from file or camera
- Remove reports
- Delete all reports for a user

Assessment:

- Good boundary around report flows.
- Current architecture still depends on local device file storage.

### ChatRepository
Path: `pulsecare/lib/repositories/chat_repository.dart`

Responsibilities:

- Start conversations
- Store user and AI messages
- Generate AI responses through AIService
- Save chat summary history
- Store AI summaries when intake completes

Assessment:

- Good orchestration point.
- Full transcript persistence is missing.

### AISummaryRepository
Path: `pulsecare/lib/repositories/ai_summary_repository.dart`

Responsibilities:

- Add/get/remove summaries

Assessment:

- Architecturally weak because it only fronts a local in-memory datasource.

### AvailabilityRepository
Path: `pulsecare/lib/repositories/availability_repository.dart`

Responsibilities:

- Generate bookable slots from doctor schedule and known booked times
- Provide placeholder default slot lists

Assessment:

- Correctly isolates scheduling generation behind a repository.

### DoctorReviewRepository
Path: `pulsecare/lib/repositories/doctor_review_repository.dart`

Responsibilities:

- Create doctor reviews
- Query doctor reviews
- Calculate doctor rating
- Update doctor aggregate rating stats

Assessment:

- Good business boundary.
- Rating aggregation depends on client-driven updates to doctor stats.

### SessionRepository
Path: `pulsecare/lib/repositories/session_repository.dart`

Responsibilities:

- Persist and restore current user id
- Persist and restore current doctor id
- Clear session

Assessment:

- Simple and effective.
- Overused directly by UI, which weakens state consistency.

## 7. Firebase Integration Audit

### Active Firebase Products

#### Firebase Core
- Initialized in `pulsecare/lib/main.dart`

#### Firebase Auth
- Used for email/password registration and login
- Used for Google sign-in

#### Cloud Firestore
- Used for:
  - users
  - doctors
  - appointments
  - reports metadata
  - doctor reviews

### Firebase Storage Status

Firebase Storage is configured at environment level through `firebase_options.dart` and included in dependencies, but it is not actually used in application code.

Implication:

- The app has cloud metadata for reports.
- It does not have cloud binary storage for reports.

### What Is Connected to Firebase vs Still Local

Connected to Firebase:

- Authentication
- User profiles
- Doctor profiles
- Appointments
- Report metadata
- Doctor reviews

Still local or local-only:

- Report files themselves
- AI summaries
- Active chat transcripts
- Intake sessions
- Chat history beyond summarized entries

## 8. Feature Audit

### Authentication
Status: Implemented

Implemented:

- Email/password registration
- Email/password login
- Google sign-in
- Role-based post-login routing

Missing or weak pieces:

- No password reset flow
- Some auth/session logic still split between repository and UI

### Patient Onboarding / Account Setup
Status: Implemented

Implemented:

- Name
- Phone
- Age or DOB
- Gender
- Patient vs doctor role selection

Missing or weak pieces:

- Direct FirebaseAuth use in UI for email access

### Doctor Onboarding
Status: Implemented

Implemented:

- Experience
- Specialization
- Hospital/address
- About
- Consultation fee
- Working days
- Working hours
- Slot duration

Missing or weak pieces:

- Stronger validation and persistence for profile image/media

### Doctor Discovery
Status: Implemented

Implemented:

- Doctor listing
- Search by name/specialization
- Filter by specialization
- Computed availability badges

Missing or weak pieces:

- Availability shown is computed client-side only

### Appointment Booking
Status: Implemented

Implemented:

- Doctor selection
- Patient details
- Date selection
- Slot selection
- Appointment creation
- Rescheduling
- Cancellation

Missing or weak pieces:

- No server-side uniqueness enforcement for doctor/time slot

### Doctor Scheduling
Status: Implemented

Implemented:

- Weekly schedule editing
- Add leave ranges
- Full-day leave
- Custom-hours leave
- Availability on/off toggle

Missing or weak pieces:

- Doctor shell state is directly mutated before/around repository persistence

### Patient Appointment Management
Status: Implemented

Implemented:

- Upcoming tab
- Past tab
- Cancelled tab
- Appointment detail screen
- Edit symptoms/reports for editable states
- Review submission

Missing or weak pieces:

- No stronger server-side enforcement around review submission uniqueness

### Doctor Appointment Management
Status: Partially implemented

Implemented:

- Dashboard list and counts
- Appointments tab views
- Detail screen with accept/reject/complete actions

Missing or weak pieces:

- The detail screen returns a result via `Navigator.pop(context, AppointmentStatus...)`, but parent screens push it without awaiting the result.
- This means the intended update path is incomplete.

### Reports System
Status: Partially implemented

Implemented:

- Upload from file
- Upload from camera
- Attach reports to appointments
- View list of reports
- Delete metadata entries
- Local PDF preview

Missing or weak pieces:

- No Firebase Storage upload
- No durable cross-device access to files
- Download/share are placeholders

### Reviews and Ratings
Status: Implemented

Implemented:

- Patient review submission
- Review persistence
- Doctor rating aggregate updates

Missing or weak pieces:

- No visible server-side uniqueness guarantee for one review per appointment

### AI Assistant
Status: Partially implemented

Implemented:

- Chat UI
- Multi-step intake process
- Local chat history summaries
- AI summary generation
- Doctor recommendation cards

Missing or weak pieces:

- AI is mock/rule-based
- No durable AI summary persistence
- No durable full chat transcript persistence
- Doctor recommendations are not specialty-filtered from AI output

## 9. State Mutation Problems and Architecture Violations

### Direct Architecture Violations

#### Direct SDK Access in UI
- `pulsecare/lib/accountsetup/account_setup_flow_screen.dart`
  - Uses `FirebaseAuth.instance.currentUser?.email` directly in UI.

#### Direct Session Access Across UI
- Many screens call `SessionRepository()` directly instead of relying on higher-level application state.

Assessment:

- This is not catastrophic, but it weakens consistency, testability, and architectural discipline.

### UI Directly Mutating Shell-Owned State

#### Doctor schedule flow
- `pulsecare/lib/doctor/screens/doctor_schedule_screen.dart`
  - Mutates `DoctorAppShell.weeklySchedule` and `DoctorAppShell.currentDoctor` directly.

Assessment:

- This is a real architectural violation because screen code is mutating parent shell state outside a dedicated state controller.

### Locally Mutated Appointment Lists in Shell

#### Doctor shell
- `pulsecare/lib/doctor/doctor_app_shell.dart`
  - Holds mutable local `appointments`, `weeklySchedule`, and `currentDoctor`.
  - Uses stream `.first` instead of staying subscribed.

Assessment:

- This creates stale-data risk and duplicates state ownership.

### Report Selection and Appointment Detail Local Mutation

#### Patient detail and appointment detail screens
- These screens locally add/remove selected reports and then persist via repository.

Assessment:

- Acceptable for view-model level local state.
- Not an architecture violation by itself.

## 10. Scheduling System Audit

### Scheduling Building Blocks

- `DaySchedule`
- `DateOverride`
- `AvailabilityEngine`
- `AvailabilityRepository`

### Slot Generation Logic

Primary slot generation lives in `pulsecare/lib/domain/availability_engine.dart`.

Behavior:

- Reject booking if doctor is globally unavailable.
- Apply matching date override first.
- If override is full-day leave, produce no slots.
- Else use override custom schedule or weekly schedule.
- Generate slot times according to `doctor.slotDuration`.
- Mark a slot as booked when an existing non-cancelled appointment matches the same doctor and exact time.

### Override Logic

Primary override validation lives in `pulsecare/lib/repositories/doctor_repository.dart`.

Behavior:

- Prevents overlapping leave/custom overrides for the same doctor.
- Supports removing overrides by date.

### Slot Conflict Prevention

Implemented at two levels:

- Display layer: booked slots are shown as unavailable when generating availability.
- Creation layer: appointment creation and reschedule query Firestore for doctor+exact scheduledAt and block duplicates.

### Scheduling Strengths

- Good separation of domain logic from UI.
- Support for full-day leave and custom-hours leave.
- Slot duration is configurable per doctor.

### Scheduling Weaknesses

- Conflict prevention is only as safe as the client.
- No transaction or server-side uniqueness constraint.
- No visible automated tests for the availability engine.

## 11. Appointment System Audit

### Flow Overview

1. Doctor selected from home or AI recommendation
2. Patient details entered in `PatientDetailScreen`
3. Date and slot selected in `DateTimeScreen`
4. Appointment created through `AppointmentRepository.createAppointment`
5. Doctor or patient updates status later through repository operations

### Duplicate Booking Prevention

Current implementation:

- Query Firestore for appointments matching `doctorId` and exact `scheduledAt`
- Block create/reschedule if any non-cancelled appointment exists

Assessment:

- This prevents duplicates in ordinary single-client use.
- It is not race-safe under concurrency.

### Status Transition Enforcement

Handled in `AppointmentRepository.updateAppointmentStatus`.

Allowed transitions:

- pending -> confirmed
- pending -> cancelled
- confirmed -> completed
- confirmed -> cancelled

Disallowed:

- cancelled -> any
- completed -> any

Assessment:

- The transition rules are sound.

### Doctor-Side Update Wiring Gap

The doctor detail screen returns the selected next status by popping with a result, but parent screens do not await and apply that result.

Impact:

- Accept/reject/complete actions from doctor detail are not reliably integrated into repository updates.

## 12. AI Assistant Audit

### Current Architecture

AI entry points:

- `pulsecare/lib/user/ai_chat_screen.dart`
- `pulsecare/lib/services/ai_service.dart`
- `pulsecare/lib/repositories/chat_repository.dart`
- `pulsecare/lib/repositories/ai_summary_repository.dart`

### How AI Works Today

- A conversation id is started locally.
- User messages are stored in local in-memory conversation state.
- `MockAIService` advances through staged intake:
  - symptoms
  - duration
  - medications
  - severity
  - temperature
  - completed
- On completion, an `AISummaryModel` is created and saved via `AISummaryRepository`.
- A `summaryId` may then be attached to an appointment.

### Where Chat Data Is Stored

#### Active conversation messages
- In-memory only via `LocalChatDataSource._messagesByConversation`

#### Chat history screen entries
- SharedPreferences summary entries only

#### AI summaries
- Local in-memory only via `LocalAISummaryDataSource`

### Architectural Consequences

- Full conversations are not recoverable after restart.
- AI summaries are not available cross-device.
- Doctor-side retrieval of `appointment.aiSummaryId` is unreliable after restart because the repository store is in-memory only.

### AI Recommendation Quality

The system records `recommendedSpecialty`, but doctor recommendations shown to users are not filtered to match it. The recommendation UI currently surfaces all doctors.

## 13. Reports System Audit

### Upload Flow

1. User opens upload bottom sheet
2. Repository calls datasource
3. Datasource calls `ReportUploadService`
4. File picker or camera returns a local file
5. Images are converted into a local PDF file if needed
6. Firestore metadata is written

### View Flow

- Reports are listed from repository streams.
- Preview screen attempts to open the local `pdfPath`.

### Delete Flow

- Firestore metadata document is deleted.
- No visible cloud file deletion exists because no cloud file was uploaded.
- No visible local file cleanup exists.

### Classification

- Metadata: Firestore
- Files: local device storage only
- Cloud storage: not implemented

### Architectural Risk

This is the largest durability gap after appointment integrity:

- Report records can survive in Firestore while the actual file is unavailable on other devices or after reinstall.

## 14. Security and Integrity Risks

### High-Risk Issues

#### Client-side duplicate booking prevention
- Appointments can still race under concurrent clients.

#### Report ownership and durability assumptions
- Metadata alone is insufficient without secure file storage and ownership rules.

#### AI summary persistence mismatch
- Appointment references a summary id that may not exist later.

### Medium-Risk Issues

#### Review submission integrity
- Client-side flags appear to prevent duplicate reviews, but no authoritative enforcement is visible.

#### Session and UI bypasses
- Direct session and SDK usage in UI makes architecture easier to desynchronize.

#### Client-driven deletion cascade
- Account deletion orchestration runs from client code and depends on backend rule correctness.

### Lower-Risk But Important Issues

#### Static report vitals preview
- Could mislead users if interpreted as actual parsed medical content.

#### Doctor-side stale appointment state
- Can produce operational inconsistency for practitioners.

## 15. Architecture Health Score

| Category | Score | Rationale |
|---|---:|---|
| Architecture | 6/10 | Clear layers exist, but runtime discipline is mixed |
| Scalability | 5/10 | Firestore-backed core entities help, but AI/report durability and doctor-state freshness do not scale cleanly |
| Maintainability | 6/10 | Readable structure, but some singleton shortcuts and duplicated flow logic increase friction |
| Production Readiness | 4/10 | Core flows work, but integrity and persistence gaps are still significant |

## 16. Recommended Next Steps

### Priority 1: Data Integrity and Safety

1. Move appointment slot uniqueness enforcement to a server-authoritative or transactional mechanism.
2. Add security rules for ownership across users, reports, appointments, and reviews.
3. Fix the doctor detail action flow so doctor-side status decisions always reach the repository layer.

### Priority 2: Durable Persistence

4. Upload report binaries to Firebase Storage and store only durable metadata/URLs in Firestore.
5. Persist AI summaries in Firestore.
6. Persist full chat transcripts if they are meant to survive across sessions or devices.

### Priority 3: Architecture Cleanup

7. Remove direct FirebaseAuth reads from UI.
8. Reduce direct SessionRepository usage from screens and centralize session-driven navigation/state handling.
9. Eliminate direct shell-state mutation from schedule screens.
10. Standardize repository lifetimes instead of mixing provider-created instances with singleton-style repositories.

### Priority 4: Maintainability and Validation

11. Add tests for:
   - slot generation
   - override overlap prevention
   - appointment status transitions
   - duplicate booking prevention behavior
12. Decide whether API datasources are real roadmap targets; if not, remove them to reduce architectural noise.

## 17. Final Verdict

PulseCare is structurally promising and already beyond a throwaway prototype. The repository/datasource pattern is real, the scheduling domain logic is sensibly isolated, and most user-facing flows are connected end to end.

The project is best described as a mid-stage application architecture with production-oriented intent but unresolved integrity boundaries.

It is ready for the next engineering phase, but that phase should prioritize correctness and persistence before further feature expansion.