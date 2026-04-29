import 'package:flutter/material.dart';

import '../../data/models/student_models.dart';
import '../controllers/student_controller.dart';

class RequestAppointmentPage extends StatefulWidget {
  final StudentController controller;
  final AppointmentAvailabilityItem? preselectedSlot;

  const RequestAppointmentPage({
    super.key,
    required this.controller,
    this.preselectedSlot,
  });

  @override
  State<RequestAppointmentPage> createState() => _RequestAppointmentPageState();
}

class _RequestAppointmentPageState extends State<RequestAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  final _preferredDateController = TextEditingController();

  late List<AppointmentAvailabilityItem> _availableSlots;
  late AppointmentAvailabilityItem _selectedSlot;
  String _selectedIssueType = 'other';
  bool _isSubmitting = false;

  static const _issueTypeOptions = [
    {'value': 'complaint', 'label': 'Complaint'},
    {'value': 'support', 'label': 'Support'},
    {'value': 'inquiry', 'label': 'Inquiry'},
    {'value': 'service_request', 'label': 'Service Request'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _availableSlots = widget.controller.appointmentAvailabilities
        .where((slot) => slot.isFree)
        .toList(growable: false);

    if (_availableSlots.isEmpty) {
      _selectedSlot = AppointmentAvailabilityItem(
        id: 0,
        officerName: '',
        availableDate: '',
        startTime: '',
        endTime: '',
        source: '',
        isFree: false,
      );
    } else if (widget.preselectedSlot != null &&
        _availableSlots.contains(widget.preselectedSlot)) {
      _selectedSlot = widget.preselectedSlot!;
    } else {
      _selectedSlot = _availableSlots.first;
    }

    _preferredDateController.text = _selectedSlot.availableDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    _preferredDateController.dispose();
    super.dispose();
  }

  String _slotSummary(AppointmentAvailabilityItem slot) {
    final parts = <String>[];
    if (slot.officerName.isNotEmpty) parts.add(slot.officerName);
    if (slot.availableDate.isNotEmpty) parts.add(slot.availableDate);
    if (slot.startTime.isNotEmpty && slot.endTime.isNotEmpty) {
      parts.add('${slot.startTime} - ${slot.endTime}');
    }
    return parts.join(' • ');
  }

  String _slotDetails(AppointmentAvailabilityItem slot) {
    final details = <String>[];
    if (slot.availableDate.isNotEmpty) {
      details.add('Date: ${slot.availableDate}');
    }
    if (slot.startTime.isNotEmpty && slot.endTime.isNotEmpty) {
      details.add('Time: ${slot.startTime} - ${slot.endTime}');
    }
    if (slot.source.isNotEmpty) details.add('Source: ${slot.source}');
    details.add(slot.isFree ? 'Status: Free' : 'Status: Booked');
    return details.join('\n');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No free appointment slots are available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final preferredDateText = _preferredDateController.text.trim();
    final preferredDate = DateTime.tryParse(
      preferredDateText.isNotEmpty
          ? preferredDateText
          : _selectedSlot.availableDate,
    );

    final success = await widget.controller.requestAppointment(
      availabilitySlotId: _selectedSlot.id,
      description: _descriptionController.text.trim(),
      issueType: _selectedIssueType,
      preferredDate: preferredDate,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.error ?? 'Unable to request appointment.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Appointment'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _availableSlots.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 24 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 20),
                        _buildSlotSelector(theme),
                        const SizedBox(height: 20),
                        _buildIssueTypeSelector(theme),
                        const SizedBox(height: 20),
                        _buildPreferredDateField(theme),
                        const SizedBox(height: 20),
                        _buildDescriptionField(theme),
                        const SizedBox(height: 20),
                        _buildLocationField(theme),
                        const SizedBox(height: 20),
                        _buildNoteField(theme),
                        const SizedBox(height: 28),
                        _buildSubmitButton(theme),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No available slots',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no free appointment slots available at the moment. Please try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_available_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book an Appointment',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select an available time slot and fill in the details below.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
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

  Widget _buildSlotSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Time Slot',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppointmentAvailabilityItem>(
              initialValue: _selectedSlot,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              items: _availableSlots
                  .map(
                    (slot) => DropdownMenuItem<AppointmentAvailabilityItem>(
                      value: slot,
                      child: Text(
                        _slotSummary(slot),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedSlot = value;
                  _preferredDateController.text = value.availableDate;
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _slotDetails(_selectedSlot),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTypeSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Issue Type',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedIssueType,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              items: _issueTypeOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label'] ?? ''),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedIssueType = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredDateField(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preferred Date',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _preferredDateController,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Defaults to the selected slot date.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(' *', style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe the reason for your appointment...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Optional meeting location',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Note',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Any additional information...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _isSubmitting ? null : _submit,
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
