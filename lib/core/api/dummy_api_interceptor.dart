import 'dart:async';
import 'package:dio/dio.dart';

/// In-memory backend. It preserves the same URL, method and JSON contract as
/// the real API, so switching to production is just [ApiConfig.useDummyApi].
class DummyApiInterceptor extends Interceptor {
  final List<Map<String, dynamic>> _jobs = [
    {
      'id': 'job_1',
      'title': 'Site Electrician',
      'company': 'Vertex Builders',
      'location': 'Bathinda, Punjab',
      'dailyPay': 850,
      'skills': ['Electrical', 'Wiring'],
      'saved': false,
      'applied': false,
      'projectType': 'Full-time',
      'experienceLevel': 'Experienced',
    },
    {
      'id': 'job_2',
      'title': 'Steel Fixer',
      'company': 'Skyline Infra',
      'location': 'Chandigarh',
      'dailyPay': 900,
      'skills': ['Rebar', 'Safety'],
      'saved': true,
      'applied': false,
      'projectType': 'Contract',
      'experienceLevel': 'Any',
    },
    {
      'id': 'job_3',
      'title': 'Mason',
      'company': 'Metro Build Group',
      'location': 'Ludhiana',
      'dailyPay': 750,
      'skills': ['Brickwork', 'Plaster'],
      'saved': false,
      'applied': true,
      'projectType': 'Daily Wage',
      'experienceLevel': 'Fresher',
    },
  ];
  final List<Map<String, dynamic>> _attendance = [];
  final List<Map<String, dynamic>> _applications = [];
  final List<Map<String, dynamic>> _conversations = [
    {'id': 'conv_1', 'company': 'Vertex Builders', 'jobTitle': 'Site Electrician', 'lastMessage': 'Can you join the site visit tomorrow?', 'lastMessageAt': '10:32 AM', 'unreadCount': 2, 'messages': [{'id':'m1','text':'Hello Ravi, we reviewed your application.','isMine':false,'time':'10:20 AM'}, {'id':'m2','text':'Thank you. I am interested in the role.','isMine':true,'time':'10:25 AM'}, {'id':'m3','text':'Can you join the site visit tomorrow?','isMine':false,'time':'10:32 AM'}]},
    {'id': 'conv_2', 'company': 'Skyline Infra', 'jobTitle': 'Steel Fixer', 'lastMessage': 'Please share your availability.', 'lastMessageAt': 'Yesterday', 'unreadCount': 0, 'messages': [{'id':'m4','text':'Please share your availability.','isMine':false,'time':'Yesterday'}]},
  ];
  final List<Map<String, dynamic>> _notifications = [
    {'id': 'note_1', 'title': 'New electrician job near you', 'body': 'Vertex Builders posted a Site Electrician role in Bathinda.', 'type': 'job', 'time': '10 min ago', 'isRead': false},
    {'id': 'note_2', 'title': 'Application received', 'body': 'Skyline Infra is reviewing your Steel Fixer application.', 'type': 'application', 'time': '2 hours ago', 'isRead': false},
    {'id': 'note_3', 'title': 'Attendance reminder', 'body': 'Remember to check out before leaving the project site.', 'type': 'attendance', 'time': 'Yesterday', 'isRead': true},
  ];
  final Map<String, dynamic> _profile = {
    'name': 'Ravi Kumar',
    'phone': '9876543210',
    'city': 'Bathinda, Punjab',
    'skills': ['Electrician', 'Safety Training'],
    'profilePhotoUrl': null,
    'documents': <Map<String, dynamic>>[],
    'salaryExpectation': '₹900/day',
  };

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final method = o.method.toUpperCase();
    final path = o.path;
    dynamic data;
    if (path == '/auth/request-otp' && method == 'POST')
      data = {'otpSent': true, 'message': 'OTP sent successfully'};
    else if (path == '/auth/verify-otp' && method == 'POST')
      data = {'accessToken': 'dummy-worker-token', 'worker': _profile};
    else if (path == '/auth/reset-password' && method == 'POST')
      data = {'changed': true};
    else if (path == '/jobs' && method == 'GET')
      data = {'items': _jobs, 'total': _jobs.length};
    else if (path == '/conversations' && method == 'GET')
      data = {'items': _conversations};
    else if (path == '/notifications' && method == 'GET')
      data = {'items': _notifications};
    else if (path.startsWith('/notifications/') && method == 'PATCH') {
      final notification = _notifications.firstWhere((item) => item['id'] == path.split('/')[2]);
      notification['isRead'] = true;
      data = notification;
    }
    else if (path.startsWith('/conversations/') && path.endsWith('/messages') && method == 'POST') {
      final conversation = _conversations.firstWhere((item) => item['id'] == path.split('/')[2]);
      final text = Map<String, dynamic>.from(o.data)['text'] as String;
      (conversation['messages'] as List).add({'id': 'm_${DateTime.now().millisecondsSinceEpoch}', 'text': text, 'isMine': true, 'time': 'Now'});
      conversation['lastMessage'] = text;
      conversation['lastMessageAt'] = 'Now';
      data = {'sent': true};
    }
    else if (path.startsWith('/jobs/') &&
        path.endsWith('/save') &&
        method == 'POST') {
      final job = _find(path);
      job['saved'] = !job['saved'];
      data = job;
    } else if (path.startsWith('/jobs/') &&
        path.endsWith('/applications') &&
        method == 'POST') {
      final job = _find(path);
      job['applied'] = true;
      // Optional applicant details (experience, summary, etc). The current
      // WorkerRepository.apply(id) call may not send a body yet — this
      // route accepts one if/when it does, without breaking the existing
      // no-body call.
      final details = o.data is Map ? Map<String, dynamic>.from(o.data) : <String, dynamic>{};
      final application = {
        'id': 'app_${job['id']}',
        'jobId': job['id'],
        'status': 'pending',
        ...details,
      };
      _applications.add(application);
      data = application;
    } else if (path == '/profile' && method == 'GET')
      data = _profile;
    else if (path == '/profile' && method == 'PUT') {
      _profile.addAll(Map<String, dynamic>.from(o.data));
      data = _profile;
    } else if (path == '/profile/photo' && method == 'POST') {
      _profile['profilePhotoUrl'] = 'https://dummy.buildhire.app/profile-photo.jpg';
      data = {'profilePhotoUrl': _profile['profilePhotoUrl']};
    } else if (path == '/documents' && method == 'POST') {
      final document = {
        'id': 'doc_${(_profile['documents'] as List).length + 1}',
        'type': 'identity_document',
        'name': 'Uploaded document',
        'verificationStatus': 'pending',
      };
      (_profile['documents'] as List).add(document);
      data = document;
    } else if (path == '/attendance/check-in' && method == 'POST') {
      final a = {
        'date': '2026-08-03',
        'checkIn': '09:05 AM',
        'checkOut': null,
        'hours': '0h 00m',
      };
      _attendance.insert(0, a);
      data = a;
    } else if (path == '/attendance/check-out' && method == 'POST') {
      final a = _attendance.isEmpty ? null : _attendance.first;
      if (a == null)
        return h.reject(
          DioException(requestOptions: o, message: 'Check in first'),
        );
      a['checkOut'] = '06:12 PM';
      a['hours'] = '9h 07m';
      data = a;
    } else if (path == '/attendance' && method == 'GET')
      data = {'items': _attendance};
    else if (path == '/dashboard' && method == 'GET')
      data = {
        'activeProjects': 1,
        'appliedJobs': 1,
        'workingHours': '42h 30m',
        'attendance': '24 days',
        'notifications': [
          'Your profile is 80% complete',
          'New electrician job near you',
        ],
      };
    else
      return h.reject(
        DioException(
          requestOptions: o,
          response: Response(
            requestOptions: o,
            statusCode: 404,
            data: {'message': 'Dummy route not found: $method $path'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    h.resolve(
      Response(
        requestOptions: o,
        statusCode: 200,
        data: {'success': true, 'message': 'Success', 'data': data},
      ),
    );
  }

  Map<String, dynamic> _find(String path) =>
      _jobs.firstWhere((j) => j['id'] == path.split('/')[2]);
}
