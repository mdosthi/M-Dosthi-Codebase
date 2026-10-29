import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../login_page.dart';
import 'wellbeing_service.dart';

class DoctorMonitoringPage extends StatefulWidget {
  const DoctorMonitoringPage({
    super.key,
    required this.patientId,
    this.patientProfile = const {},
  });

  final String patientId;
  final Map<String, dynamic> patientProfile;

  @override
  State<DoctorMonitoringPage> createState() => _DoctorMonitoringPageState();
}

class _DoctorMonitoringPageState extends State<DoctorMonitoringPage> {
  final TextEditingController _therapyPreviousController =
      TextEditingController();
  final TextEditingController _therapyNewController = TextEditingController();
  final TextEditingController _therapyReasonController =
      TextEditingController();
  final TextEditingController _metastasisNotesController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _metastasisStateController =
      TextEditingController();

  String _distressStatus = 'Not assessed';
  String _distressMessage =
      'No distress assessment is available for this patient.';
  String _selectedAction = 'Reviewed by doctor';
  List<Map<String, dynamic>> _therapyHistory = [];
  List<Map<String, dynamic>> _metastasisHistory = [];
  List<Map<String, dynamic>> _problemList = [];
  bool _isLoading = true;

  String _patientValue(String key) {
    final value = widget.patientProfile[key];
    return value == null || value.toString().trim().isEmpty
        ? 'Not provided'
        : value.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadMonitoringData();
  }

  Future<void> _loadMonitoringData() async {
    setState(() => _isLoading = true);
    final data = await WellbeingService.getPatientMonitoring(widget.patientId);
    if (!mounted) return;
    setState(() {
      _distressStatus = data['distressStatus'] ?? 'Not assessed';
      _distressMessage = data['distressMessage'] ??
          'No distress assessment is available for this patient.';
      _therapyHistory =
          List<Map<String, dynamic>>.from(data['therapyHistory'] ?? const []);
      _metastasisHistory = List<Map<String, dynamic>>.from(
          data['metastasisHistory'] ?? const []);
      _problemList =
          List<Map<String, dynamic>>.from(data['problemList'] ?? const []);
      _isLoading = false;
    });
  }

  Future<void> _saveTherapyChange() async {
    final previous = _therapyPreviousController.text.trim();
    final next = _therapyNewController.text.trim();
    final reason = _therapyReasonController.text.trim();
    final date = DateTime.now().toIso8601String().split('T').first;

    if (previous.isEmpty || next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter both previous and new therapy details.')),
      );
      return;
    }

    final result = await WellbeingService.createTherapyChange(
      patientId: widget.patientId,
      previousTherapy: previous,
      newTherapy: next,
      reason: reason.isEmpty ? 'No reason provided' : reason,
      date: date,
    );

    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _therapyHistory.insert(0, {
          'previousTherapy': previous,
          'newTherapy': next,
          'reason': reason.isEmpty ? 'No reason provided' : reason,
          'date': date,
        });
      });
      _therapyPreviousController.clear();
      _therapyNewController.clear();
      _therapyReasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapy change saved.')),
      );
    }
  }

  Future<void> _saveMetastasisState() async {
    final state = _metastasisStateController.text.trim();
    final notes = _metastasisNotesController.text.trim();
    if (state.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add the current metastasis state.')),
      );
      return;
    }

    final result = await WellbeingService.createMetastasisState(
      patientId: widget.patientId,
      state: state,
      notes: notes,
      date: DateTime.now().toIso8601String().split('T').first,
    );

    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _metastasisHistory.insert(0, {
          'state': state,
          'notes': notes,
          'date': DateTime.now().toIso8601String().split('T').first,
        });
      });
      _metastasisStateController.clear();
      _metastasisNotesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metastasis state saved.')),
      );
    }
  }

  Future<void> _recordDistressAction() async {
    final result = await WellbeingService.recordDistressAction(
      patientId: widget.patientId,
      action: _selectedAction,
      remarks: _remarksController.text.trim(),
    );

    if (!mounted) return;
    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient monitoring action recorded.')),
      );
    }
  }

  @override
  void dispose() {
    _therapyPreviousController.dispose();
    _therapyNewController.dispose();
    _therapyReasonController.dispose();
    _metastasisNotesController.dispose();
    _remarksController.dispose();
    _metastasisStateController.dispose();
    super.dispose();
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!LoginPage.isClinician) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Monitoring')),
        body: const Center(
          child: Text(
              'Only doctors and psychologists can access patient monitoring.'),
        ),
      );
    }

    final distressColor =
        _distressStatus.toLowerCase() == 'high' ? Colors.red : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Monitoring: ${widget.patientId}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _loadMonitoringData,
            tooltip: 'Refresh monitoring data',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: 'Patient Profile',
                      children: [
                        Text(
                          _patientValue('name'),
                          style: GoogleFonts.outfit(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text('Patient ID: ${widget.patientId}'),
                        Text('Age: ${_patientValue('age')}'),
                        Text('Gender: ${_patientValue('sex')}'),
                        Text(
                            'Appointment: ${_patientValue('appointment_date')}'),
                        Text('Registered: ${_patientValue('entry_date')}'),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Distress Status',
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: distressColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: distressColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _distressStatus,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: distressColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _distressMessage,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Problem List',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_problemList.isEmpty)
                                Text(
                                  'No concerns selected.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                )
                              else
                                ..._problemList.expand((group) {
                                  final concerns = List<String>.from(
                                      group['concerns'] ?? const []);
                                  return [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        group['category']?.toString() ?? '',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    ...concerns.map(
                                      (concern) => Padding(
                                        padding: const EdgeInsets.only(
                                            left: 12, top: 3),
                                        child: Text('• $concern'),
                                      ),
                                    ),
                                  ];
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Doctor action',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedAction,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                          items: const [
                            'Physical meeting recommended',
                            'Follow-up required',
                            'Reviewed by doctor',
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedAction = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Remarks (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _recordDistressAction,
                            icon:
                                const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Save Action'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Therapy Change',
                      children: [
                        TextFormField(
                          controller: _therapyPreviousController,
                          decoration: const InputDecoration(
                              labelText: 'Previous Therapy',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _therapyNewController,
                          decoration: const InputDecoration(
                              labelText: 'New Therapy',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _therapyReasonController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Reason / Remarks',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saveTherapyChange,
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('Save Therapy Change'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                _therapyPreviousController.clear();
                                _therapyNewController.clear();
                                _therapyReasonController.clear();
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('Therapy History',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800)),
                        const SizedBox(height: 8),
                        if (_therapyHistory.isEmpty)
                          Text('No therapy history available yet.',
                              style: GoogleFonts.outfit(
                                  color: Colors.grey.shade600))
                        else
                          ..._therapyHistory.map((entry) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Previous: ${entry['previousTherapy'] ?? '-'}',
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600)),
                                    Text('New: ${entry['newTherapy'] ?? '-'}',
                                        style: GoogleFonts.outfit()),
                                    Text('Reason: ${entry['reason'] ?? '-'}',
                                        style: GoogleFonts.outfit()),
                                    Text('Date: ${entry['date'] ?? '-'}',
                                        style: GoogleFonts.outfit(
                                            color: Colors.grey.shade700)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                    _buildSectionCard(
                      title: 'Metastasis State',
                      children: [
                        TextFormField(
                          controller: _metastasisStateController,
                          decoration: const InputDecoration(
                              labelText: 'Current metastasis state',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _metastasisNotesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Notes / Remarks',
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveMetastasisState,
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text('Save'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('History',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800)),
                        const SizedBox(height: 8),
                        if (_metastasisHistory.isEmpty)
                          Text('No metastasis history available yet.',
                              style: GoogleFonts.outfit(
                                  color: Colors.grey.shade600))
                        else
                          ..._metastasisHistory.map((entry) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('State: ${entry['state'] ?? '-'}',
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600)),
                                    if ((entry['notes'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text('Notes: ${entry['notes']}',
                                          style: GoogleFonts.outfit()),
                                    Text('Date: ${entry['date'] ?? '-'}',
                                        style: GoogleFonts.outfit(
                                            color: Colors.grey.shade700)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
