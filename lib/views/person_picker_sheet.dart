import 'package:flutter/material.dart';
import '../models/chore_item.dart';
import '../models/person.dart';
import '../viewmodels/chore_store.dart';

void showPersonPickerSheet(
  BuildContext context, {
  required ChoreItem chore,
  required ChoreStore store,
  DateTime? presetDate,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) =>
        _PersonPickerSheet(chore: chore, store: store, presetDate: presetDate),
  );
}

class _PersonPickerSheet extends StatefulWidget {
  const _PersonPickerSheet(
      {required this.chore, required this.store, this.presetDate});
  final ChoreItem chore;
  final ChoreStore store;
  final DateTime? presetDate;

  @override
  State<_PersonPickerSheet> createState() => _PersonPickerSheetState();
}

class _PersonPickerSheetState extends State<_PersonPickerSheet> {
  bool _recorded = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.presetDate ?? DateTime.now();
  }

  bool get _isPreset => widget.presetDate != null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: now,
      locale: const Locale('ja'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (sel == today) return '今日';
    if (today.difference(sel).inDays == 1) return '昨日';
    return '${_selectedDate.month}/${_selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _isPreset ? 380 : 440,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 28),
              const Text('誰がやりましたか？',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(widget.chore.name,
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
              Text('+${widget.chore.points} pt',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isPreset ? null : _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(_dateLabel,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87)),
                      if (!_isPreset) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down,
                            size: 16, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: Person.values
                    .map((person) => Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: PersonButton(
                            person: person,
                            onTap: () {
                              final date = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                DateTime.now().hour,
                                DateTime.now().minute,
                              );
                              widget.store
                                  .recordChore(widget.chore, person, date: date);
                              setState(() => _recorded = true);
                              Future.delayed(
                                  const Duration(milliseconds: 700), () {
                                if (context.mounted) Navigator.pop(context);
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 16),
            ],
          ),
          if (_recorded)
            Container(
              color: Colors.white.withValues(alpha: 0.93),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 72, color: Colors.green),
                    SizedBox(height: 12),
                    Text('記録しました！',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PersonButton extends StatelessWidget {
  const PersonButton({super.key, required this.person, required this.onTap});
  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: person.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: person.color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(person.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              person.displayName,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: person.color),
            ),
          ],
        ),
      ),
    );
  }
}
