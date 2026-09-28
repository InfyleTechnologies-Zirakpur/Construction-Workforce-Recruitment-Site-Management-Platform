# Worker API contract

All endpoints return this envelope:

```json
{"success": true, "message": "Success", "data": {}}
```

Errors use `success: false`, `message`, and an optional `errors` object.

| Feature | Method / endpoint | Request body | `data` response |
|---|---|---|---|
| Send OTP | `POST /auth/request-otp` | `{"phone":"9876543210"}` | `{"otpSent":true,"message":"OTP sent successfully"}` |
| Verify OTP / login | `POST /auth/verify-otp` | `{"phone":"9876543210","otp":"123456"}` | `{"accessToken":"jwt","worker":{...}}` |
| Reset password | `POST /auth/reset-password` | `{"phone":"...","otp":"...","newPassword":"..."}` | `{"changed":true}` |
| Jobs (filters) | `GET /jobs?search=&location=&minDailyPay=&skill=&projectType=` | none | `{"items":[Job],"total":24}` |
| Job details | `GET /jobs/{jobId}` | none | `Job` |
| Apply job | `POST /applications/jobs/{jobId}/apply` | `{"coverNote":"..."}` | `{"id":"app_1","jobId":"job_1","status":"pending"}` |
| Saved jobs | `GET /jobs/saved/list` | none | `{"items":[Job]}` |
| Save / remove job | `POST /jobs/{jobId}/save` | none | updated `Job` |
| Applications | `GET /applications?status=pending` | none | `{"items":[{"id":"app_1","status":"pending","job":Job}]}` |
| Profile | `GET /profile` | none | `WorkerProfile` |
| Update profile | `PUT /profile` | `WorkerProfile` fields below | updated `WorkerProfile` |
| Dashboard | `GET /dashboard` | none | `{"activeProjects":1,"appliedJobs":4,"attendance":"24 days","workingHours":"42h 30m","notifications":["..."]}` |
| Check in | `POST /attendance/check-in` | `{"latitude":30.210,"longitude":74.945,"projectId":"project_1"}` | `Attendance` |
| Check out | `POST /attendance/check-out` | same as check in | updated `Attendance` |
| Attendance list | `GET /attendance?month=2026-08` | none | `{"items":[Attendance],"summary":{"days":24,"overtime":"5h"}}` |
| Upload document | `POST /documents` multipart | `file`, `type` (`aadhaar`, `experience`, `skill`) | `Document` |
| Documents | `GET /documents` | none | `{"items":[Document]}` |
| Delete document | `DELETE /documents/{documentId}` | none | `{"deleted":true}` |
| Notifications | `GET /notifications` | none | `{"items":[Notification]}` |
| Mark read | `PATCH /notifications/{id}` | `{"read":true}` | updated `Notification` |

## Core JSON types

```json
// Job
{"id":"job_1","title":"Site Electrician","company":"Vertex Builders","location":"Bathinda, Punjab","dailyPay":850,"skills":["Electrical","Wiring"],"saved":false,"applied":false}

// WorkerProfile (PUT body includes only changed fields)
{"name":"Ravi Kumar","phone":"9876543210","city":"Bathinda, Punjab","skills":["Electrician"],"experience":[{"company":"Vertex","role":"Electrician","years":2}],"education":[{"qualification":"10th pass"}],"salaryExpectation":"₹900/day","preferredLocations":["Bathinda"],"photoUrl":"https://..."}

// Attendance
{"id":"att_1","date":"2026-08-03","checkIn":"09:05 AM","checkOut":"06:12 PM","hours":"9h 07m","overtime":"1h 07m","status":"present"}

// Document
{"id":"doc_1","type":"aadhaar","url":"https://...","verificationStatus":"pending","uploadedAt":"2026-08-03T09:00:00Z"}
```

## Switching from mock to backend

`core/api/dummy_api_interceptor.dart` is an in-memory backend mounted on Dio. It supports the endpoints used by the current UI. Set `ApiConfig.useDummyApi` to `false`, change `ApiConfig.baseUrl`, and add the JWT in `ApiClient`'s request interceptor. Repositories and BLoCs remain unchanged.
