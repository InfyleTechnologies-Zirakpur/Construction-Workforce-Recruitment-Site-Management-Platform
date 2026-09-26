# Missing — Seeker + Company (Simple)

> `construction_workforce_recruitment_site_management_platform` — what’s not there yet

## Screens
- [ ] `screens/auth/company_login_screen.dart` — company email/pass login
- [ ] `screens/company/post_job_screen.dart` — POST /jobs
- [ ] `screens/company/applicants_screen.dart` — GET /applications?role=company + shortlist
- [ ] `screens/company/company_profile_screen.dart` — POST /companies full 15 fields

## Data / Repositories
- [ ] `features/repositories/company_repository.dart` — POST /companies, POST /jobs, GET /applications (company)
- [ ] `features/repositories/worker_repository.dart` — still DummyApiInterceptor, no Authorization header

## Providers (Bloc)
- [ ] `features/bloc/company_jobs_cubit.dart` — CompanyJobsCubit
- [ ] `features/bloc/applicants_cubit.dart` — shortlist + chat
- [ ] `features/bloc/worker_blocs.dart` — JobsCubit not sending skill/location filters to real GET /jobs

## Core
- [ ] `core/api/api_config.dart` — still https://api.buildhire.example/v1 + useDummyApi=true
- [ ] `core/api/api_client.dart` — Authorization Bearer not attached, no refresh POST /auth/users/:id/refresh
