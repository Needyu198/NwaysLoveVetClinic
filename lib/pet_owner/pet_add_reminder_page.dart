import 'package:flutter/material.dart';

import 'pet_add_reminder_styles.dart';

class PetAddReminderPage extends StatefulWidget {
  const PetAddReminderPage({super.key});

  static const String routeName = '/pet-add-reminder';

  @override
  State<PetAddReminderPage> createState() => _PetAddReminderPageState();
}

class _PetAddReminderPageState extends State<PetAddReminderPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  ReminderType _selectedType = ReminderType.vaccine;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _showErrors = false;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _selectedDate != null &&
      _selectedTime != null;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshSubmitState);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _AddReminderHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormHint(type: _selectedType),
                    const SizedBox(height: 22),
                    const _FieldLabel(label: 'Title', requiredField: true),
                    const SizedBox(height: 10),
                    _InputBox(
                      controller: _titleController,
                      hint: 'e.g., Rabies Vaccine',
                      hasError:
                          _showErrors && _titleController.text.trim().isEmpty,
                      errorText: 'Please enter a reminder title.',
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel(label: 'Type', requiredField: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChoice(
                            type: ReminderType.vaccine,
                            selectedType: _selectedType,
                            onTap: _selectType,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeChoice(
                            type: ReminderType.medicine,
                            selectedType: _selectedType,
                            onTap: _selectType,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TypeChoice(
                            type: ReminderType.checkup,
                            selectedType: _selectedType,
                            onTap: _selectType,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _FieldLabel(label: 'Description'),
                    const SizedBox(height: 10),
                    _InputBox(
                      controller: _descriptionController,
                      hint: 'Add details about this reminder...',
                      minHeight: 132,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _DateTimeField(
                            label: 'Date',
                            value: _formatDate(_selectedDate),
                            hint: 'Select date',
                            icon: Icons.calendar_month_rounded,
                            hasError: _showErrors && _selectedDate == null,
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _DateTimeField(
                            label: 'Time',
                            value: _formatTime(_selectedTime),
                            hint: 'Select time',
                            icon: Icons.schedule_rounded,
                            hasError: _showErrors && _selectedTime == null,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    if (_showErrors &&
                        (_selectedDate == null || _selectedTime == null)) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Please choose both date and time.',
                        style: AddReminderStyles.error,
                      ),
                    ],
                    const SizedBox(height: 22),
                    const _FieldLabel(label: 'Additional Notes'),
                    const SizedBox(height: 10),
                    _InputBox(
                      controller: _notesController,
                      hint: 'e.g., Give with food, bring medical records...',
                      minHeight: 96,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    const _FriendlyNote(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
            _BottomActions(
              canSubmit: _canSubmit,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _refreshSubmitState() {
    setState(() {});
  }

  void _selectType(ReminderType type) {
    setState(() => _selectedType = type);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (date == null) return;
    setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time == null) return;
    setState(() => _selectedTime = time);
  }

  void _submit() {
    setState(() => _showErrors = true);

    if (!_canSubmit) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_titleController.text.trim()} reminder added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '${months[date.month - 1]} $day, ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

enum ReminderType {
  vaccine(
    label: 'Vaccine',
    helper: 'Best for shots, boosters, and vaccination records.',
    icon: Icons.vaccines_rounded,
    selectedColor: Color(0xFF2F80FF),
  ),
  medicine(
    label: 'Medicine',
    helper: 'Use for pills, drops, dosage, and repeat medication.',
    icon: Icons.medication_rounded,
    selectedColor: Color(0xFF6B7280),
  ),
  checkup(
    label: 'Check-up',
    helper: 'Great for clinic visits, follow-ups, and health checks.',
    icon: Icons.medical_services_rounded,
    selectedColor: Color(0xFF8B3DFF),
  );

  const ReminderType({
    required this.label,
    required this.helper,
    required this.icon,
    required this.selectedColor,
  });

  final String label;
  final String helper;
  final IconData icon;
  final Color selectedColor;
}

class _AddReminderHeader extends StatelessWidget {
  const _AddReminderHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 22),
      decoration: const BoxDecoration(
        color: Color(0xFFC2FBE3),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add New Reminder', style: AddReminderStyles.pageTitle),
                SizedBox(height: 4),
                Text(
                  'Set a care task for your pet',
                  style: AddReminderStyles.pageSubtitle,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF6B7280),
            iconSize: 32,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

class _FormHint extends StatelessWidget {
  const _FormHint({required this.type});

  final ReminderType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9F5E5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: type.selectedColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(type.icon, color: type.selectedColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(type.helper, style: AddReminderStyles.helper)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.requiredField = false});

  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AddReminderStyles.label,
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFFF2A2A)),
            ),
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.hint,
    this.minHeight = 72,
    this.maxLines = 1,
    this.hasError = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String hint;
  final double minHeight;
  final int maxLines;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFFF4D4D)
        : const Color(0xFFE1E4EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AddReminderStyles.input,
          decoration: InputDecoration(
            constraints: BoxConstraints(minHeight: minHeight),
            hintText: hint,
            hintStyle: AddReminderStyles.hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFFF4D4D)
                    : const Color(0xFF7EDFBF),
                width: 2.4,
              ),
            ),
          ),
        ),
        if (hasError && errorText != null) ...[
          const SizedBox(height: 7),
          Text(errorText!, style: AddReminderStyles.error),
        ],
      ],
    );
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  final ReminderType type;
  final ReminderType selectedType;
  final ValueChanged<ReminderType> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = type == selectedType;
    final foreground = selected ? Colors.white : const Color(0xFF344054);
    final iconColor = selected
        ? const Color(0xFFC2FBE3)
        : const Color(0xFF344054);

    return Material(
      color: selected ? type.selectedColor : const Color(0xFFF2F3F5),
      borderRadius: BorderRadius.circular(22),
      elevation: selected ? 8 : 0,
      shadowColor: selected ? type.selectedColor.withValues(alpha: 0.24) : null,
      child: InkWell(
        onTap: () => onTap(type),
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 108,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 31, color: iconColor),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.hasError = false,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFFF4D4D)
        : const Color(0xFFE1E4EA);
    final hasValue = value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, requiredField: true),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF6B7280), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasValue ? value : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hasValue
                          ? AddReminderStyles.dateTimeValue
                          : AddReminderStyles.dateTimeHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendlyNote extends StatelessWidget {
  const _FriendlyNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF66756F), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Required fields are marked with *. Optional details help the clinic understand the reminder faster.',
            style: AddReminderStyles.smallHelp,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool canSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFC2FBE3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 58,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFFFF0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 58,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.save_outlined, size: 23),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Add Reminder'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: canSubmit
                      ? const Color(0xFF666664)
                      : const Color(0xFF9CA3AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: canSubmit ? 8 : 0,
                  shadowColor: const Color(0x66000000),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
