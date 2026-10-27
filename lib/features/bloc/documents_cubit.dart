import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/models.dart';
import '../repositories/worker_repository.dart';
import 'worker_blocs.dart';

/// Cubit for managing documents state (CRUD operations).
class DocumentsCubit extends Cubit<LoadState<List<DocumentModel>>> {
  DocumentsCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;

  void reset() => emit(const Idle());

  /// Seed documents from profile if not yet loaded or empty.
  void seedFromProfile(WorkerProfile profile) {
    final list = <DocumentModel>[];
    for (final m in profile.documents) {
      list.add(DocumentModel.fromJson(m));
    }
    if (profile.resumeUrl != null &&
        profile.resumeUrl!.isNotEmpty &&
        !list.any((d) => d.isResume)) {
      list.insert(
        0,
        DocumentModel(
          id: 'profile_resume',
          type: 'resume',
          fileName: 'Resume.pdf',
          fileUrl: profile.resumeUrl,
          verificationStatus: 'verified',
        ),
      );
    }
    if (list.isNotEmpty) {
      if (state is! Loaded<List<DocumentModel>> ||
          (state as Loaded<List<DocumentModel>>).data.isEmpty) {
        emit(Loaded(list));
      }
    }
  }

  /// Load all documents for the current user.
  Future<void> load({bool silent = false}) async {
    if (!silent && state is! Loaded<List<DocumentModel>>) {
      emit(const Loading());
    }
    try {
      final raw = await _repo.fetchDocuments();
      if (raw.isNotEmpty) {
        final docs = raw.map((d) => DocumentModel.fromJson(Map<String, dynamic>.from(d))).toList();
        emit(Loaded(docs));
      } else if (state is! Loaded<List<DocumentModel>>) {
        emit(const Loaded([]));
      }
    } catch (e) {
      if (state is! Loaded<List<DocumentModel>>) {
        emit(Failed(e.toString()));
      }
    }
  }

  /// Upload a new document.
  Future<DocumentModel?> upload({
    required List<int> bytes,
    required String filename,
    required String type,
  }) async {
    try {
      final isResumeType = type.toLowerCase() == 'resume' || type.toLowerCase() == 'cv';
      if (isResumeType) {
        final existingResumes = resumes;
        for (final old in existingResumes) {
          if (old.id.isNotEmpty && old.id != 'profile_resume') {
            try {
              await _repo.deleteDocument(old.id);
            } catch (_) {}
          }
        }
      }

      final result = await _repo.uploadDocument(
        bytes: bytes,
        filename: filename,
        type: type,
      );

      Map<String, dynamic> cleanResult = Map<String, dynamic>.from(result);
      if (cleanResult['data'] is Map) {
        cleanResult = Map<String, dynamic>.from(cleanResult['data'] as Map);
      }
      if (cleanResult['type'] == null || cleanResult['type'].toString().isEmpty) {
        cleanResult['type'] = type;
      }
      if (cleanResult['fileName'] == null && cleanResult['originalFilename'] == null) {
        cleanResult['fileName'] = filename;
      }

      final doc = DocumentModel.fromJson(cleanResult);

      // Optimistically update the cubit state immediately!
      final currentDocs = state is Loaded<List<DocumentModel>>
          ? List<DocumentModel>.from((state as Loaded<List<DocumentModel>>).data)
          : <DocumentModel>[];

      if (isResumeType) {
        currentDocs.removeWhere((d) => d.isResume);
        currentDocs.insert(0, doc);
      } else {
        currentDocs.removeWhere((d) => d.id == doc.id && doc.id.isNotEmpty);
        currentDocs.add(doc);
      }
      emit(Loaded(currentDocs));

      // Attempt silent sync with backend without losing our freshly uploaded doc
      try {
        final raw = await _repo.fetchDocuments();
        if (raw.isNotEmpty) {
          final serverDocs = raw.map((d) => DocumentModel.fromJson(Map<String, dynamic>.from(d))).toList();
          if (isResumeType && !serverDocs.any((d) => d.isResume)) {
            serverDocs.insert(0, doc);
          }
          emit(Loaded(serverDocs));
        }
      } catch (_) {}

      return doc;
    } catch (e) {
      // ignore: avoid_print
      print('❌ [DocumentsCubit.upload] error: $e');
      return null;
    }
  }

  /// Delete a document by ID.
  Future<bool> delete(String documentId) async {
    final success = await _repo.deleteDocument(documentId);
    if (success) {
      await load(silent: true);
    }
    return success;
  }

  /// Single active resume getter (only one resume can exist at a time).
  DocumentModel? get activeResume {
    if (state is Loaded<List<DocumentModel>>) {
      return (state as Loaded<List<DocumentModel>>)
          .data
          .where((d) => d.isResume)
          .firstOrNull;
    }
    return null;
  }

  /// Get all resumes from loaded documents.
  List<DocumentModel> get resumes {
    if (state is Loaded<List<DocumentModel>>) {
      return (state as Loaded<List<DocumentModel>>)
          .data
          .where((d) => d.isResume)
          .toList();
    }
    return [];
  }

  /// Get all non-resume documents.
  List<DocumentModel> get certificates {
    if (state is Loaded<List<DocumentModel>>) {
      return (state as Loaded<List<DocumentModel>>)
          .data
          .where((d) => !d.isResume)
          .toList();
    }
    return [];
  }
}
