import 'package:flutter/material.dart';

import 'wellbeing_service.dart';

class _ScreeningHistoryColors {
  static const primary = Color(0xFF226A27);
  static const deepGreen = Color(0xFF123F16);
  static const page = Color(0xFFEDF5ED);
  static const line = Color(0xFFDCE6DD);
  static const softGreen = Color(0xFFE5F1E5);
  static const ink = Color(0xFF173B22);
}

class ScreeningScheduleCard extends StatelessWidget {
  const ScreeningScheduleCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final dueDate = item['dueDate']?.toString();
    final countdown = item['countdown']?.toString() ?? 'Countdown unavailable';
    final hasDueDate = dueDate != null && dueDate.isNotEmpty;
    final isOverdue = countdown.toLowerCase().startsWith('due date passed');
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isOverdue
        ? colorScheme.error
        : hasDueDate
            ? _ScreeningHistoryColors.primary
            : colorScheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: _ScreeningHistoryColors.softGreen,
                    borderRadius: BorderRadius.all(Radius.circular(13)),
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: _ScreeningHistoryColors.deepGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['screeningType']?.toString() ?? 'Screening',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (item['lastCompletedCheckpoint'] != null)
              _ScheduleDetail(
                label: 'Last completed',
                value: item['lastCompletedCheckpoint'].toString(),
              ),
            if (item['nextCheckpoint'] != null)
              _ScheduleDetail(
                label: 'Next checkpoint',
                value: item['nextCheckpoint'].toString(),
              ),
            if (hasDueDate)
              _ScheduleDetail(label: 'Next follow-up date', value: dueDate),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : hasDueDate
                            ? Icons.schedule_rounded
                            : Icons.info_outline_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      countdown,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDetail extends StatelessWidget {
  const _ScheduleDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTag extends StatelessWidget {
  const _RecordTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: _ScreeningHistoryColors.softGreen,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _ScreeningHistoryColors.deepGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _ScreeningHistoryColors.deepGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class PatientScreeningReportPage extends StatefulWidget {
  const PatientScreeningReportPage({super.key, required this.patientId});

  final String patientId;

  @override
  State<PatientScreeningReportPage> createState() =>
      _PatientScreeningReportPageState();
}

class _PatientScreeningReportPageState
    extends State<PatientScreeningReportPage> {
  static const int _pageSize = 50;

  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _screeningSchedule = [];
  String? _lastScreeningDate;
  String? _error;
  String _selectedType = 'All screenings';
  DateTimeRange? _dateRange;
  int _totalCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool append = false}) async {
    if (append) {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await WellbeingService.getPatientScreeningHistory(
        patientId: widget.patientId,
        offset: append ? _records.length : 0,
        limit: _pageSize,
      );
      final newRecords = List<Map<String, dynamic>>.from(
        (result['records'] as List? ?? const []).map(
          (record) => Map<String, dynamic>.from(record as Map),
        ),
      );
      if (!mounted) return;
      setState(() {
        _records = append ? [..._records, ...newRecords] : newRecords;
        _screeningSchedule = List<Map<String, dynamic>>.from(
          (result['screeningSchedule'] as List? ?? const []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        _totalCount = (result['totalCount'] as num?)?.toInt() ?? 0;
        _hasMore = result['hasMore'] == true;
        _lastScreeningDate = result['lastScreeningDate']?.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleRecords {
    return _records.where((record) {
      if (_selectedType != 'All screenings' &&
          record['screeningType'] != _selectedType) {
        return false;
      }
      if (_dateRange == null) return true;
      final date = DateTime.tryParse(record['screeningDate']?.toString() ?? '');
      if (date == null) return false;
      final day = DateTime(date.year, date.month, date.day);
      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );
      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
      );
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  Widget _buildSummaryCard(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _ScreeningHistoryColors.softGreen,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(icon, color: _ScreeningHistoryColors.deepGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecord(BuildContext context, Map<String, dynamic> record) {
    final responses = List<Map<String, dynamic>>.from(
      (record['responses'] as List? ?? const []).map(
        (response) => Map<String, dynamic>.from(response as Map),
      ),
    );
    final concerns = List<Map<String, dynamic>>.from(
      (record['concerns'] as List? ?? const []).map(
        (concern) => Map<String, dynamic>.from(concern as Map),
      ),
    );
    final score = record['score'];
    final maximumScore = record['maximumScore'];
    final scoreText =
        score == null ? 'Score not recorded' : '$score/$maximumScore';

    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: const BoxDecoration(
            color: _ScreeningHistoryColors.softGreen,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: _ScreeningHistoryColors.deepGreen,
          ),
        ),
        title: Text(
          record['screeningType']?.toString() ?? 'Screening',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          '${record['screeningDate'] ?? 'Date unavailable'}'
          ' · ${record['assessmentCheckpoint'] ?? 'Checkpoint not recorded'}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecordTag(
                  icon: Icons.check_circle_outline_rounded,
                  label: record['status']?.toString() ?? 'Completed',
                ),
                _RecordTag(
                  icon: Icons.bar_chart_rounded,
                  label: scoreText,
                ),
              ],
            ),
          ),
          if (record['interpretation'] != null)
            Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Recorded interpretation: ${record['interpretation']}'),
            ),
          if (responses.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recorded responses',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...responses.map(
              (response) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${response['label'] ?? 'Response'}: ${response['value'] ?? 'Not recorded'}',
                ),
              ),
            ),
          ],
          if (concerns.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recorded concerns',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...concerns.map(
              (concern) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${concern['category'] ?? 'Concern'}: ${concern['concern'] ?? ''}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _ScreeningHistoryColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _ScreeningHistoryColors.primary,
      onPrimary: Colors.white,
      secondary: _ScreeningHistoryColors.deepGreen,
      tertiary: const Color(0xFF3D8050),
      surface: Colors.white,
      onSurface: _ScreeningHistoryColors.ink,
      onSurfaceVariant: const Color(0xFF4B5B4C),
      outlineVariant: _ScreeningHistoryColors.line,
      primaryContainer: _ScreeningHistoryColors.softGreen,
      onPrimaryContainer: _ScreeningHistoryColors.deepGreen,
      secondaryContainer: _ScreeningHistoryColors.softGreen,
      onSecondaryContainer: _ScreeningHistoryColors.deepGreen,
      error: const Color(0xFFB3261E),
    );
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _ScreeningHistoryColors.page,
        appBarTheme: const AppBarTheme(
          backgroundColor: _ScreeningHistoryColors.deepGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: _ScreeningHistoryColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: _ScreeningHistoryColors.primary),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: _ScreeningHistoryColors.ink,
          displayColor: _ScreeningHistoryColors.ink,
        ),
      ),
      child: Builder(
        builder: (context) {
          final visibleRecords = _visibleRecords;
          final colorScheme = Theme.of(context).colorScheme;
          final activeSchedules = _screeningSchedule
              .where((item) => item['dueDate'] != null)
              .length;
          return Scaffold(
            backgroundColor: _ScreeningHistoryColors.page,
            appBar: AppBar(
              title: const Text('Screening history'),
              actions: [
                IconButton(
                  onPressed: _isLoading ? null : () => _loadHistory(),
                  tooltip: 'Refresh screening history',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadHistory(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                _ScreeningHistoryColors.deepGreen,
                                _ScreeningHistoryColors.primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PATIENT SCREENING',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.78),
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Screening history',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Patient ID  ${widget.patientId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = (constraints.maxWidth - 10) / 2;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildSummaryCard(
                                    context,
                                    'Total records',
                                    '$_totalCount',
                                    Icons.fact_check_outlined,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildSummaryCard(
                                    context,
                                    'Next follow-ups',
                                    '$activeSchedules of ${_screeningSchedule.length}',
                                    Icons.event_available_outlined,
                                  ),
                                ),
                                SizedBox(
                                  width: constraints.maxWidth,
                                  child: _buildSummaryCard(
                                    context,
                                    'Latest screening',
                                    _lastScreeningDate ??
                                        'No screening records',
                                    Icons.history_rounded,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          context,
                          'Follow-up schedule',
                          'Each screening has its own next date and countdown.',
                        ),
                        if (_screeningSchedule.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Text('No screening schedule is available.'),
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth >= 760 ? 2 : 1;
                              const spacing = 12.0;
                              final cardWidth = columns == 1
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - spacing) / columns;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: _screeningSchedule
                                    .map(
                                      (item) => SizedBox(
                                        width: cardWidth,
                                        child:
                                            ScreeningScheduleCard(item: item),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(
                          context,
                          'Screening records',
                          'Review completed assessments, scores and recorded answers.',
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 210,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Screening type',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      'All screenings',
                                      'PO Bado',
                                      'Distress Thermometer',
                                      'PHQ-9',
                                      'GAD-7',
                                    ]
                                        .map((type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedType = value);
                                      }
                                    },
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _selectDateRange(context),
                                  icon: const Icon(Icons.date_range_rounded),
                                  label: Text(
                                    _dateRange == null
                                        ? 'Date range'
                                        : '${_dateRange!.start.toIso8601String().substring(0, 10)}'
                                            ' – ${_dateRange!.end.toIso8601String().substring(0, 10)}',
                                  ),
                                ),
                                if (_dateRange != null)
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _dateRange = null),
                                    child: const Text('Clear'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            '${visibleRecords.length} shown · $_totalCount total records',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                        if (_error != null)
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: ListTile(
                              title: const Text(
                                  'Unable to load screening history'),
                              subtitle: Text(_error!),
                              trailing: IconButton(
                                onPressed: () => _loadHistory(),
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Retry',
                              ),
                            ),
                          ),
                        if (_records.isEmpty && _error == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, size: 42),
                                SizedBox(height: 10),
                                Text('No screening records are available.'),
                              ],
                            ),
                          ),
                        if (_records.isNotEmpty && visibleRecords.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: Text('No records match these filters.'),
                            ),
                          ),
                        ...visibleRecords.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildRecord(context, record),
                          ),
                        ),
                        if (_hasMore)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: OutlinedButton(
                                onPressed: _isLoadingMore
                                    ? null
                                    : () => _loadHistory(append: true),
                                child: _isLoadingMore
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Load more'),
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
