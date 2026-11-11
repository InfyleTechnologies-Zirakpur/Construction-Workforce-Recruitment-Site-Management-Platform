# Sub Contractor Migration & Architecture Guide

> **Document Status**: Active  
> **Last Updated**: November 11, 2026  
> **Target Platform**: Flutter Mobile App & Backend API Integration  
> **Scope**: Complete rebranding and architectural transition from "Company" to "Sub Contractor".

---

## 1. Overview & Context

The platform requirements transitioned from using the generic term **"Company"** to **"Sub Contractor"**. 

To deliver this across the product without breaking live APIs, database records, JWT auth tokens, or NestJS class-validators, we adopted **Solution 1 (The Non-Breaking Production Pattern)**.

### Architectural Strategy
1. **Frontend / UI**: 100% of the user experience, screens, dialogs, forms, placeholders, headers, and messages display **"Sub Contractor"**.
2. **Database Record**: Profile submissions explicitly persist `"businessType": "Sub Contractor"` in the database record (`companies` table/collection).
3. **Internal Backend Auth**: The system authentication key remains `'company'` (with fallback support for `'subcontractor'` / `'sub_contractor'`), satisfying the backend's strict DTO validation (`@IsIn(['company'])`) without requiring emergency backend deployments or database table alterations.

---

## 2. Database Specification (`businessType`)

When a Sub Contractor registers or updates their profile via `POST /companies` or `PATCH /companies/:id`:

```json
{
  "name": "Vertex Builders",
  "contactEmail": "contact@vertexbuilders.com",
  "contactPhone": "9876543210",
  "businessType": "Sub Contractor",
  "specializations": ["Electrical", "Wiring", "Civil Work"],
  "description": "Sub contractor specialized in site electrical infrastructure.",
  "teamSizeRange": "10-50"
}
```

* **Default Enforcement**: In `CompanyRepository.createCompanyProfile()`, if `businessType` is missing or empty, it automatically defaults to `"Sub Contractor"`.
* **Form Defaults**: In `CompanyProfileFormScreen`, the dropdown defaults to `'Sub Contractor'`.

---

## 3. Complete File Change Registry

### A. Repositories & Profile Forms
| File Path | Changes Made |
| :--- | :--- |
| `lib/screens/company/company_profile_form_screen.dart` | Added `'Sub Contractor'` to `_businessTypes`, defaulted `_businessType` to `'Sub Contractor'`, updated UI headings (*"Register Sub Contractor Profile"*, *"Sub Contractor Description"*, *"Sub Contractor Name"*). |
| `lib/features/repositories/company_repository.dart` | Enforced default `'businessType': 'Sub Contractor'` in `createCompanyProfile()`. |

### B. Authentication & Onboarding
| File Path | Changes Made |
| :--- | :--- |
| `lib/screens/auth/choose_role_screen.dart` | Role card title changed to **"Sub Contractor"**. |
| `lib/screens/auth/company_login_screen.dart` | AppBar title updated to **"Sub Contractor Login"**, hint to `name@subcontractor.com`, footer to *"Don't have a sub contractor account? Sign Up"*, blocked account message updated to *"This sub contractor account has been blocked"*. |
| `lib/screens/auth/company_register_screen.dart` | Multi-step progress bar updated to **"Sub Contractor Info"**, name field to **"Sub Contractor / Contact Name *"**, email to **"Official Sub Contractor Email *"**, header titles to **"Sub Contractor Registration"** and **"Sub Contractor Sign Up"**. |
| `lib/screens/auth/login_screen.dart` | Bottom portal link updated to **"Sub Contractor login with email"**. |
| `lib/screens/auth/job_seeker_register_screen.dart` | Bottom portal link updated to **"Sub Contractor portal with email"**. |

### C. Sub Contractor Portal & Management
| File Path | Changes Made |
| :--- | :--- |
| `lib/screens/company/company_home_screen.dart` | Logout confirmation dialog updated to *"Log Out Sub Contractor?"*. |
| `lib/screens/company/company_profile_screen.dart` | Fallback company name changed to `'Sub Contractor'`, verification badge changed to `'Verified Sub Contractor'`, action buttons changed to *"Edit Sub Contractor Details"*, *"About Sub Contractor"*, and *"Log Out Sub Contractor"*. |
| `lib/screens/company/widgets/company_post_job_sheet.dart` | Pre-check dialogs updated to *"Sub Contractor Profile Required"*. |
| `lib/screens/settings/settings_screen.dart` | Section 1 header changed to **"SUB CONTRACTOR"**, tile changed to **"Sub Contractor Profile"**, and Privacy/Terms dialogs updated from "company" to "sub contractor". |

### D. Job Seeker, Search, Chat & Feed Screens
| File Path | Changes Made |
| :--- | :--- |
| `lib/screens/search/search_screen.dart` | Search input placeholder updated to `'Job title, keywords or sub contractor'`. |
| `lib/screens/home/widgets/home_search_bar.dart` | Search bar placeholder updated to `'Job title, keywords or sub contractor'`. |
| `lib/screens/home/widgets/home_job_card.dart` | Card contractor fallback changed from `'Verified Contractor'` to `'Verified Sub Contractor'`. |
| `lib/features/jobs/apply_job_screen.dart` | Cover note hint updated to *"Tell the sub contractor why you are a good fit for this role..."*, experience summary updated to *"Previous Sub Contractor"*. |
| `lib/screens/profile/complete_profile_screen.dart` | Work experience section and field labels updated to *"Sub Contractor / Employer Name"*. |
| `lib/screens/profile/widgets/edit_profile_sheet.dart` | Experience label and hint updated to *"Sub Contractor / Site"*. |
| `lib/screens/resume/create_resume_screen.dart` | Work experience label updated to *"Sub Contractor / Employer Name *"*. |
| `lib/screens/messages/chat_screen.dart` | Empty chat placeholder updated to *"Waiting for sub contractor to send the first message"*, conversation lock note updated to *"Only the sub contractor can initiate the conversation..."*. |
| `lib/screens/feed/feed_screen.dart` | **Sub Contractor Feed Redesign**: Implemented custom `_buildSubContractorFeed()` with warm amber/gold gradient banner (*"Welcome Back! 🙏"*, *"Explore new opportunities and stay updated"*), section header (*"Company Feed"* with dynamic *"3 New Jobs"* pill), interactive proposal submission bottom sheet, and integration with `SubContractorDummyData`. Replaced blue theme with warm amber. |
| `lib/screens/feed/widgets/tender_feed_card.dart` | **New Component**: Created `TenderFeedCard` matching Company Tender mockup cards (avatar with company initials, time ago, green *"Job"* badge, project title, description, 2x2 metadata grid for location, budget, deadline, category, amber *"Apply Now"* button, bookmark toggle button, and applicant count). Includes `onBackgroundImageError` safe network image handling. |
| `lib/screens/feed/widgets/feed_post_card.dart` | **Redesigned Post Card**: Styled to match Sharma Construction mockup card: amber circular avatar with white initials (`SC`), author name, timestamp, subtle horizontal divider line, body text, and minimal bottom action row (outline heart + like count, outline chat bubble + comment count, and outline share icon). Added `onBackgroundImageError` safe network image handling. |
| `lib/screens/feed/widgets/feed_comments_sheet.dart` | Comment author fallback changed from `'Company'` to `'Sub Contractor'`. |
| `lib/screens/notifications/notifications_screen.dart` | Empty notification state message updated to *"When sub contractors update applications or post matching jobs, they will appear here."*. |

### E. Models, Cubits & Themes
| File Path | Changes Made |
| :--- | :--- |
| `lib/core/models/models.dart` | Default fallback job company name changed to `'Sub Contractor'`. |
| `lib/core/models/company_model.dart` | Fallback model name changed from `'Company'` to `'Sub Contractor'`. |
| `lib/features/bloc/feed_cubit.dart` | Local author name/role fallbacks updated to `'Sub Contractor'` / `'Verified Sub Contractor'`. |
| `lib/core/constants/app_colors.dart` | Added `subContractorPrimary`, `subContractorSurface`, `subContractorBorder`, etc. aliases. |
| `lib/core/theme/app_theme.dart` | Added `AppTheme.subContractorTheme(context)` alias. |
| Role Check Inclusivity | Updated `splash_screen.dart`, `notifications_screen.dart`, `create_feed_screen.dart`, and `feed_screen.dart` to check `role == 'company' || role == 'subcontractor' || role == 'sub_contractor'`. |

### F. Work Leads Screen & Navigation Hierarchy
| File Path | Changes Made |
| :--- | :--- |
| `lib/core/data/sub_contractor_dummy_data.dart` | **Centralized Mock Data Store**: Consolidated all mock/dummy records for the Sub Contractor experience into a single file (Work Leads, Feed Tenders, and Community Posts) with `WorkLeadItem.fromJson()` deserialization for instant backend API connection. |
| `lib/screens/company/work_leads_screen.dart` | Created new **Work Leads** screen featuring opportunities available count, status tabs (*Active*, *Applied*, *Saved*, *Rejected*), with enlarged typography, clean horizontal scrolling without bottom track lines, 2x2 details grid (location, budget, deadline, trade category), proposal submission sheet (*"Apply Now"*), bookmarking (*"Save"* / *"Remove"*), and the **Advanced Filters** modal. Styled strictly in warm amber/gold theme. |
| `lib/screens/company/company_home_screen.dart` | Updated main navigation hierarchy: **Removed `Post` action tab and replaced it with `Chat`**. Current tab order: **1. Home (`FeedScreen`)**, **2. Work (`WorkLeadsScreen`)**, **3. Chat (`CompanyChatsView`)**, **4. Hiring (`CompanyHiringView`)**, **5. Settings (`SettingsScreen`)**. Preserved top `CompanyAppBar` across main tabs while hiding it on the Settings tab to avoid stacked duplicate headers. |
| `lib/screens/notifications/notifications_screen.dart` | Aligned notification redirect indices with the new bottom navigation bar layout. |

---

## 4. Centralized Dummy Data Store & Future API Integration Guide

To ensure that mock data does not clutter UI screens and can be replaced with real backend endpoints in minutes, all dummy data for Sub Contractors is stored in a single centralized hub:

📁 **Location**: [`lib/core/data/sub_contractor_dummy_data.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/core/data/sub_contractor_dummy_data.dart)

### What Is in This File?
1. **`WorkLeadItem` Model**: Complete data model representing tenders/work leads, supporting status, budget, category, location, proposal fields, rejection feedback, and `fromJson` serialization.
2. **`SubContractorDummyData.getInitialWorkLeads()`**: The mock dataset powering `WorkLeadsScreen` across all 4 status tabs (*Active (3)*, *Applied (2)*, *Saved (1)*, *Rejected (1)*).
3. **`SubContractorDummyData.getInitialFeedTenders()`**: The mock company tenders displayed in `FeedScreen`.
4. **`SubContractorDummyData.getSampleFeaturedPost()`**: The featured Sharma Construction sub contractor post.

---

### Step-by-Step: How to Connect Live Backend APIs

When the backend development team has the Tender / Work Leads APIs deployed:

#### Step 1: Fetching Work Leads
Open `lib/core/data/sub_contractor_dummy_data.dart` and update `getInitialWorkLeads()` or add:
```dart
static Future<List<WorkLeadItem>> fetchWorkLeads({String? status}) async {
  final response = await ApiClient.instance.dio.get(
    '/sub-contractors/work-leads',
    queryParameters: {if (status != null) 'status': status},
  );
  final items = response.data['data'] is List 
      ? response.data['data'] 
      : response.data['data']?['items'] ?? [];
  return (items as List).map((j) => WorkLeadItem.fromJson(j)).toList();
}
```

#### Step 2: Submitting a Proposal ("Apply Now")
Call the application endpoint:
```dart
static Future<bool> submitProposal({
  required String leadId,
  required String quote,
  required String timeline,
  String? notes,
}) async {
  final response = await ApiClient.instance.dio.post(
    '/sub-contractors/work-leads/$leadId/proposals',
    data: {
      'quotedPrice': quote,
      'estimatedTimeline': timeline,
      if (notes != null) 'notes': notes,
    },
  );
  return response.statusCode == 200 || response.statusCode == 201;
}
```

#### Step 3: Bookmarking / Saving Leads
```dart
static Future<bool> toggleSaveLead(String leadId) async {
  final response = await ApiClient.instance.dio.post(
    '/sub-contractors/work-leads/$leadId/save',
  );
  return response.statusCode == 200;
}
```

#### Step 4: Feed Tenders
```dart
static Future<List<TenderJobItem>> fetchFeedTenders() async {
  final response = await ApiClient.instance.dio.get('/sub-contractors/feed/tenders');
  final items = response.data['data'] is List ? response.data['data'] : [];
  return (items as List).map((t) => TenderJobItem.fromJson(t)).toList();
}
```

---

## 5. Sub Contractor Feed Screen Architecture & UI Specifications

The Home / Feed screen for Sub Contractors (`_buildSubContractorFeed()` in `lib/screens/feed/feed_screen.dart`) was redesigned to match the company tender & workforce ecosystem:

### Key Components & Layout:

1. **Top Greeting Banner**:
   - **Gradient**: Replaced the mockup's royal blue with the warm amber/gold palette (`LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])`).
   - **Text**: *"Welcome Back! 🙏"* (20px bold white), Subtitle: *"Explore new opportunities and stay updated"* (13px white/90%).
   - Rounded corners (`BorderRadius.circular(20)`), soft amber drop shadow.

2. **Section Header**:
   - Section Title: **"Company Feed"** (20px bold `Color(0xFF0F172A)`).
   - Count Pill on right: **"${tenders.length} New Jobs"** (light amber tint container `Color(0xFFFEF3C7)` with bold amber text `Color(0xFFD97706)`).

3. **Sub Contractor Community Post Card (`FeedPostCard`)**:
   - Created based on the **Sharma Construction** mockup card.
   - **Header**: Amber circle avatar with white initials (`SC`), author name in bold, `2 hours ago` timestamp.
   - **Divider**: Subtle horizontal divider line (`Color(0xFFF1F5F9)`) separating the header from the content.
   - **Typography**: 14.5px clean body text with auto-expanding *"View more / View less"* for long text.
   - **Action Bar**:
     - Outline heart (`Icons.favorite_border_rounded`) + like count (`24`).
     - Outline chat bubble (`Icons.chat_bubble_outline_rounded`) + comment count (`8`).
     - Outline share icon (`Icons.share_outlined`) aligned to the right.
   - **Safe Network Image Loading**: Added `onBackgroundImageError` to gracefully fall back to initials if CDN images fail or return 403.

4. **Company Tender / Job Card (`TenderFeedCard`)**:
   - Matches the Metro Developers, Green Valley Homes, and Food Ventures India cards from the design.
   - **Header**: Circular avatar with company initials (e.g. `MD`, `GV`, `FV`), company name, time ago, and green **"Job"** status pill badge (`#DCFCE7` background, `#16A34A` text).
   - **Project Scope**: Large project title + description container.
   - **2x2 Metadata Grid**:
     - 📍 **Location**: *e.g., Sector 56, Gurgaon / Cyber City, Gurugram*
     - 💰 **Budget Range**: *e.g., ₹8,00,000 - ₹12,00,000*
     - 🕒 **Deadline**: *e.g., May 15, 2026*
     - 💼 **Trade / Category**: *e.g., HVAC / Electrical / Plumbing*
   - **Action Row**:
     - Amber **"Apply Now"** button (`AppColors.companyPrimary` `#F7B532`), launches the Proposal Submission modal.
     - Rounded **Bookmark / Save** icon button with amber active state.
     - **Applicant Count**: *e.g., "14 applicants" / "8 applicants"*.

5. **Proposal Submission Modal ("Apply Now")**:
   - Interactive bottom sheet allowing Sub Contractors to submit:
     - Proposed quote price (₹).
     - Estimated completion timeline.
     - Cover note / team capabilities.
   - On submission, marks the item as *"Applied ✓"* with green theme and gives immediate visual confirmation.

---

## 6. Future Roadmap & Backend Migration (Optional Phase 2)

If the backend development team wishes to transition the raw database column `users.role` from `'company'` to `'sub_contractor'` in the future, follow these steps:

### Backend Updates Required:
1. **`src/common/types/role.enum.ts`**:
   ```typescript
   export type UserRole =
     | 'admin'
     | 'job_seeker'
     | 'company'
     | 'contractor'
     | 'sub_contractor'  
     | 'site_engineer';
   ```
2. **`src/modules/auth/dto/company-signup-send-otp.dto.ts`**:
   ```typescript
   @IsIn(['company', 'sub_contractor'], {
     message: "Only 'company' or 'sub_contractor' role can use this signup",
   })
   role: string = 'company';
   ```
3. **`src/modules/auth/dto/register-user.dto.ts`**:
   Add `'sub_contractor'` to the `@IsEnum` array.

4. **Database Migration**:
   Update existing `users` rows where `role = 'company'` to `role = 'sub_contractor'` (if a full historical migration is desired).

> **Note**: Because the Flutter client code already supports `role == 'company' || role == 'subcontractor' || role == 'sub_contractor'`, the mobile app will immediately and seamlessly work with the new role without any breaking changes!

---

## 7. Maintenance & Update Log

Future updates to this migration should be logged below:

| Date | Author / Contributor | Changes Summary |
| :--- | :--- | :--- |
| **2026-11-11** | Engineering Team | Initial migration complete: All UI rebranded to "Sub Contractor", `businessType: "Sub Contractor"` enforced in profile payloads, backwards compatibility maintained with backend. |
| **2026-11-11** | Engineering Team | Redesigned Sub Contractor Feed: Added warm amber gradient banner ("Welcome Back!"), Company Feed section ("3 New Jobs"), `TenderFeedCard` with proposal flow, and Sharma Construction `FeedPostCard`. |
| **2026-11-11** | Engineering Team | Added Work Leads screen with Advanced Filters & Proposal Submission. Updated Sub Contractor navigation to replace Post with Chat (Home, Work, Chat, Hiring, Settings). |
| **2026-11-11** | Engineering Team | Consolidated all mock/dummy data into `lib/core/data/sub_contractor_dummy_data.dart`. Added Saved View with dynamic "Remove" button, 4-tab filter (Active, Applied, Saved, Rejected) with enlarged typography and no track lines. Documented backend API connection steps. |
| **2026-11-11** | Engineering Team | Unified top navigation bar across all Sub Contractor tabs: Kept main `CompanyAppBar` persistent on Settings tab and eliminated duplicate inner `AppBar` / "Settings" header text. |
| **2026-11-11** | Engineering Team | Removed Posts section from Sub Contractor Profile (`CompanyProfileScreen`): Tab bar reduced to 2 tabs (`Jobs` and `About`), eliminating post tabs and redundant post fetching. |
| **2026-11-11** | Engineering Team | Completely removed post creation option across the entire application: Disconnected all `CreateFeedScreen` invocations, removed dead post methods, and disabled post edit actions. |

---

## 8. Today's Completed Tasks & Changelog (November 11, 2026)

The following is an exhaustive breakdown of all features, redesigns, bug fixes, and architectural improvements completed today:

### 1. Sub Contractor Rebranding & Profile Persistence (Non-Breaking Solution 1)
- **Problem Solved**: System previously used generic "Company" terminology and lacked dedicated business classification for sub contractors.
- **Implementation**:
  - Rebranded 100% of user-facing screens, inputs, placeholders, validation alerts, dialogs, and navigation labels from "Company" to **"Sub Contractor"**.
  - Enforced `businessType: "Sub Contractor"` in [`CompanyRepository.createCompanyProfile()`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/features/repositories/company_repository.dart) and defaulted dropdown in [`CompanyProfileFormScreen`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_profile_form_screen.dart).
  - Maintained complete backwards compatibility with existing NestJS backend auth roles (`'company'`, `'subcontractor'`, `'sub_contractor'`).

### 2. Sub Contractor Home / Feed Screen Redesign
- **Problem Solved**: Mockup required a specialized, branded Sub Contractor Feed that felt tailored to commercial tenders rather than generic social feeds.
- **Implementation**:
  - **Top Welcome Banner**: Added warm amber gradient (`#F59E0B` to `#D97706`) reading *"Welcome Back! 🙏"* and *"Explore new opportunities and stay updated"*.
  - **Company Feed Header**: Added *"Company Feed"* section with a live count badge (*"3 New Jobs"*).
  - **Commercial Tender Cards ([`TenderFeedCard`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/feed/widgets/tender_feed_card.dart))**: Created responsive card matching tender mockups with company initials avatar, green *"Job"* badge, project title, description, 2x2 metadata grid (Location, Budget Range, Deadline, Category), amber *"Apply Now"* button, bookmark toggle, and applicant counts.
  - **Community Post Card ([`FeedPostCard`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/feed/widgets/feed_post_card.dart))**: Refactored to mirror the Sharma Construction post mockup with avatar, subtle divider, typography, and like/comment/share actions.
  - **Proposal Submission Bottom Sheet**: Interactive workflow allowing sub contractors to enter quoted prices, project timelines, and cover notes.

### 3. Work Leads Screen (Full Mockup Replica)
- **Problem Solved**: Sub contractors needed a dedicated workspace to browse and manage commercial project opportunities.
- **Implementation** in [`work_leads_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/work_leads_screen.dart):
  - **Opportunities Header**: Real-time counter showing *"X opportunities available"*.
  - **Enlarged 4-Tab Filter**: Horizontal filter tabs (**Active**, **Applied**, **Saved**, **Rejected**) with 16.5px bold typography.
  - **Removed Horizontal Scroll Track**: Wrapped tab strip in `ScrollbarTheme` with transparent tracks and thumbs to eliminate unsightly scroll track lines across devices.
  - **Dynamic Card Actions**:
    - **Active Tab**: Displays blue/amber *"Apply Now"* and *"Save"* buttons.
    - **Saved Tab**: Exactly mirrors the mockup with a purple status badge (`• Saved: 3 days ago`) and a red outline **"Remove"** button (`#EF4444` border, `#DC2626` text).
    - **Rejected Tab**: Displays red rejection reason container explaining client decision.
  - **Advanced Filters Bottom Sheet**:
    - Project / Company Name search input with magnifying glass icon.
    - Category selection dropdown (Civil, HVAC, Electrical, Plumbing, Fabrication, etc.).
    - Location text field.
    - Min & Max Budget Range inputs with Rupee symbol (`₹`).
    - Reset / *"Clear All"* and *"Apply Filters"* actions.

### 4. Bottom Navigation Hierarchy Overhaul
- **Problem Solved**: The bottom navigation had an obsolete `Post` action tab.
- **Implementation** in [`company_home_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart):
  - Replaced the `Post` tab with **`Chat`**.
  - Final tab order:
    1. **Home (0)**: Sub Contractor Feed (`FeedScreen`)
    2. **Work (1)**: Work Leads & Commercial Tenders (`WorkLeadsScreen`)
    3. **Chat (2)**: Real-time candidate & partner messaging (`CompanyChatsView`)
    4. **Hiring (3)**: Job postings & candidate applications pipeline (`CompanyHiringView`)
    5. **Settings (4)**: Account management & preferences (`SettingsScreen`)

### 5. Centralized Dummy Data Store
- **Problem Solved**: Mock data was previously scattered across screens, making future API integration cumbersome.
- **Implementation** in [`lib/core/data/sub_contractor_dummy_data.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/core/data/sub_contractor_dummy_data.dart):
  - Created a single, centralized data repository containing:
    - `WorkLeadItem` model with robust `fromJson()` deserializer.
    - 6 realistic work leads covering Active, Applied, Saved (with `savedAgo`), and Rejected (with `rejectionReason`).
    - 3 commercial feed tenders (Metro Developers, Green Valley Homes, Food Ventures India).
    - Sample community post for Sharma Construction.
  - Provided comprehensive instructions and ready-to-copy Dio API methods in Section 4 so the backend team can connect live endpoints in minutes.

### 6. App Bar Consistency & Settings Screen Refinement
- **Problem Solved**: Switching to the Settings tab removed the top app bar and showed a duplicate "Settings" title text.
- **Implementation**:
  - In [`company_home_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart), ensured [`CompanyAppBar`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/widgets/company_app_bar.dart) remains visible on **all 5 tabs** (including Settings).
  - In [`settings_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/settings/settings_screen.dart), removed the secondary inner `AppBar` when loaded as a tab (`widget.isTab == true`), eliminating double headers and the extra "Settings" text.

### 7. Streamlined Sub Contractor Profile (Removed Posts Section)
- **Problem Solved**: Sub contractors requested removal of social post management from their internal business profile view.
- **Implementation** in [`company_profile_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_profile_screen.dart):
  - Reduced `DefaultTabController` length from `3` to `2`.
  - Removed `Tab(text: 'Posts (...)')` from the profile tab bar, leaving only **Jobs** and **About**.
  - Removed `_buildPostsTab()` from the `TabBarView`.
  - Removed `_loadPosts()` from profile initialization to prevent unnecessary backend calls.

### 8. Bug Fixes & Stability Hardening
- **CircleAvatar Assertion Failure**: Fixed `_AssertionError ('circle_avatar.dart': backgroundImage != null || onBackgroundImageError == null)` by conditioning error callbacks on `hasValidAvatar`.
- **CDN 403 Forbidden Handling**: Gracefully handled broken or restricted avatar URLs on `construction-site.b-cdn.net` to fall back to clean colored initials instead of crashing or showing broken icons.
- **RenderFlex Overflow in Chat View**: Fixed a 189px overflow bug in `CompanyChatsView` by nesting it inside a scrollable `ListView` under `RefreshIndicator`.

### 9. Complete Elimination of Create Post Options
- **Problem Solved**: Ensured that the application contains no user-accessible pathways, buttons, floating action buttons (FABs), navigation tabs, or dialogs to create feed posts.
- **Implementation**:
  - Removed all `CreateFeedScreen` references, imports, and navigation flows from [`company_home_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_home_screen.dart), [`company_profile_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/company/company_profile_screen.dart), and [`feed_screen.dart`](file:///d:/programs/Construction-Workforce-Recruitment-Site-Management-Platform/lib/screens/feed/feed_screen.dart).
  - Explicitly removed `_openCreatePost()` and `_openEditPost()`.
  - Configured `floatingActionButton: null` across all primary and feed screens.
  - Disabled post editing (`onEditTap: null`) on post cards, preventing any access to edit/create post sheets.

