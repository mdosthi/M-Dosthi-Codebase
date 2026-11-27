import 'package:flutter/material.dart';
import '../theme/brand_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../login_page.dart';
import 'doctor_monitoring_page.dart';
import 'wellbeing_service.dart';

class _PatientsColors {
  static const primaryGreen = BrandColors.teal;
  static const deepGreen = BrandColors.navy;
  static const pageBackground = BrandColors.pageBg;
  static const stripeRow = BrandColors.ice;
  static const rowHover = BrandColors.cyanBg;
  static const textPrimary = BrandColors.navy;
  static const textMuted = BrandColors.mutedInk;
  static const white = Colors.white;
}

class DoctorPatientListPage extends StatefulWidget {
  const DoctorPatientListPage({super.key});

  @override
  State<DoctorPatientListPage> createState() => _DoctorPatientListPageState();
}

class _DoctorPatientListPageState extends State<DoctorPatientListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalTableController = ScrollController();
  late Future<List<Map<String, dynamic>>> _patientsFuture;
  String _searchQuery = '';
  double _horizontalScrollProgress = 0;

  bool get _isPsychologist => LoginPage.userType.trim().toLowerCase() == 'psy';

  @override
  void initState() {
    super.initState();
    _patientsFuture = LoginPage.isClinician
        ? WellbeingService.getDoctorPatients()
        : Future.value(const []);
    _horizontalTableController.addListener(_updateHorizontalScrollProgress);
  }

  void _updateHorizontalScrollProgress() {
    if (!_horizontalTableController.hasClients) return;
    final position = _horizontalTableController.position;
    final maxExtent = position.maxScrollExtent;
    final progress =
        maxExtent <= 0 ? 0.0 : (position.pixels / maxExtent).clamp(0.0, 1.0);
    if ((progress - _horizontalScrollProgress).abs() > 0.01) {
      setState(() => _horizontalScrollProgress = progress);
    }
  }

  void _setHorizontalScrollProgress(double progress) {
    if (!_horizontalTableController.hasClients) return;
    final position = _horizontalTableController.position;
    _horizontalTableController.jumpTo(position.maxScrollExtent * progress);
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

  String _compactDate(String value) {
    String format(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${(date.year % 100).toString().padLeft(2, '0')}';

    if (value.length >= 10 && value[4] == '-' && value[7] == '-') {
      final date = DateTime.tryParse(value.substring(0, 10));
      if (date != null) return format(date);
    }

    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return format(date);
  }

  Widget _buildCompactMobileTable(List<Map<String, dynamic>> patients) {
    final headerStyle = GoogleFonts.nunitoSans(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: _PatientsColors.white,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: _PatientsColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _PatientsColors.deepGreen,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Patient', style: headerStyle)),
                Expanded(flex: 5, child: Text('ID', style: headerStyle)),
                Expanded(flex: 3, child: Text('Appt.', style: headerStyle)),
                Expanded(flex: 3, child: Text('Reg.', style: headerStyle)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: patients.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: BrandColors.borderSubtle,
              ),
              itemBuilder: (context, index) => _buildCompactMobilePatientRow(
                  context, patients[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMobilePatientRow(
      BuildContext context, Map<String, dynamic> patient, int index) {
    final patientId = _value(patient, 'pat_id');
    final textStyle = GoogleFonts.nunitoSans(
      fontSize: 10,
      color: _PatientsColors.textPrimary,
    );

    return Container(
      color: index.isOdd ? _PatientsColors.stripeRow : _PatientsColors.white,
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 9,
                    color: _PatientsColors.textMuted,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    _value(patient, 'name'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _PatientIdPill(
                patientId: patientId,
                compact: true,
                onTap: patientId == '-'
                    ? null
                    : () => _openMonitoring(context, patient),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _compactDate(_value(patient, 'appointment_date')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _compactDate(_value(patient, 'entry_date')),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePatientCards(List<Map<String, dynamic>> patients) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: _PatientsColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemCount: patients.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: BrandColors.borderSubtle,
        ),
        itemBuilder: (context, index) {
          final patient = patients[index];
          final patientId = _value(patient, 'pat_id');
          return Container(
            color:
                index.isOdd ? _PatientsColors.stripeRow : _PatientsColors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMobilePatientField(
                        'Patient',
                        Text(
                          '${index + 1}. ${_value(patient, 'name')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            color: _PatientsColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMobilePatientField(
                        'Patient ID',
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _PatientIdPill(
                            patientId: patientId,
                            compact: true,
                            onTap: patientId == '-'
                                ? null
                                : () => _openMonitoring(context, patient),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildMobilePatientField(
                        'Appointment',
                        Text(
                          _compactDate(_value(patient, 'appointment_date')),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            color: _PatientsColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMobilePatientField(
                        'Registration',
                        Text(
                          _compactDate(_value(patient, 'entry_date')),
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            color: _PatientsColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobilePatientField(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunitoSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _PatientsColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        value,
      ],
    );
  }

  @override
  void dispose() {
    _horizontalTableController.removeListener(_updateHorizontalScrollProgress);
    _horizontalTableController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPsychologist = _isPsychologist;
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isMobile = screenWidth < 600;
    final isCompactHeight = screenSize.height < 500;
    final useCompactColumns =
        isMobile || (isCompactHeight && screenWidth < 900);

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
        backgroundColor: _PatientsColors.deepGreen,
        foregroundColor: _PatientsColors.white,
        elevation: 0,
        titleSpacing: 8,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: BrandColors.heroHeaderGradient,
          ),
        ),
        title: Row(
          children: [
            if (!isMobile)
              Expanded(
                child: Text(
                  'Patients',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _PatientsColors.white,
                  ),
                ),
              )
            else
              const SizedBox(width: 0),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 210 : 340),
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
          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 12 : 32,
                    isCompactHeight ? 12 : (isMobile ? 16 : 32),
                    isMobile ? 12 : 32,
                    useCompactColumns ? 16 : 92,
                  ),
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
                                  fontSize: isMobile ? 22 : 26,
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
                      SizedBox(height: isMobile ? 12 : 20),
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
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (useCompactColumns) {
                                    final useCards =
                                        constraints.maxWidth < 320 ||
                                            MediaQuery.textScalerOf(context)
                                                    .scale(1) >
                                                1.15;
                                    return useCards
                                        ? _buildMobilePatientCards(patients)
                                        : _buildCompactMobileTable(patients);
                                  }

                                  return Card(
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
                                      controller: _horizontalTableController,
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          horizontalMargin: 20,
                                          columnSpacing: 24,
                                          dataRowMinHeight: 52,
                                          dataRowMaxHeight: 64,
                                          headingRowHeight: 54,
                                          headingRowColor:
                                              const WidgetStatePropertyAll(
                                                  _PatientsColors.deepGreen),
                                          headingTextStyle:
                                              GoogleFonts.nunitoSans(
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
                                                child:
                                                    Text('Registration Date'),
                                              ),
                                            ),
                                          ],
                                          rows: patients
                                              .asMap()
                                              .entries
                                              .map((entry) => _buildPatientRow(
                                                  context,
                                                  entry.value,
                                                  entry.key))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (patients.isNotEmpty && !useCompactColumns)
                Positioned(
                  left: isMobile ? 10 : 16,
                  right: isMobile ? 10 : 16,
                  bottom: isMobile ? 6 : 8,
                  child: SafeArea(
                    top: false,
                    child: _HorizontalScrollControls(
                      progress: _horizontalScrollProgress,
                      onChanged: _setHorizontalScrollProgress,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HorizontalScrollControls extends StatefulWidget {
  const _HorizontalScrollControls({
    required this.progress,
    required this.onChanged,
  });

  final double progress;
  final ValueChanged<double> onChanged;

  @override
  State<_HorizontalScrollControls> createState() =>
      _HorizontalScrollControlsState();
}

class _HorizontalScrollControlsState extends State<_HorizontalScrollControls> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final thumbWidth = (trackWidth * 0.16).clamp(44.0, 104.0);
          final thumbTravel = trackWidth - thumbWidth;
          final thumbLeft = thumbTravel * widget.progress.clamp(0.0, 1.0);

          void updateFromPointer(Offset localPosition) {
            if (thumbTravel <= 0) return;
            final nextProgress =
                ((localPosition.dx - thumbWidth / 2) / thumbTravel)
                    .clamp(0.0, 1.0);
            widget.onChanged(nextProgress);
          }

          return Semantics(
            label: 'Horizontal table scrollbar',
            value: '${(widget.progress * 100).round()} percent',
            onIncrease: () =>
                widget.onChanged((widget.progress + 0.1).clamp(0.0, 1.0)),
            onDecrease: () =>
                widget.onChanged((widget.progress - 0.1).clamp(0.0, 1.0)),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                _isDragging = true;
                updateFromPointer(event.localPosition);
              },
              onPointerMove: (event) {
                if (_isDragging) updateFromPointer(event.localPosition);
              },
              onPointerUp: (_) => _isDragging = false,
              onPointerCancel: (_) => _isDragging = false,
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: Center(
                  child: SizedBox(
                    width: trackWidth,
                    height: 12,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Positioned(
                          left: thumbLeft,
                          top: 0,
                          bottom: 0,
                          width: thumbWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const accentPurple = Color(0xFF7C3AED);
    const tealInk = Color(0xFF008F83);
    final borderColor = _hasFocus
        ? accentPurple
        : _isHovered
            ? const Color(0xFF8D61E9)
            : const Color(0xFF9B75E8);

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9FC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: _hasFocus ? 2 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
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
                  color: tealInk,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: BrandColors.blue,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 48, minHeight: 46),
                suffixIcon: widget.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: widget.onClear,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: tealInk,
                        style: IconButton.styleFrom(
                          shape: const CircleBorder(),
                        ),
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientIdPill extends StatefulWidget {
  const _PatientIdPill({
    required this.patientId,
    required this.onTap,
    this.compact = false,
  });

  final String patientId;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<_PatientIdPill> createState() => _PatientIdPillState();
}

class _PatientIdPillState extends State<_PatientIdPill> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;
    final patientIdText = Text(
      widget.patientId,
      maxLines: widget.compact ? 1 : null,
      overflow: TextOverflow.clip,
      style: GoogleFonts.nunitoSans(
        fontSize: widget.compact ? 10 : 14,
        fontWeight: FontWeight.w600,
        color: _PatientsColors.white,
      ),
    );
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
          child: Container(
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [
                        BrandColors.navyDark,
                        BrandColors.navy,
                      ],
                    )
                  : BrandColors.ctaGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (pressed) =>
                    setState(() => _isPressed = pressed),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.compact ? 6 : 14,
                    vertical: widget.compact ? 4 : 6,
                  ),
                  child: widget.compact
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: patientIdText,
                        )
                      : patientIdText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
