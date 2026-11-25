import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../login_page.dart';
import 'doctor_monitoring_page.dart';
import 'wellbeing_service.dart';

class _PatientsColors {
  static const primaryGreen = Color(0xFF226A27);
  static const deepGreen = Color(0xFF123F16);
  static const pageBackground = Color(0xFFEDF5ED);
  static const stripeRow = Color(0xFFF3F8F3);
  static const rowHover = Color(0xFFDCEEDC);
  static const focusRing = Color(0xFF7BC47F);
  static const textPrimary = Color(0xFF0F1A10);
  static const textMuted = Color(0xFF4B5B4C);
  static const white = Color(0xFFFFFFFF);
}

class DoctorPatientListPage extends StatefulWidget {
  const DoctorPatientListPage({super.key});

  @override
  State<DoctorPatientListPage> createState() => _DoctorPatientListPageState();
}

class _DoctorPatientListPageState extends State<DoctorPatientListPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _patientsFuture;
  String _searchQuery = '';

  bool get _isPsychologist => LoginPage.userType.trim().toLowerCase() == 'psy';

  @override
  void initState() {
    super.initState();
    _patientsFuture = LoginPage.isClinician
        ? WellbeingService.getDoctorPatients()
        : Future.value(const []);
  }

  void _reloadPatients() {
    if (!LoginPage.isClinician) return;
    setState(() {
      _patientsFuture = WellbeingService.getDoctorPatients();
    });
  }

  String _value(Map<String, dynamic> patient, String key) {
    final value = patient[key];
    return value == null || value.toString().trim().isEmpty
        ? '-'
        : value.toString();
  }

  void _openMonitoring(BuildContext context, Map<String, dynamic> patient) {
    final patientId = _value(patient, 'pat_id');
    if (patientId == '-') return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorMonitoringPage(
          patientId: patientId,
          patientProfile: Map<String, dynamic>.from(patient),
        ),
      ),
    );
  }

  DataRow _buildPatientRow(
      BuildContext context, Map<String, dynamic> patient, int index) {
    final patientId = _value(patient, 'pat_id');
    final hasPatientId = patientId != '-';
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return _PatientsColors.rowHover;
        }
        return index.isOdd ? _PatientsColors.stripeRow : _PatientsColors.white;
      }),
      cells: [
        DataCell(Text('${index + 1}',
            style: const TextStyle(color: _PatientsColors.textMuted))),
        DataCell(Text(_value(patient, 'name'),
            style: const TextStyle(color: _PatientsColors.textPrimary))),
        DataCell(
          _PatientIdPill(
            patientId: patientId,
            onTap:
                hasPatientId ? () => _openMonitoring(context, patient) : null,
          ),
        ),
        DataCell(Text(_value(patient, 'appointment_date'),
            style: const TextStyle(color: _PatientsColors.textMuted))),
        DataCell(Text(_value(patient, 'entry_date'),
            style: const TextStyle(color: _PatientsColors.textMuted))),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPsychologist = _isPsychologist;

    if (!LoginPage.isClinician) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Monitoring')),
        body: const Center(
          child: Text(
              'Only doctors and psychologists can access patient monitoring.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _PatientsColors.pageBackground,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: _PatientsColors.primaryGreen,
        foregroundColor: _PatientsColors.white,
        elevation: 0,
        titleSpacing: 8,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Patients',
                style: GoogleFonts.nunitoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _PatientsColors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: SizedBox(
                  height: 48,
                  child: _PatientsSearchField(
                    controller: _searchController,
                    query: _searchQuery,
                    hintText: 'Search all patients',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _reloadPatients,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh patients',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: _PatientsColors.primaryGreen),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to load patients.',
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w700,
                          color: _PatientsColors.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                            color: _PatientsColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                        onPressed: _reloadPatients,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final allPatients = snapshot.data ?? const <Map<String, dynamic>>[];
          final query = _searchQuery.trim().toLowerCase();
          final patients = query.isEmpty
              ? allPatients
              : allPatients.where((patient) {
                  return _value(patient, 'name')
                          .toLowerCase()
                          .contains(query) ||
                      _value(patient, 'pat_id').toLowerCase().contains(query);
                }).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1216),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPsychologist
                                ? 'All Patients'
                                : 'Assigned Patients',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _PatientsColors.deepGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a patient to review and update monitoring information.',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: _PatientsColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (patients.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          allPatients.isEmpty
                              ? isPsychologist
                                  ? 'No patients are currently available.'
                                  : 'No patients are currently available in your assigned list.'
                              : 'No patients match your search.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunitoSans(
                            color: _PatientsColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1216),
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 2,
                            color: _PatientsColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shadowColor: _PatientsColors.deepGreen
                                .withOpacity(0.1),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  horizontalMargin: 20,
                                  columnSpacing: 24,
                                  dataRowMinHeight: 52,
                                  dataRowMaxHeight: 64,
                                  headingRowHeight: 54,
                                  headingRowColor: const WidgetStatePropertyAll(
                                      _PatientsColors.deepGreen),
                                  headingTextStyle: GoogleFonts.nunitoSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _PatientsColors.white,
                                  ),
                                  dataTextStyle: GoogleFonts.nunitoSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: _PatientsColors.textPrimary,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: SizedBox(
                                        width: 52,
                                        child: Text('SNo'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 180,
                                        child: Text('Patient Name'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 140,
                                        child: Text('Patient ID'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 170,
                                        child: Text('Appointment Date'),
                                      ),
                                    ),
                                    DataColumn(
                                      label: SizedBox(
                                        width: 180,
                                        child: Text('Registration Date'),
                                      ),
                                    ),
                                  ],
                                  rows: patients
                                      .asMap()
                                      .entries
                                      .map((entry) => _buildPatientRow(
                                          context, entry.value, entry.key))
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PatientsSearchField extends StatefulWidget {
  const _PatientsSearchField({
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_PatientsSearchField> createState() => _PatientsSearchFieldState();
}

class _PatientsSearchFieldState extends State<_PatientsSearchField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      child: Container(
        decoration: BoxDecoration(
          color: _PatientsColors.white,
          borderRadius: BorderRadius.circular(999),
          border: _hasFocus
              ? Border.all(color: _PatientsColors.focusRing, width: 3)
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _PatientsColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.nunitoSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _PatientsColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _PatientsColors.primaryGreen),
            suffixIcon: widget.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: widget.onClear,
                    icon: const Icon(Icons.close_rounded),
                    color: _PatientsColors.textMuted,
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}

class _PatientIdPill extends StatefulWidget {
  const _PatientIdPill({required this.patientId, required this.onTap});

  final String patientId;
  final VoidCallback? onTap;

  @override
  State<_PatientIdPill> createState() => _PatientIdPillState();
}

class _PatientIdPillState extends State<_PatientIdPill> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;
    return Semantics(
      button: widget.onTap != null,
      label: 'Open patient ${widget.patientId}',
      child: Tooltip(
        message: 'Open patient ${widget.patientId}',
        child: MouseRegion(
          cursor: widget.onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Material(
            color: isActive
                ? _PatientsColors.deepGreen
                : _PatientsColors.primaryGreen,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (pressed) =>
                  setState(() => _isPressed = pressed),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(
                  widget.patientId,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _PatientsColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
