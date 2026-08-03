import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> apply(String id) async {
    await _repo.apply(id);
    await load();
  }

  Future<void> save(String id) async {
    await _repo.save(id);
    await load();
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

class AuthCubit extends Cubit<LoadState<bool>> {
  AuthCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> requestOtp(String phone) async {
    emit(const Loading());
    try {
      await _repo.requestOtp(phone);
      emit(const Loaded(true));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(const Loading());
    try {
      await _repo.verifyOtp(phone: phone, otp: otp);
      emit(const Loaded(true));
    } catch (e) {
      emit(Failed(e.toString()));
    }
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
  Future<void> load() async { emit(const Loading()); try { emit(Loaded(await _repo.notifications())); } catch (e) { emit(Failed(e.toString())); } }
  Future<void> markRead(String id) async { await _repo.markNotificationRead(id); await load(); }
}
