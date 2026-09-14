import 'package:flutter/material.dart';

import 'access_control.dart';
import 'dermaire_theme.dart';
import 'dermaire_widgets.dart';

enum PatientPriority { routine, review, urgent }

class DoctorPatient {
  const DoctorPatient({
    required this.id,
    required this.name,
    required this.lastCheckIn,
    required this.experiment,
    required this.priority,
    required this.activeProducts,
    this.followUp,
    this.fileClosed = false,
  });
  final String id;
  final String name;
  final String lastCheckIn;
  final String experiment;
  final PatientPriority priority;
  final int activeProducts;
  final String? followUp;
  final bool fileClosed;
}

class ClinicalAuditEvent {
  const ClinicalAuditEvent(this.action, this.timestamp);
  final String action;
  final DateTime timestamp;
}

class DoctorWorkspaceController extends ChangeNotifier {
  DoctorWorkspaceController(this.session);
  final AccessSession session;
  bool loading = false;
  String query = '';
  PatientPriority? filter;
  final notes = <String, List<String>>{};
  final audit = <String, List<ClinicalAuditEvent>>{};
  final patients = const [
    DoctorPatient(
      id: 'patient-salma',
      name: 'Salma Ahmed',
      lastCheckIn: 'Today, 8:40 AM',
      experiment: 'Product X · Day 14 of 28',
      priority: PatientPriority.review,
      activeProducts: 3,
      followUp: 'Apr 29',
    ),
    DoctorPatient(
      id: 'patient-nour',
      name: 'Nour Hassan',
      lastCheckIn: 'Yesterday',
      experiment: 'Baseline · 3 of 5 check-ins',
      priority: PatientPriority.routine,
      activeProducts: 2,
    ),
    DoctorPatient(
      id: 'patient-mariam',
      name: 'Mariam Ali',
      lastCheckIn: '3 days ago',
      experiment: 'Experiment paused',
      priority: PatientPriority.urgent,
      activeProducts: 4,
      followUp: 'Overdue',
    ),
  ];

  List<DoctorPatient> get visible => patients.where((patient) {
    if (!AccessControl.allows(
      session,
      Permission.viewAuthorizedPatient,
      patientId: patient.id,
    )) {
      return false;
    }
    if (filter != null && patient.priority != filter) return false;
    return patient.name.toLowerCase().contains(query.trim().toLowerCase());
  }).toList();

  void search(String value) {
    query = value;
    notifyListeners();
  }

  void setFilter(PatientPriority? value) {
    filter = value;
    notifyListeners();
  }

  String? validateNote(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'Enter a clinical note';
    if (cleaned.length < 10) return 'Add enough context for the care record';
    if (cleaned.length > 1500) return 'Keep the note under 1500 characters';
    return null;
  }

  bool addNote(DoctorPatient patient, String value) {
    if (patient.fileClosed ||
        validateNote(value) != null ||
        !AccessControl.allows(
          session,
          Permission.addClinicalNote,
          patientId: patient.id,
        )) {
      return false;
    }
    notes.putIfAbsent(patient.id, () => []).add(value.trim());
    audit
        .putIfAbsent(patient.id, () => [])
        .add(
          ClinicalAuditEvent(
            'Clinical note added by ${session.userId}',
            DateTime.now(),
          ),
        );
    notifyListeners();
    return true;
  }
}

class DoctorSignInScreen extends StatefulWidget {
  const DoctorSignInScreen({super.key});

  @override
  State<DoctorSignInScreen> createState() => _DoctorSignInScreenState();
}

class _DoctorSignInScreenState extends State<DoctorSignInScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final license = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    license.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || loading) return;
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => loading = false);
    const session = AccessSession(
      userId: 'doctor-demo',
      role: UserRole.doctor,
      authorizedPatientIds: {'patient-salma', 'patient-nour', 'patient-mariam'},
      exportConsentPatientIds: {'patient-salma'},
    );
    await openPage(context, DoctorPortalScreen(session: session));
  }

  @override
  Widget build(BuildContext context) => DermairePage(
    eyebrow: 'Clinician workspace',
    title: 'Doctor sign in',
    subtitle:
        'Demo environment — no real clinical records or credentials are used.',
    children: [
      const Notice(
        icon: '🔒',
        text:
            'Production access requires verified identity, MFA, server-side authorization and an audit service.',
        color: DermaireColors.unknownBackground,
      ),
      Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Professional email',
              ),
              validator: (value) => (value ?? '').contains('@')
                  ? null
                  : 'Enter a valid professional email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: license,
              decoration: const InputDecoration(labelText: 'License ID'),
              validator: (value) => (value?.trim().length ?? 0) >= 4
                  ? null
                  : 'Enter a valid license ID',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (loading) const LinearProgressIndicator(),
      FilledButton(
        key: const Key('doctorSignIn'),
        onPressed: loading ? null : submit,
        child: const Text('Open clinician demo'),
      ),
    ],
  );
}

class DoctorPortalScreen extends StatefulWidget {
  const DoctorPortalScreen({super.key, required this.session});
  final AccessSession session;

  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen> {
  late final DoctorWorkspaceController controller = DoctorWorkspaceController(
    widget.session,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.role != UserRole.doctor || widget.session.isExpired) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('You are not authorized to view this workspace.'),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => DermairePage(
        showBack: false,
        eyebrow: 'Doctor dashboard · Demo',
        title: 'Patient reviews',
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
        children: [
          const Notice(
            icon: 'ⓘ',
            text:
                'Demonstration data only. Recommendations require clinician review and patient consent.',
          ),
          SearchBar(
            hintText: 'Search authorized patients',
            leading: const Icon(Icons.search_rounded),
            onChanged: controller.search,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                _filterChip('Routine', PatientPriority.routine),
                _filterChip('Needs review', PatientPriority.review),
                _filterChip('Urgent', PatientPriority.urgent),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (controller.visible.isEmpty)
            const DermaireCard(
              child: Text('No authorized patients match these filters.'),
            )
          else
            ...controller.visible.map(
              (patient) => _PatientCard(
                patient: patient,
                onTap: () => openPage(
                  context,
                  PatientDetailScreen(controller: controller, patient: patient),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, PatientPriority? value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: controller.filter == value,
      onSelected: (_) => controller.setFilter(value),
    ),
  );
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, required this.onTap});
  final DoctorPatient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DermaireCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                patient.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            StatusPill(
              patient.priority.name.toUpperCase(),
              kind: patient.priority == PatientPriority.urgent
                  ? StatusKind.conflict
                  : patient.priority == PatientPriority.review
                  ? StatusKind.warning
                  : StatusKind.safe,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(patient.experiment),
        Text('Last check-in: ${patient.lastCheckIn}'),
        Text(
          '${patient.activeProducts} active products${patient.followUp == null ? '' : ' · Follow-up ${patient.followUp}'}',
        ),
      ],
    ),
  );
}

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({
    super.key,
    required this.controller,
    required this.patient,
  });
  final DoctorWorkspaceController controller;
  final DoctorPatient patient;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final note = TextEditingController();
  String? noteError;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => DermairePage(
      eyebrow: 'Authorized patient · Demo',
      title: widget.patient.name,
      subtitle:
          '${widget.patient.experiment} · Last activity ${widget.patient.lastCheckIn}',
      children: [
        const Row(
          children: [
            Expanded(child: MetricTile('−8%', 'Redness')),
            SizedBox(width: 10),
            Expanded(child: MetricTile('−12%', 'Texture')),
          ],
        ),
        const SizedBox(height: 12),
        _clinicalSection(
          'Baseline',
          '5 comparable check-ins · established Apr 8',
        ),
        _clinicalSection(
          'Products',
          '${widget.patient.activeProducts} active products · interaction status reviewed',
        ),
        _clinicalSection(
          'Journal',
          'Last entry today · hydration good · no severe symptom recorded',
        ),
        _clinicalSection(
          'Report',
          'Latest trend report available for clinician review',
        ),
        TextField(
          key: const Key('clinicalNote'),
          controller: note,
          maxLength: 1500,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Clinical note',
            errorText: noteError,
            helperText:
                'Notes are append-only and recorded in the audit history.',
          ),
        ),
        FilledButton(
          key: const Key('addClinicalNote'),
          onPressed: () {
            final error = widget.controller.validateNote(note.text);
            setState(() => noteError = error);
            if (error != null) return;
            final saved = widget.controller.addNote(widget.patient, note.text);
            if (saved) {
              note.clear();
              showDermaireSnack(
                context,
                'Clinical note added to the audit history.',
              );
            }
          },
          child: const Text('Add clinical note'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showDermaireSnack(
            context,
            'Messaging requires a connected, consented care provider.',
          ),
          icon: const Icon(Icons.message_outlined),
          label: const Text('Message patient'),
        ),
        const SizedBox(height: 18),
        Text('Audit history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...(widget.controller.audit[widget.patient.id] ??
                const <ClinicalAuditEvent>[])
            .map(
              (event) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(event.action),
                subtitle: Text(event.timestamp.toIso8601String()),
              ),
            ),
      ],
    ),
  );

  Widget _clinicalSection(String title, String value) => DermaireCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}
