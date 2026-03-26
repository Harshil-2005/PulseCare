# PulseCare: A Modern Telemedicine Platform (Presentation Script)

Date: 2026-03-26

---

## 1. Project Vision: What is PulseCare?

PulseCare is a comprehensive, dual-sided mobile application designed to bridge the gap between patients and doctors.

*   **For Patients:** It offers a seamless way to find doctors, book appointments, manage medical records, and get initial AI-powered symptom guidance.
*   **For Doctors:** It provides powerful tools to manage schedules, view appointments, and streamline patient interactions.

Our goal is to create a single, integrated, and user-friendly platform that simplifies healthcare access and management.

**Core Technologies:** Flutter, Riverpod, Firebase (Auth & Firestore), and Supabase (Storage).

---

## 2. Core Features Overview

PulseCare is built around two distinct user experiences:

#### Patient-Facing Features:
*   **Secure Authentication:** Easy sign-up and login using Email/Password or Google Sign-In.
*   **Doctor Discovery:** A searchable list of doctors, filterable by specialty, with visible ratings and availability.
*   **AI-Assisted Triage:** A conversational chat interface to identify symptoms and recommend a doctor specialty before booking.
*   **Seamless Booking:** An intuitive flow to select a doctor, pick a date and time, and book an appointment.
*   **Report Management:** Upload medical reports from the device or camera, which are securely stored and can be attached to appointments.

#### Doctor-Facing Features:
*   **Profile & Schedule Management:** Doctors can set their specialty, fees, and precisely control their weekly schedule, including adding leave or custom hours.
*   **Appointment Dashboard:** A clear overview of upcoming, past, and pending appointments.
*   **Patient & Review Management:** View patient details and manage reviews to maintain their public profile.

---

## 3. Technical Architecture: A Layered Approach

To ensure the application is maintainable, scalable, and testable, we adopted a clean, layered architecture. Each layer has a single, well-defined responsibility.

**UI Layer (The "View")**
*   **What:** Flutter Widgets and Screens.
*   **Responsibility:** Renders the UI and captures user input. It knows *what* to show, but not *how* to get the data.

**Provider Layer (The "Wiring")**
*   **What:** Riverpod Providers.
*   **Responsibility:** Provides dependencies to the UI layer. It connects the UI to the business logic without creating tight coupling.

**Repository Layer (The "Brain")**
*   **What:** Business Logic and Orchestration.
*   **Responsibility:** Contains the core business rules. For example, the `AppointmentRepository` knows the rules for rescheduling an appointment or preventing a double booking. It orchestrates calls to one or more data sources.

**Datasource Layer (The "Hands")**
*   **What:** Data Fetching and Persistence.
*   **Responsibility:** Directly interacts with external services. It knows *how* to talk to Firebase, Supabase, or local device storage, but it doesn't contain any business rules.

This separation of concerns is the foundation of our application's health.

---

## 4. Deep Dive: The Data Flow of Booking an Appointment

Let's trace a real-world example to see the architecture in action:

1.  **UI (`DateTimeScreen`):** A patient selects an available time slot and taps "Confirm".

2.  **Provider (`appointmentRepositoryProvider`):** The UI uses `ref.read(appointmentRepositoryProvider)` to get the `AppointmentRepository` instance and calls the `createAppointment` method.

3.  **Repository (`AppointmentRepository`):** This is where the magic happens.
    *   It validates the request (e.g., checks if the slot is still available).
    *   It constructs the `AppointmentModel` object with all the necessary data (patient ID, doctor ID, timestamp).
    *   It then calls the `FirebaseAppointmentDataSource` to persist this new object.

4.  **Datasource (`FirebaseAppointmentDataSource`):** This class receives the `AppointmentModel` object. Its only job is to convert it into a format Firestore understands and write it to the `appointments` collection in the database.

This flow ensures that our UI is decoupled from our business logic, and our business logic is decoupled from the specific database we are using.

---

## 5. Data Persistence: A Hybrid Storage Strategy

We use a combination of services to store data efficiently and securely, choosing the right tool for the right job.

*   **Firebase Firestore (For Metadata):**
    *   **What:** Our primary database for structured, document-based data.
    *   **Collections:** `users`, `doctors`, `appointments`, `reports` (metadata), `doctor_reviews`, `ai_summaries`.
    *   **Why:** It's fast, scalable, and provides real-time data synchronization, which is perfect for things like appointment lists.

*   **Supabase Storage (For Binary Files):**
    *   **What:** Our object storage solution for large files.
    *   **Buckets:** `pulsecare_pdf` for medical reports, `pulsecare_avatar` for profile pictures.
    *   **Why:** Storing large files like PDFs or images in a database is inefficient. A dedicated file storage service is the correct approach for durability and performance.

*   **Local Storage (`SharedPreferences`):**
    *   **What:** On-device key-value storage.
    *   **Data:** Session tokens, user preferences, and other non-critical cached data.
    *   **Why:** For fast access to data that doesn't need to be synced to the cloud immediately.

---

## 6. Feature Spotlight: The Scheduling Engine

One of the most complex parts of the project is the doctor's scheduling and availability system. We centralized this logic into a dedicated `AvailabilityEngine`.

**How it Works:**

1.  **Base Schedule:** It starts with the doctor's standard weekly schedule (e.g., "Mon 9-5, Tue 9-1").
2.  **Overrides:** It then applies any `DateOverride` records. This allows a doctor to specify leave (full-day off) or set custom hours for a specific date range (e.g., working only in the morning next Friday).
3.  **Booked Appointments:** It queries all existing, non-cancelled appointments for that day.
4.  **Slot Generation:** Finally, it generates a list of `TimeSlot` objects based on the doctor's `slotDuration` (e.g., every 30 minutes), and marks any slots that clash with existing appointments as "booked".

This engine is located in the `domain/` layer, completely separate from the UI, making it a pure, testable piece of business logic.

---

## 7. Feature Spotlight: AI-Assisted Triage Flow

To help patients before they even book, we implemented an AI-assisted triage chat.

**The End-to-End Flow:**

1.  **Conversation Start:** The patient initiates a chat from the home screen.
2.  **Symptom Intake:** The user describes their symptoms. The `MockAIService` uses keyword matching (from `triage_data.dart`) to parse the initial message.
3.  **Staged Follow-up:** Based on the detected symptoms, the service proceeds through a multi-step conversation to gather more information: duration, medications, severity, etc.
4.  **Summary Generation:** Once the intake is complete, an `AISummaryModel` is created.
5.  **Persistence:** This summary is saved to the `ai_summaries` collection in Firestore via the `AISummaryRepository`.
6.  **Doctor Recommendation:** The system uses the summary to recommend a medical specialty, helping the user find the right doctor.

This creates a complete, valuable feature loop that enhances the user experience and provides useful data for the doctor.

---

## 8. Project Strengths & Key Learnings

#### Strengths:
*   **Clean, Scalable Architecture:** The layered approach and use of Riverpod for dependency injection make the codebase easy to navigate, extend, and maintain.
*   **Clear Separation of Concerns:** Business logic is not mixed with UI code or data fetching code, which is a major architectural win.
*   **Robust Data Model:** The hybrid storage strategy (Firestore for metadata, Supabase for files) is a production-ready pattern that ensures performance and data integrity.
*   **Encapsulated Domain Logic:** Complex features like the `AvailabilityEngine` are isolated and well-defined, making them reliable and testable.

#### Key Learnings:
*   The critical importance of a well-defined architecture from the beginning of a project.
*   Effective state management strategies in a complex Flutter application using Riverpod.
*   The benefits of integrating multiple backend-as-a-service platforms to leverage their individual strengths.
*   The challenge and reward of modeling complex, real-world domains like medical scheduling.

---

## 9. Future Improvements

While the project is functionally complete, there are several exciting areas for future development:

*   **Integrate a Real AI Model:** Replace the rule-based `MockAIService` with a true Large Language Model (like the Gemini API) for more nuanced and intelligent symptom analysis.
*   **Server-Side Booking Transactions:** Move the appointment conflict-checking logic to a Firebase Cloud Function to make it transactional and eliminate any possibility of race conditions from concurrent bookings.
*   **Durable Chat History:** Persist the full chat transcripts to Firestore to allow users to view their past conversations across devices.
*   **Video Consultations:** Integrate a WebRTC or third-party SDK to enable in-app video calls between patients and doctors.

---

## 10. Thank You & Questions
