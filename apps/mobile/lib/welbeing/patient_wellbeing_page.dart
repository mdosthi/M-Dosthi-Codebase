import 'package:flutter/material.dart';
import '../theme/brand_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/language_service.dart';

import '../login_page.dart';
import 'wellbeing_service.dart';

enum WellbeingTab { sleepHygiene, moodActivity }

class PatientWellbeingPage extends StatefulWidget {
  const PatientWellbeingPage({super.key, required this.tab});

  final WellbeingTab tab;

  @override
  State<PatientWellbeingPage> createState() => _PatientWellbeingPageState();
}

class _PatientWellbeingPageState extends State<PatientWellbeingPage> {
  final TextEditingController _sleepDateController = TextEditingController();
  final TextEditingController _bedtimeController = TextEditingController();
  final TextEditingController _wakeUpController = TextEditingController();
  final TextEditingController _sleepDurationController =
      TextEditingController();
  final TextEditingController _nightAwakeningsController =
      TextEditingController();
  final TextEditingController _sleepNotesController = TextEditingController();

  final TextEditingController _moodNotesController = TextEditingController();
  final TextEditingController _activityNotesController =
      TextEditingController();

  String _sleepQuality = 'Good';
  String _difficultySleeping = 'No difficulty';
  String _selectedMood = 'Good';
  String _selectedMoodIntensity = 'Moderate';
  String _selectedActivityCategory = 'Walking';
  String? _selectedActivityDuration;
  String _selectedNightAwakenings = '0 time';
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeUpTime;

  List<Map<String, dynamic>> _sleepRecords = [];
  List<Map<String, dynamic>> _moodRecords = [];
  List<Map<String, dynamic>> _activities = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _sleepDateController.text = _today;
    _loadData();
  }

  String get _today => DateTime.now().toIso8601String().split('T').first;

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _updateSleepDuration() {
    final bedtime = _bedtime;
    final wakeUpTime = _wakeUpTime;
    if (bedtime == null || wakeUpTime == null) return;

    var minutes = (wakeUpTime.hour * 60 + wakeUpTime.minute) -
        (bedtime.hour * 60 + bedtime.minute);
    if (minutes <= 0) minutes += 24 * 60;
    _sleepDurationController.text = '${minutes ~/ 60}h ${minutes % 60}m';
  }

  Future<void> _pickSleepTime({required bool bedtime}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: bedtime
          ? (_bedtime ?? const TimeOfDay(hour: 22, minute: 0))
          : (_wakeUpTime ?? const TimeOfDay(hour: 6, minute: 0)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (bedtime) {
        _bedtime = selected;
        _bedtimeController.text = _formatTime(selected);
      } else {
        _wakeUpTime = selected;
        _wakeUpController.text = _formatTime(selected);
      }
      _updateSleepDuration();
    });
  }

  Widget _sleepTimeTile({required bool bedtime}) {
    final value = bedtime ? _bedtimeController.text : _wakeUpController.text;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _pickSleepTime(bedtime: bedtime),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          alignment: Alignment.centerLeft,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          children: [
            Icon(bedtime ? Icons.bedtime_rounded : Icons.wb_sunny_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bedtime ? 'Bedtime' : 'Wake up',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  Text(value.isEmpty ? 'Choose time' : value,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleepChoiceChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: BrandColors.navy.withOpacity(0.14),
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
    );
  }

  bool _toBool(dynamic value) {
    return WellbeingService.normalizeBool(value);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final patientId =
        LoginPage.userId.isNotEmpty ? LoginPage.userId : 'patient-01';
    final sleep = await WellbeingService.getSleepRecords(patientId);
    final mood = await WellbeingService.getMoodRecords(patientId);
    final activities = await WellbeingService.getActivities(patientId);

    setState(() {
      _sleepRecords = sleep;
      _moodRecords = mood;
      _activities = activities.map((entry) {
        final normalized = Map<String, dynamic>.from(entry);
        normalized['completed'] = _toBool(normalized['completed']);
        return normalized;
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _saveSleepRecord() async {
    if (_bedtime == null || _wakeUpTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select bedtime and wake-up time.')),
      );
      return;
    }
    final patientId =
        LoginPage.userId.isNotEmpty ? LoginPage.userId : 'patient-01';
    final result = await WellbeingService.createSleepRecord(
      patientId: patientId,
      sleepDate: _today,
      bedtime: _bedtimeController.text,
      wakeUpTime: _wakeUpController.text,
      sleepDuration: _sleepDurationController.text,
      sleepQuality: _sleepQuality,
      nightAwakenings: _selectedNightAwakenings,
      difficultySleeping: _difficultySleeping,
      notes: _sleepNotesController.text.trim(),
    );

    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _sleepRecords.insert(0, {
          'date': result['sleepDate'],
          'bedTime': result['bedtime'],
          'wakeUpTime': result['wakeUpTime'],
          'sleepDuration': result['sleepDuration'],
          'quality': result['sleepQuality'],
          'awakenings': result['nightAwakenings'],
          'difficulty': result['difficultySleeping'],
          'notes': result['notes'],
        });
      });
      _sleepDateController.clear();
      _bedtimeController.clear();
      _wakeUpController.clear();
      _sleepDurationController.clear();
      _sleepDateController.text = _today;
      _nightAwakeningsController.clear();
      _sleepNotesController.clear();
      _bedtime = null;
      _wakeUpTime = null;
      _selectedNightAwakenings = '0 time';
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sleep record saved.')));
    }
  }

  Future<void> _saveMoodRecord() async {
    final patientId =
        LoginPage.userId.isNotEmpty ? LoginPage.userId : 'patient-01';
    final result = await WellbeingService.createMoodRecord(
      patientId: patientId,
      mood: _selectedMood,
      intensity: _selectedMoodIntensity,
      notes: _moodNotesController.text.trim(),
      date: DateTime.now().toIso8601String().split('T').first,
    );

    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _moodRecords.insert(0, {
          'date': result['date'],
          'mood': result['mood'],
          'intensity': result['intensity'],
          'notes': result['notes'],
        });
      });
      _moodNotesController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mood recorded.')));
    }
  }

  Future<void> _saveActivity() async {
    final patientId =
        LoginPage.userId.isNotEmpty ? LoginPage.userId : 'patient-01';
    final result = await WellbeingService.createActivity(
      patientId: patientId,
      title: _selectedActivityCategory,
      category: _selectedActivityCategory,
      date: DateTime.now().toIso8601String().split('T').first,
      time: DateTime.now().toIso8601String().split('T').last.substring(0, 5),
      duration: _selectedActivityDuration,
      notes: _activityNotesController.text.trim(),
    );

    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _activities.insert(0, {
          'title': result['title'],
          'category': result['category'],
          'date': result['date'],
          'time': result['time'],
          'duration': result['duration'],
          'notes': result['notes'],
          'completed': false,
        });
      });
      _selectedActivityDuration = null;
      _activityNotesController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Activity added.')));
    }
  }

  Future<void> _toggleActivityComplete(Map<String, dynamic> item) async {
    final patientId =
        LoginPage.userId.isNotEmpty ? LoginPage.userId : 'patient-01';
    final activityId = item['id']?.toString() ??
        'activity-${DateTime.now().millisecondsSinceEpoch}';
    final completed = !_toBool(item['completed']);
    await WellbeingService.completeActivity(
      patientId: patientId,
      activityId: activityId,
      completed: completed,
    );

    setState(() {
      final index = _activities.indexWhere((entry) =>
          entry['id'] == activityId ||
          (entry['title'] == item['title'] && entry['date'] == item['date']));
      if (index >= 0) {
        _activities[index]['completed'] = completed;
      }
    });
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
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  bool get _showSleep => widget.tab == WellbeingTab.sleepHygiene;

  @override
  void dispose() {
    _sleepDateController.dispose();
    _bedtimeController.dispose();
    _wakeUpController.dispose();
    _sleepDurationController.dispose();
    _nightAwakeningsController.dispose();
    _sleepNotesController.dispose();
    _moodNotesController.dispose();
    _activityNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final todayActivities = _activities
        .where((a) =>
            '${a['date']}' == DateTime.now().toIso8601String().split('T').first)
        .toList();
    final upcomingActivities = _activities
        .where((a) =>
            '${a['date']}' != DateTime.now().toIso8601String().split('T').first)
        .toList();
    final completedActivities =
        _activities.where((a) => _toBool(a['completed']) == true).toList();

    return AnimatedBuilder(
      animation: LanguageService(),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            LanguageService().getText(
              _showSleep ? 'sleep_hygiene' : 'mood_activity',
            ),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showSleep)
                  _buildSectionCard(
                    title: LanguageService().getText('sleep_hygiene'),
                    children: [
                      TextFormField(
                        controller: _sleepDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Sleep date',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _sleepTimeTile(bedtime: true),
                          const SizedBox(width: 10),
                          _sleepTimeTile(bedtime: false),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: BrandColors.ice,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_bottom_rounded,
                                color: BrandColors.tealDark),
                            const SizedBox(width: 10),
                            Text('Time asleep', style: GoogleFonts.poppins()),
                            const Spacer(),
                            Text(
                              _sleepDurationController.text.isEmpty
                                  ? 'Set both times'
                                  : _sleepDurationController.text,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('How did you sleep?',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          (
                            'Very Low',
                            Icons.sentiment_very_dissatisfied_rounded
                          ),
                          ('Low', Icons.sentiment_dissatisfied_rounded),
                          ('Neutral', Icons.sentiment_neutral_rounded),
                          ('Good', Icons.sentiment_satisfied_rounded),
                          ('Very Good', Icons.sentiment_very_satisfied_rounded),
                        ]
                            .map((choice) => _sleepChoiceChip(
                                  label: choice.$1,
                                  icon: choice.$2,
                                  selected: _sleepQuality == choice.$1,
                                  onSelected: () =>
                                      setState(() => _sleepQuality = choice.$1),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('How often did you wake?',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          '0 time',
                          '1 time',
                          '2 times',
                          '3 times',
                          '4 times',
                          '5 and more'
                        ]
                            .map((value) => _sleepChoiceChip(
                                  label: value,
                                  icon: Icons.nights_stay_rounded,
                                  selected: _selectedNightAwakenings == value,
                                  onSelected: () => setState(
                                      () => _selectedNightAwakenings = value),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Text('Difficulty falling or staying asleep',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ('No difficulty', Icons.check_circle_outline_rounded),
                          ('Mild', Icons.bedtime_outlined),
                          ('Moderate', Icons.more_horiz_rounded),
                          ('High', Icons.warning_amber_rounded),
                        ]
                            .map((choice) => _sleepChoiceChip(
                                  label: choice.$1,
                                  icon: choice.$2,
                                  selected: _difficultySleeping == choice.$1,
                                  onSelected: () => setState(
                                      () => _difficultySleeping = choice.$1),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sleepNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: _saveSleepRecord,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save Sleep Record'))),
                      const SizedBox(height: 12),
                      Text('Recent sleep history',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800)),
                      const SizedBox(height: 8),
                      if (_sleepRecords.isEmpty)
                        Text('No sleep records yet.',
                            style:
                                GoogleFonts.poppins(color: Colors.grey.shade600))
                      else
                        ..._sleepRecords.take(3).map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item['date']} • ${item['quality']}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Bedtime: ${item['bedTime']} • Wake: ${item['wakeUpTime']}',
                                      style: GoogleFonts.poppins()),
                                  Text(
                                      'Duration: ${item['sleepDuration']} • Awakenings: ${item['awakenings']}',
                                      style: GoogleFonts.poppins()),
                                  if ((item['notes'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text('Notes: ${item['notes']}',
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey.shade700)),
                                ],
                              ),
                            )),
                    ],
                  ),
                if (!_showSleep)
                  _buildSectionCard(
                    title: 'Mood',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Very Low',
                          'Low',
                          'Neutral',
                          'Good',
                          'Very Good'
                        ].map((mood) {
                          final active = _selectedMood == mood;
                          return ChoiceChip(
                            label: Text(mood),
                            selected: active,
                            onSelected: (_) =>
                                setState(() => _selectedMood = mood),
                            selectedColor:
                                BrandColors.navy.withOpacity(0.15),
                            labelStyle:
                                GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedMoodIntensity,
                        decoration: const InputDecoration(
                            labelText: 'Intensity',
                            border: OutlineInputBorder()),
                        items: ['Low', 'Moderate', 'High']
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) => setState(
                            () => _selectedMoodIntensity = value ?? 'Moderate'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _moodNotesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: _saveMoodRecord,
                              icon: const Icon(
                                  Icons.sentiment_satisfied_alt_rounded),
                              label: const Text('Save Mood'))),
                      const SizedBox(height: 12),
                      Text('Mood history',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800)),
                      const SizedBox(height: 8),
                      if (_moodRecords.isEmpty)
                        Text('No mood entries yet.',
                            style:
                                GoogleFonts.poppins(color: Colors.grey.shade600))
                      else
                        ..._moodRecords.take(3).map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item['date']} • ${item['mood']}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                  if ((item['intensity'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text('Intensity: ${item['intensity']}',
                                        style: GoogleFonts.poppins()),
                                  if ((item['notes'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text('Notes: ${item['notes']}',
                                        style: GoogleFonts.poppins(
                                            color: Colors.grey.shade700)),
                                ],
                              ),
                            )),
                    ],
                  ),
                if (!_showSleep)
                  _buildSectionCard(
                    title: 'Activity',
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedActivityCategory,
                        decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder()),
                        items: [
                          'Walking',
                          'Exercise',
                          'Relaxation',
                          'Social Activity',
                          'Hobby',
                          'Daily Routine',
                          'Other'
                        ]
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) => setState(() =>
                            _selectedActivityCategory = value ?? 'Walking'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedActivityDuration,
                        decoration: const InputDecoration(
                            labelText: 'Duration',
                            border: OutlineInputBorder()),
                        items: [
                          '0 to 1 hour',
                          '1 to 2 hour',
                          'More than 2 hour'
                        ]
                            .map((value) => DropdownMenuItem(
                                value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedActivityDuration = value),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _activityNotesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: _saveActivity,
                              icon:
                                  const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Add Activity'))),
                      const SizedBox(height: 12),
                      Text('Activities',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800)),
                      const SizedBox(height: 8),
                      if (_activities.isEmpty)
                        Text('No activities added yet.',
                            style:
                                GoogleFonts.poppins(color: Colors.grey.shade600))
                      else
                        ..._activities.take(4).map((activity) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${activity['title']} • ${activity['category']}',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            '${activity['date']} • ${activity['time']} • ${activity['duration']}',
                                            style: GoogleFonts.poppins()),
                                        if ((activity['notes'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text('Notes: ${activity['notes']}',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: _toBool(activity['completed']),
                                    onChanged: (_) =>
                                        _toggleActivityComplete(activity),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                if (!_showSleep)
                  _buildSectionCard(
                    title: 'Activity Schedule',
                    children: [
                      ...[
                        ('Today', todayActivities),
                        ('Upcoming', upcomingActivities),
                        ('Completed', completedActivities),
                      ].map((entry) {
                        final sectionTitle = entry.$1;
                        final items = entry.$2;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(sectionTitle,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800)),
                            const SizedBox(height: 6),
                            if (items.isEmpty)
                              Text(
                                  'No ${sectionTitle.toLowerCase()} activities.',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade600))
                            else
                              ...items.map((item) => Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  '${item['title']} • ${item['category']}',
                                                  style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  '${item['date']} • ${item['time']} • ${item['duration']}',
                                                  style: GoogleFonts.poppins()),
                                            ],
                                          ),
                                        ),
                                        if (sectionTitle != 'Completed')
                                          TextButton(
                                            onPressed: () =>
                                                _toggleActivityComplete(item),
                                            child: Text(
                                                _toBool(item['completed'])
                                                    ? 'Completed'
                                                    : 'Mark complete'),
                                          ),
                                      ],
                                    ),
                                  )),
                          ],
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
