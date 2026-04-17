import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hopelink_admin/features/Event/models/event_volunteer_model.dart';
import 'package:hopelink_admin/features/Event/models/org_event_model.dart';

import '../controllers/org_events_controller.dart';
import '../widgets/event_theme.dart';
import '../widgets/event_components.dart';

class EditEventPage extends StatefulWidget {
  final OrgEvent event;
  final OrgEventsController ctrl;

  const EditEventPage({required this.event, required this.ctrl, super.key});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final formKey = GlobalKey<FormState>();
  late TextEditingController titleCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController maxVolunteersCtrl;
  late TextEditingController creditHoursCtrl;
  late TextEditingController skillsInputCtrl;

  late Rx<String> selectedCategory;
  late Rx<String> selectedEventType;
  late Rx<String> selectedEligibility;
  late Rx<String> selectedStatus;
  late Rx<DateTime> startDate;
  late Rx<DateTime> endDate;
  late Rx<TimeOfDay> startTime;
  late Rx<TimeOfDay> endTime;
  final selectedSkills = <String>[].obs;
  final updatedImages = <String>[].obs;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _initializeForm();
  }

  void _initializeForm() {
    titleCtrl = TextEditingController(text: widget.event.title);
    descriptionCtrl = TextEditingController(text: widget.event.description);
    addressCtrl = TextEditingController(text: widget.event.location.address);
    cityCtrl = TextEditingController(text: widget.event.location.city);
    stateCtrl = TextEditingController(text: widget.event.location.state);
    maxVolunteersCtrl = TextEditingController(
      text: widget.event.maxVolunteers.toString(),
    );
    creditHoursCtrl = TextEditingController(
      text: widget.event.creditHours.toString(),
    );
    skillsInputCtrl = TextEditingController();

    selectedCategory = widget.event.category.obs;
    selectedEventType = widget.event.eventType.obs;
    selectedEligibility = widget.event.eligibility.obs;
    selectedStatus = widget.event.status.obs;
    startDate = widget.event.startDate.obs;
    endDate = widget.event.endDate.obs;
    startTime = TimeOfDay.fromDateTime(widget.event.startDate).obs;
    endTime = TimeOfDay.fromDateTime(widget.event.endDate).obs;
    selectedSkills.assignAll(widget.event.parsedSkills);
    updatedImages.assignAll(widget.event.images.map((img) => img.url).toList());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    maxVolunteersCtrl.dispose();
    creditHoursCtrl.dispose();
    skillsInputCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!formKey.currentState!.validate()) return;
    if (selectedSkills.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please add at least one skill',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: evRed,
        colorText: Colors.white,
      );
      return;
    }

    final startDateTime = DateTime(
      startDate.value.year,
      startDate.value.month,
      startDate.value.day,
      startTime.value.hour,
      startTime.value.minute,
    );

    final endDateTime = DateTime(
      endDate.value.year,
      endDate.value.month,
      endDate.value.day,
      endTime.value.hour,
      endTime.value.minute,
    );

    final updateData = UpdateEventRequest(
      title: titleCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      category: selectedCategory.value,
      eventType: selectedEventType.value,
      status: selectedStatus.value,
      startDate: startDateTime,
      endDate: endDateTime,
      maxVolunteers: int.tryParse(maxVolunteersCtrl.text) ?? 0,
      creditHours: int.tryParse(creditHoursCtrl.text) ?? 0,
      requiredSkills: selectedSkills.toList(),
      eligibility: selectedEligibility.value,
      location: {
        'address': addressCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
      },
    );

    widget.ctrl.updateEvent(widget.event.id, updateData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: evBg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventSectionHeader(
                  title: 'Basic Information',
                  icon: Icons.info_outlined,
                ),
                EventFormField(
                  label: 'Event Title',
                  controller: titleCtrl,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                EventFormField(
                  label: 'Description',
                  controller: descriptionCtrl,
                  maxLines: 4,
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'Description is required' : null,
                ),
                EventSectionHeader(
                  title: 'Event Configuration',
                  icon: Icons.tune,
                  divider: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Category',
                        value: selectedCategory,
                        items: const [
                          'cleaning',
                          'education',
                          'awareness',
                          'health',
                          'environment',
                          'animals',
                          'community',
                          'other',
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Type',
                        value: selectedEventType,
                        items: const ['one-day', 'multi-day', 'recurring'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Status',
                  value: selectedStatus,
                  items: const [
                    'draft',
                    'published',
                    'ongoing',
                    'completed',
                    'cancelled',
                  ],
                ),
                EventSectionHeader(
                  title: 'Location Details',
                  icon: Icons.location_on_outlined,
                  divider: true,
                ),
                EventFormField(label: 'Address', controller: addressCtrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: EventFormField(
                        label: 'City',
                        controller: cityCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EventFormField(
                        label: 'State',
                        controller: stateCtrl,
                      ),
                    ),
                  ],
                ),
                EventSectionHeader(
                  title: 'Schedule',
                  icon: Icons.calendar_today_outlined,
                  divider: true,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START DATE & TIME',
                      style: evMonoSm().copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Start',
                        date: startDate,
                        onDateChanged: (d) => startDate.value = d,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Time',
                        time: startTime,
                        onTimeChanged: (t) => startTime.value = t,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'END DATE & TIME',
                      style: evMonoSm().copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'End',
                        date: endDate,
                        onDateChanged: (d) => endDate.value = d,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        label: 'Time',
                        time: endTime,
                        onTimeChanged: (t) => endTime.value = t,
                      ),
                    ),
                  ],
                ),
                EventSectionHeader(
                  title: 'Volunteer Requirements',
                  icon: Icons.group_outlined,
                  divider: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: EventFormField(
                        label: 'Max Volunteers',
                        controller: maxVolunteersCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) {
                            return 'Max volunteers is required';
                          }
                          if (int.tryParse(v!) == null) {
                            return 'Must be a number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EventFormField(
                        label: 'Credit Hours',
                        controller: creditHoursCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Eligibility',
                        value: selectedEligibility,
                        items: const [
                          'Anyone',
                          '18+',
                          'Students',
                          'Adults',
                          'Seniors',
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REQUIRED SKILLS',
                      style: evMonoSm().copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: EventFormField(
                        label: 'Add skill',
                        controller: skillsInputCtrl,
                      ),
                    ),
                    const SizedBox(width: 8),
                    EventBtn(
                      label: 'Add',
                      icon: Icons.add_rounded,
                      onTap: () {
                        final skill = skillsInputCtrl.text.trim();
                        if (skill.isNotEmpty &&
                            !selectedSkills.contains(skill)) {
                          selectedSkills.add(skill);
                          skillsInputCtrl.clear();
                        }
                      },
                      accentColor: evBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedSkills
                        .map(
                          (skill) => EventTag(
                            label: skill,
                            removable: true,
                            color: evBlue,
                            onRemove: () => selectedSkills.remove(skill),
                          ),
                        )
                        .toList(),
                  ),
                ),
                EventSectionHeader(
                  title: 'Media',
                  icon: Icons.image_outlined,
                  divider: true,
                ),
                Obx(
                  () => updatedImages.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: evBorder),
                            borderRadius: evR12,
                            color: evSurf2,
                          ),
                          child: Center(
                            child: Text(
                              'No images attached',
                              style: evBodySm(),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: updatedImages.length,
                            itemBuilder: (ctx, idx) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: evR10,
                                      child: Image.network(
                                        updatedImages[idx],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 100,
                                          height: 100,
                                          color: evSurf3,
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: evTextMute,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            updatedImages.removeAt(idx),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: evRed,
                                            borderRadius: evR6,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 40),
                _buildActionButtons(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILDERS
  // ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: evSurf,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: evText, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Text('Edit Event', style: evHeadingMd()),
      centerTitle: false,
    );
  }

  Widget _buildDropdown({
    required String label,
    required Rx<String> value,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: evMonoSm().copyWith(letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Obx(
          () => DropdownButtonFormField<String>(
            value: items.contains(value.value) ? value.value : items.first,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: evBodySm()),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) value.value = val;
            },
            style: evBodySm().copyWith(color: evText),
            decoration: InputDecoration(
              filled: true,
              fillColor: evSurf2,
              border: OutlineInputBorder(
                borderRadius: evR10,
                borderSide: const BorderSide(color: evBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: evR10,
                borderSide: const BorderSide(color: evBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: evR10,
                borderSide: BorderSide(color: evBlue.withOpacity(0.6)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required Rx<DateTime> date,
    required Function(DateTime) onDateChanged,
  }) {
    return Obx(
      () => GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: date.value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: evBlue,
                  onPrimary: Colors.black,
                  surface: evSurf,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (d != null) onDateChanged(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: evSurf2,
            border: Border.all(color: evBorder),
            borderRadius: evR10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(date.value),
                style: evBodySm(),
              ),
              Icon(Icons.calendar_today, size: 14, color: evTextSub),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required Rx<TimeOfDay> time,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Obx(
      () => GestureDetector(
        onTap: () async {
          final t = await showTimePicker(
            context: context,
            initialTime: time.value,
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: evBlue,
                  onPrimary: Colors.black,
                  surface: evSurf,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (t != null) onTimeChanged(t);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: evSurf2,
            border: Border.all(color: evBorder),
            borderRadius: evR10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time.value.format(context), style: evBodySm()),
              Icon(Icons.access_time_rounded, size: 14, color: evTextSub),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: EventBtn(
              label: 'Cancel',
              ghost: true,
              onTap: () => Get.back(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: EventBtn(
              label: widget.ctrl.isUpdatingEvent.value
                  ? 'Saving...'
                  : 'Save Changes',
              loading: widget.ctrl.isUpdatingEvent.value,
              onTap: widget.ctrl.isUpdatingEvent.value ? null : _submitForm,
              accentColor: evGreen,
            ),
          ),
          const SizedBox(width: 12),
          EventBtn(
            label: 'Delete',
            ghost: true,
            accentColor: evRed,
            onTap: widget.ctrl.isDeletingEvent.value
                ? null
                : () {
                    Get.dialog(
                      AlertDialog(
                        backgroundColor: evSurf,
                        title: Text('Delete Event?', style: evHeadingMd()),
                        content: Text(
                          'This action cannot be undone. All volunteer enrollments will be removed.',
                          style: evBodySm(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text('Cancel', style: evBodySm()),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.back();
                              widget.ctrl.deleteEvent(widget.event.id);
                            },
                            child: Text(
                              'Delete',
                              style: evBodySm().copyWith(
                                color: evRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
