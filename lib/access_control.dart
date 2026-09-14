enum UserRole { patient, doctor, admin, support }

enum Permission {
  viewOwnHealthData,
  viewAuthorizedPatient,
  addClinicalNote,
  addRecommendation,
  requestFollowUp,
  sendMessage,
  escalateCase,
  viewAuditHistory,
  exportPatientData,
  manageUsers,
}

class AccessSession {
  const AccessSession({
    required this.userId,
    required this.role,
    this.authorizedPatientIds = const {},
    this.exportConsentPatientIds = const {},
    this.expiresAt,
  });

  final String userId;
  final UserRole role;
  final Set<String> authorizedPatientIds;
  final Set<String> exportConsentPatientIds;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
}

abstract final class AccessControl {
  static const rolePermissions = <UserRole, Set<Permission>>{
    UserRole.patient: {Permission.viewOwnHealthData, Permission.sendMessage},
    UserRole.doctor: {
      Permission.viewAuthorizedPatient,
      Permission.addClinicalNote,
      Permission.addRecommendation,
      Permission.requestFollowUp,
      Permission.sendMessage,
      Permission.escalateCase,
      Permission.viewAuditHistory,
      Permission.exportPatientData,
    },
    UserRole.admin: {Permission.manageUsers, Permission.viewAuditHistory},
    UserRole.support: {Permission.sendMessage},
  };

  static bool allows(
    AccessSession session,
    Permission permission, {
    String? patientId,
  }) {
    if (session.isExpired) return false;
    if (!(rolePermissions[session.role]?.contains(permission) ?? false)) {
      return false;
    }
    if (patientId != null && session.role == UserRole.doctor) {
      if (!session.authorizedPatientIds.contains(patientId)) return false;
      if (permission == Permission.exportPatientData) {
        return session.exportConsentPatientIds.contains(patientId);
      }
    }
    return true;
  }
}
