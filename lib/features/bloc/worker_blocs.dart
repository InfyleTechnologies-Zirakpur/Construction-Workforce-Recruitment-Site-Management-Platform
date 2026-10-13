import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/models/models.dart';
import '../repositories/worker_repository.dart';

export 'feed_cubit.dart';

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
  void reset() => emit(const Idle());
  Future<void> load([String? query, bool silent = false]) async {
    if (!silent && state is! Loaded<List<Job>>) {
      emit(const Loading());
    }
    try {
      emit(Loaded(await _repo.fetchJobs(query: query)));
    } catch (e) {
      if (state is! Loaded<List<Job>>) {
        emit(Failed(e.toString()));
      }
    }
  }

  Future<void> apply(String id, {Map<String, dynamic>? details}) async {
    final currentState = state;
    if (currentState is Loaded<List<Job>>) {
      final updated = currentState.data.map((j) => j.id == id ? j.copyWith(applied: true) : j).toList();
      emit(Loaded(List.unmodifiable(updated)));
    }
    try {
      await _repo.apply(id, details: details);
    } catch (e) {
      if (currentState is Loaded<List<Job>>) {
        emit(currentState);
      }
      rethrow;
    }
  }

  Future<void> save(String id) async {
    final currentState = state;
    if (currentState is Loaded<List<Job>>) {
      final updated = currentState.data.map((j) => j.id == id ? j.copyWith(saved: true) : j).toList();
      emit(Loaded(List.unmodifiable(updated)));
    }
    try {
      await _repo.save(id);
    } catch (e) {
      if (currentState is Loaded<List<Job>>) {
        emit(currentState);
      }
    }
  }

  Future<void> unsave(String id) async {
    final currentState = state;
    if (currentState is Loaded<List<Job>>) {
      final updated = currentState.data.map((j) => j.id == id ? j.copyWith(saved: false) : j).toList();
      emit(Loaded(List.unmodifiable(updated)));
    }
    try {
      await _repo.unsave(id);
    } catch (e) {
      if (currentState is Loaded<List<Job>>) {
        emit(currentState);
      }
    }
  }

  Future<void> withdraw(String applicationId, {String? jobId}) async {
    final currentState = state;
    if (currentState is Loaded<List<Job>> && jobId != null) {
      final updated = currentState.data.map((j) => j.id == jobId ? j.copyWith(applied: false) : j).toList();
      emit(Loaded(List.unmodifiable(updated)));
    }
    await _repo.withdrawApplication(applicationId, jobId: jobId);
    await load(null, true);
  }

  Future<void> report({required String jobId, required String reason}) async {
    await _repo.reportJob(jobId: jobId, reason: reason);
  }
}

class ProfileCubit extends Cubit<LoadState<WorkerProfile>> {
  ProfileCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
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
      final updatedProfile = await _repo.updateProfile(body);
      try {
        const storage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        if (updatedProfile.name.isNotEmpty) {
          await storage.write(key: 'companyName', value: updatedProfile.name);
          await storage.write(key: 'fullName', value: updatedProfile.name);
          await storage.write(key: 'name', value: updatedProfile.name);
        }
      } catch (_) {}
      emit(Loaded(updatedProfile));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<String?> uploadPhoto({required List<int> bytes, required String filename}) async {
    try {
      return await _repo.uploadProfilePhoto(bytes: bytes, filename: filename);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadDocument({
    required List<int> bytes,
    required String filename,
    required String type,
  }) async {
    try {
      return await _repo.uploadDocument(bytes: bytes, filename: filename, type: type);
    } catch (_) {
      return null;
    }
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
  void reset() => emit(const Idle());
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
      final res = await _repo.requestOtp(phone);
      emit(Loaded(<String, dynamic>{'otpSent': true, ...res}));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(const Loading());
    try {
      try {
        await const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ).deleteAll();
      } catch (_) {}
      final data = await _repo.verifyOtp(phone: phone, otp: otp);
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      if (data['accessToken'] != null) await storage.write(key: 'accessToken', value: data['accessToken'].toString());
      if (data['refreshToken'] != null) await storage.write(key: 'refreshToken', value: data['refreshToken'].toString());
      await storage.write(key: 'role', value: 'job_seeker');
      await storage.write(key: 'phone', value: phone);
      final worker = data['worker'] ?? data['user'];
      bool? completeFlag;
      if (data['isProfileComplete'] is bool) {
        completeFlag = data['isProfileComplete'] as bool;
      } else if (data['isNewUser'] is bool) {
        completeFlag = !(data['isNewUser'] as bool);
      } else if (worker is Map && worker['isProfileComplete'] is bool) {
        completeFlag = worker['isProfileComplete'] as bool;
      } else if (worker is Map && worker['isNewUser'] is bool) {
        completeFlag = !(worker['isNewUser'] as bool);
      }
      if (completeFlag != null) {
        await storage.write(key: 'profileComplete', value: completeFlag.toString());
      }
      final user = data['worker'] ?? data['user'];
      if (user is Map && user['id'] != null) {
        await storage.write(key: 'userId', value: user['id'].toString());
      }
      emit(Loaded(data));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> logout({String? fcmToken}) async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    try {
      String? tokenToSend = fcmToken;
      if (tokenToSend == null || tokenToSend.isEmpty) {
        try {
          tokenToSend = await storage.read(key: 'fcmDeviceToken');
        } catch (_) {}
      }
      await _repo.logout(fcmToken: tokenToSend);
    } catch (_) {}
    try {
      await storage.deleteAll();
    } catch (_) {}
    emit(const Idle());
  }

  void reset() => emit(const Idle());
}

class MessagesCubit extends Cubit<LoadState<List<Conversation>>> {
  MessagesCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());

  Future<void> load({bool silent = false}) async {
    if (!silent && state is! Loaded<List<Conversation>>) {
      emit(const Loading());
    }
    try {
      emit(Loaded(await _repo.conversations()));
    } catch (e) {
      if (state is! Loaded<List<Conversation>>) {
        emit(Failed(e.toString()));
      }
    }
  }

  Future<void> markAsRead(String conversationId) async {
    final currentState = state;
    if (currentState is Loaded<List<Conversation>>) {
      final updated = currentState.data.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(unreadCount: 0);
        }
        return c;
      }).toList();
      emit(Loaded(List.unmodifiable(updated)));
    }
    try {
      await _repo.markConversationRead(conversationId);
    } catch (_) {}
  }

  Future<void> send(String conversationId, String text) async {
    await _repo.sendMessage(conversationId, text);
    await load(silent: true);
  }
}

class NotificationsCubit extends Cubit<LoadState<List<WorkerNotification>>> {
  NotificationsCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
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
