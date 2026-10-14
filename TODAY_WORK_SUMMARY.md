# Today's Implementation & Bug Fixes Summary

**Date**: September 28, 2026  
**Project**: Construction Workforce Recruitment & Site Management Platform (BuildHire)

---

## 🚀 Key Features Implemented

### 1. Company Authentication & Onboarding Flow
- **Email + Password Registration**:
  - Built `CompanyRegisterScreen` (`lib/screens/auth/company_register_screen.dart`).
  - Implemented company sign-up via `POST /auth/register` using Email & Password (no mandatory phone input).
  - Automatically persists `accessToken`, `refreshToken`, and `role: 'company'` to `FlutterSecureStorage`.
  - Automatically routes newly registered companies to the 2-step onboarding screen: `CompanyProfileFormScreen(isInitialSetup: true)`.
- **Company Login**:
  - Updated `CompanyLoginScreen` (`lib/screens/auth/company_login_screen.dart`).
  - Handled Email + Password authentication (`POST /auth/login`).
  - Saved `role: 'company'` for role-based app routing.
- **Company Profile Onboarding & Management**:
  - Built `CompanyProfileFormScreen` (`lib/screens/company/company_profile_form_screen.dart`).
  - Supports initial setup & profile editing (`POST /companies` and `PATCH /companies/:id`).
  - Fields included: Company Name, CIN/Registration Number, GST Number, PAN Number, Contact Email, Phone, Alternate Phone, Website, Address, City, State, Pincode, Business Type, Year Established, Team Size Range, Specializations, Operational Areas, and Description.

---

### 2. Employer Portal & Dashboard
- **Updated `CompanyHomeScreen` (`lib/screens/company/company_home_screen.dart`)**:
  - **4 Bottom Tabs**:
    1. **Applications**: Candidate list with filter chips (*All, Pending, Shortlisted, Hired, Rejected*) and bulk shortlisting.
    2. **Site Jobs**: Posted site requirements with status badges (*Published, Draft, Closed*), publish actions, and close actions.
    3. **Analytics**: Funnel report metrics (*Total Jobs, Total Applications, Shortlisted, Hired, Acceptance Rate*).
    4. **Company Profile**: Overview card with verification status (*Pending, Verified, Rejected*), contact info, and legal registration numbers.
  - **Interactive Candidate Review Modal**:
    - Detailed candidate profile view.
    - Quick actions to **Shortlist**, **Reject**, or **Hire** candidate with optional review remarks.
  - **Bulk Candidate Shortlisting**:
    - Multi-select candidates with checkbox controls.
    - Triggers `POST /applications/bulk-shortlist`.
  - **Company Profile Guard on Job Creation**:
    - Checks if company profile exists before opening job creation.
    - If profile is missing (404), prompts user to complete company setup first.

---

### 3. API Integrations & Repository Layer
- **Created `CompanyRepository` (`lib/features/repositories/company_repository.dart`)**:
  - Implemented full API integration for 10 endpoints:
    - `POST /companies` (Register Profile)
    - `GET /companies/my-profiles` (Get Owned Profiles)
    - `GET /companies` & `GET /companies/:id` (Details & Search)
    - `PATCH /companies/:id` (Update Profile)
    - `PATCH /companies/:id/verify` (Verification Status)
    - `POST /jobs` (Create Job)
    - `GET /jobs` & `GET /jobs/:id` (Get Jobs)
    - `PATCH /jobs/:id` (Update Job)
    - `POST /jobs/:id/close` (Close Job)
    - `GET /applications` & `GET /applications/:id` (Manage Applications)
    - `PATCH /applications/:id/status` (Update App Status)
    - `POST /applications/bulk-shortlist` (Bulk Shortlist)
    - `GET /reports/operations/jobs-applications` (Analytics Report)
  - Handled missing/optional endpoints (e.g. `/reports/operations/jobs-applications` returning 404) gracefully with try-catch fallbacks.

---

### 4. Global Auth Interceptor & Session Expiry Handling
- **Updated `main.dart`**:
  - Added global `GlobalKey<NavigatorState> navigatorKey` to `MaterialApp`.
  - Configured auth router to inspect stored `role`:
    - `company` -> `CompanyHomeScreen`
    - `job_seeker` -> `HomePage`
- **Updated `ApiClient` (`lib/core/api/api_client.dart`)**:
  - Intercepted `401 Unauthorized` / `Session expired` responses globally.
  - Automatically clears `FlutterSecureStorage`, displays a red SnackBar (*"Session expired. Please log in again."*), and redirects the user back to `LoginScreen`.

---

## 🛠️ UI & Layout Fixes

1. **RenderFlex Overflow Fix**:
   - Fixed `RenderFlex` bottom overflow in `company_profile_screen.dart` title bar by wrapping flex items with `Expanded`/`Flexible`.
2. **`SmartSkeleton.list` Overflow Fix**:
   - Wrapped skeleton items with `Flexible` in `lib/core/widgets/skeleton/smart_skeleton.dart`.
3. **Logout Dialog Contrast & Text Styling**:
   - Updated logout confirmation dialogs and buttons in `worker_profile_screen.dart` and `company_home_screen.dart`.
   - Set explicit white background (`backgroundColor: Colors.white`) and high contrast dark/red text (`AppColors.dark`, `AppColors.error`).
4. **API Base URL Configuration**:
   - Updated `ApiConfig.baseUrl` in `lib/core/api/api_config.dart` to the Render backend endpoint: `https://constructor-backend-bhah.onrender.com/api/v1`.
5. **Job Seeker Notifications Screen Redesign**:
   - Overhauled `NotificationsScreen` to harmonize with BuildHire's visual design system (white AppBar, dark text, peach/orange accents, and rounded cards).
   - Streamlined interface by keeping focus on content category filter chips (*All, Applications, Messages*).
   - Built modern `NotificationCard` with category tags, custom icon colors, and "NEW" pill indicators.
   - Added role-aware direct redirection for all notification types:
     - Applications ➡️ [`MyJobsScreen(initialFilter: applied)`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/jobs/my_jobs_screen.dart) for Job Seekers / [`CompanyHomeScreen(initialTabIndex: 1)`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart) for Employers
     - Jobs ➡️ [`HomePage(initialNavIndex: 1)`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/home/home_page.dart) (Jobs Tab) / [`CompanyHomeScreen(initialTabIndex: 2)`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart) (Site Jobs)
     - Messages ➡️ [`MessagesScreen`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/messages/messages_screen.dart) with back navigation / [`CompanyHomeScreen(initialTabIndex: 4)`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart) (Company Chats)
     - General / Announcements ➡️ [`NotificationDetailsSheet`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/notifications/widgets/notification_details_sheet.dart) full message reader
   - Updated `HomeAppBar` to only display the orange unread dot when unread notifications actually exist.

---

## 📁 Modified & Created Files

| File | Purpose |
| :--- | :--- |
| [`lib/screens/auth/company_register_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/auth/company_register_screen.dart) | Company Sign-up Screen (Email + Password) |
| [`lib/screens/auth/company_login_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/auth/company_login_screen.dart) | Company Login Screen |
| [`lib/screens/company/company_profile_form_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_profile_form_screen.dart) | Company Profile Onboarding Form |
| [`lib/screens/company/company_profile_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_profile_screen.dart) | Company Profile Display Screen |
| [`lib/screens/company/company_home_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart) | Employer Portal Dashboard & Actions |
| [`lib/features/repositories/company_repository.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/features/repositories/company_repository.dart) | Complete Company API Repository |
| [`lib/core/api/api_client.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/core/api/api_client.dart) | Global Dio API Client & 401 Session Interceptor |
| [`lib/main.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/main.dart) | Root App & Global Navigator Key |
| [`lib/core/api/api_config.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/core/api/api_config.dart) | API Configuration & Base URL |
| [`lib/screens/profile/worker_profile_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/profile/worker_profile_screen.dart) | Logout Dialog Styling Fix |
| [`lib/core/widgets/skeleton/smart_skeleton.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/core/widgets/skeleton/smart_skeleton.dart) | Skeleton Overflow Fix |
| [`lib/screens/notifications/notifications_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/notifications/notifications_screen.dart) | Redesigned Notifications Screen to match App Design System |
| [`lib/screens/notifications/widgets/notification_card.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/notifications/widgets/notification_card.dart) | Card container with type-specific color palette and badges |
| [`lib/screens/notifications/widgets/notification_details_sheet.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/notifications/widgets/notification_details_sheet.dart) | Interactive modal bottom sheet with contextual actions |
| [`lib/screens/home/widgets/home_app_bar.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/home/widgets/home_app_bar.dart) | Dynamic unread notification dot badge |
