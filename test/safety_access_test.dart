import 'package:dermaire_app/access_control.dart';
import 'package:dermaire_app/chatbot.dart';
import 'package:dermaire_app/doctor_portal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('doctor access is limited to authorized and consented patients', () {
    final session = AccessSession(
      userId: 'doctor-1',
      role: UserRole.doctor,
      authorizedPatientIds: const {'patient-1'},
      exportConsentPatientIds: const {'patient-1'},
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(
      AccessControl.allows(
        session,
        Permission.viewAuthorizedPatient,
        patientId: 'patient-1',
      ),
      isTrue,
    );
    expect(
      AccessControl.allows(
        session,
        Permission.viewAuthorizedPatient,
        patientId: 'patient-2',
      ),
      isFalse,
    );
    expect(
      AccessControl.allows(
        session,
        Permission.exportPatientData,
        patientId: 'patient-2',
      ),
      isFalse,
    );
  });

  test('expired sessions and patient roles cannot use doctor permissions', () {
    final expired = AccessSession(
      userId: 'doctor-1',
      role: UserRole.doctor,
      authorizedPatientIds: const {'patient-1'},
      expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    const patient = AccessSession(userId: 'patient-1', role: UserRole.patient);
    expect(
      AccessControl.allows(
        expired,
        Permission.addClinicalNote,
        patientId: 'patient-1',
      ),
      isFalse,
    );
    expect(AccessControl.allows(patient, Permission.addClinicalNote), isFalse);
  });

  test('clinical notes require authorization, content and an open record', () {
    const session = AccessSession(
      userId: 'doctor-1',
      role: UserRole.doctor,
      authorizedPatientIds: {'patient-1'},
    );
    final controller = DoctorWorkspaceController(session);
    const allowed = DoctorPatient(
      id: 'patient-1',
      name: 'Demo Patient',
      lastCheckIn: 'Today',
      experiment: 'Baseline',
      priority: PatientPriority.routine,
      activeProducts: 1,
    );
    const closed = DoctorPatient(
      id: 'patient-1',
      name: 'Closed Demo Patient',
      lastCheckIn: 'Today',
      experiment: 'Complete',
      priority: PatientPriority.routine,
      activeProducts: 1,
      fileClosed: true,
    );
    expect(controller.addNote(allowed, 'short'), isFalse);
    expect(
      controller.addNote(allowed, 'Reviewed trend and requested follow-up.'),
      isTrue,
    );
    expect(controller.audit['patient-1'], hasLength(1));
    expect(
      controller.addNote(closed, 'This should never change a closed record.'),
      isFalse,
    );
  });

  test('chatbot escalates red flags and avoids diagnosis language', () {
    final emergency = SkinAssistantSafety.reply(
      'I have difficulty breathing and facial swelling',
    );
    expect(emergency.kind, AssistantReplyKind.escalation);
    expect(emergency.text, contains('emergency services'));

    final ordinary = SkinAssistantSafety.reply(
      'What does this measurement mean?',
    );
    expect(ordinary.kind, AssistantReplyKind.education);
    expect(ordinary.text.toLowerCase(), contains('not a diagnosis'));
  });
}
