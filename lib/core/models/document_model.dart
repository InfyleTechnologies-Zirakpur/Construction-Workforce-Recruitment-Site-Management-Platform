
class DocumentModel {
  final String id;
  final String? userId;
  final String? entityType;
  final String? entityId;
  final String? objectKey;
  final String type;
  final String? originalFilename;
  final String? fileName;
  final String? fileUrl;
  final String? mimeType;
  final int? sizeBytes;
  final String? verificationStatus;
  final DateTime? uploadedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentModel({
    required this.id,
    this.userId,
    this.entityType,
    this.entityId,
    this.objectKey,
    required this.type,
    this.originalFilename,
    this.fileName,
    this.fileUrl,
    this.mimeType,
    this.sizeBytes,
    this.verificationStatus,
    this.uploadedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// The best display name for this document.
  String get displayName =>
      originalFilename ?? fileName ?? '${type.replaceAll('_', ' ')} document';

  /// Whether this is a resume or CV type.
  bool get isResume {
    final t = type.toLowerCase().trim();
    if (t == 'resume' || t == 'cv') return true;
    if (objectKey?.toLowerCase().contains('/resume/') == true) return true;
    final fn = (originalFilename ?? fileName ?? '').toLowerCase();
    if (fn.contains('resume') || fn.contains('cv')) return true;
    final url = (fileUrl ?? '').toLowerCase();
    if (url.contains('/resume/') || url.contains('resume')) return true;
    return false;
  }

  /// Whether this document is verified.
  bool get isVerified => verificationStatus?.toLowerCase() == 'verified';

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> j = json;
    if (j['data'] is Map) {
      j = Map<String, dynamic>.from(j['data'] as Map);
    }
    return DocumentModel(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      userId: j['userId']?.toString() ?? j['ownerId']?.toString() ?? j['entityId']?.toString(),
      entityType: j['entityType']?.toString(),
      entityId: j['entityId']?.toString(),
      objectKey: j['objectKey']?.toString(),
      type: j['type']?.toString() ?? 'other',
      originalFilename: j['originalFilename']?.toString() ??
          j['originalName']?.toString() ??
          j['fileName']?.toString() ??
          j['name']?.toString(),
      fileName: j['fileName']?.toString() ??
          j['name']?.toString() ??
          j['originalFilename']?.toString(),
      fileUrl: j['fileUrl']?.toString() ?? j['url']?.toString() ?? j['path']?.toString(),
      mimeType: j['mimeType']?.toString(),
      sizeBytes: j['sizeBytes'] is num
          ? (j['sizeBytes'] as num).toInt()
          : (j['size'] is num ? (j['size'] as num).toInt() : null),
      verificationStatus: j['verificationStatus']?.toString(),
      uploadedAt: j['uploadedAt'] != null
          ? DateTime.tryParse(j['uploadedAt'].toString())
          : (j['createdAt'] != null
              ? DateTime.tryParse(j['createdAt'].toString())
              : null),
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
      updatedAt: j['updatedAt'] != null
          ? DateTime.tryParse(j['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      if (entityType != null) 'entityType': entityType,
      if (entityId != null) 'entityId': entityId,
      'type': type,
      if (originalFilename != null) 'originalFilename': originalFilename,
      if (fileName != null) 'fileName': fileName,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (mimeType != null) 'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (verificationStatus != null)
        'verificationStatus': verificationStatus,
    };
  }
}
