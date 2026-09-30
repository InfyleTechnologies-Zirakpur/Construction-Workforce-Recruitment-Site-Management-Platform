import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/models/models.dart';
import '../repositories/worker_repository.dart';

sealed class LoadState<T> {
  const LoadState();
}

class Idle<T> extends LoadState<T> {
  const Idle();
}

class Loading<T> extends LoadState<T> {
  const Loading();
}

class Loaded<T> extends LoadState<T> {
  const Loaded(this.data);
  final T data;
}

class Failed<T> extends LoadState<T> {
  const Failed(this.message);
  final String message;
}

class JobsCubit extends Cubit<LoadState<List<Job>>> {
  JobsCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load([String? query]) async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.fetchJobs(query: query)));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> apply(String id, {Map<String, dynamic>? details}) async {
    await _repo.apply(id, details: details);
    await load();
  }

  Future<void> save(String id) async {
    await _repo.save(id);
    await load();
  }

  Future<void> withdraw(String applicationId, {String? jobId}) async {
    await _repo.withdrawApplication(applicationId, jobId: jobId);
    await load();
  }

  Future<void> report({required String jobId, required String reason}) async {
    await _repo.reportJob(jobId: jobId, reason: reason);
    // don't necessarily need to reload for a report, but we could.
  }
}

class ProfileCubit extends Cubit<LoadState<WorkerProfile>> {
  ProfileCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.profile()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> update(Map<String, dynamic> body) async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.updateProfile(body)));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }
  Future<String?> uploadPhoto({required List<int> bytes, required String filename}) async {
    try { return await _repo.uploadProfilePhoto(bytes: bytes, filename: filename); } catch (_) { return null; }
  }
  Future<Map<String, dynamic>?> uploadDocument({required List<int> bytes, required String filename, required String type}) async {
    try { return await _repo.uploadDocument(bytes: bytes, filename: filename, type: type); } catch (_) { return null; }
  }
}

class AttendanceCubit extends Cubit<LoadState<List<Attendance>>> {
  AttendanceCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.attendance()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> checkIn() async {
    await _repo.checkIn();
    await load();
  }

  Future<void> checkOut() async {
    await _repo.checkOut();
    await load();
  }
}

class DashboardCubit extends Cubit<LoadState<Map<String, dynamic>>> {
  DashboardCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.dashboard()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }
}

class AuthCubit extends Cubit<LoadState<Map<String, dynamic>>> {
  AuthCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> requestOtp(String phone) async {
    emit(const Loading());
    try {
      await _repo.requestOtp(phone);
      emit(const Loaded(<String, dynamic>{'otpSent': true}));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(const Loading());
    try {
      final data = await _repo.verifyOtp(phone: phone, otp: otp);
      // Persist tokens for ApiClient
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      if (data['accessToken'] != null) await storage.write(key: 'accessToken', value: data['accessToken'].toString());
      if (data['refreshToken'] != null) await storage.write(key: 'refreshToken', value: data['refreshToken'].toString());
      await storage.write(key: 'role', value: 'job_seeker');
      // Persist userId for conversation message ownership detection
      final user = data['worker'] ?? data['user'];
      if (user is Map && user['id'] != null) {
        await storage.write(key: 'userId', value: user['id'].toString());
      }
      emit(Loaded(data));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> logout() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.deleteAll();
    emit(const Idle());
  }
}

class MessagesCubit extends Cubit<LoadState<List<Conversation>>> {
  MessagesCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load() async { emit(const Loading()); try { emit(Loaded(await _repo.conversations())); } catch (e) { emit(Failed(e.toString())); } }
  Future<void> send(String conversationId, String text) async { await _repo.sendMessage(conversationId, text); await load(); }
}

class NotificationsCubit extends Cubit<LoadState<List<WorkerNotification>>> {
  NotificationsCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.notifications()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repo.markNotificationRead(id);
    } catch (_) {}
    await load();
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllNotificationsRead();
    } catch (_) {}
    await load();
  }
}
