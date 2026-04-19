import 'package:flutter/material.dart';
import '../models/chore_item.dart';
import '../models/person.dart';
import '../viewmodels/chore_store.dart';

enum _Selection { none, husband, wife, both }

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
  _Selection _selection = _Selection.none;
  double _husbandRatio = 50;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.presetDate ?? DateTime.now();
  }

  bool get _isPreset => widget.presetDate != null;

  int get _husbandPt => (widget.chore.points * _husbandRatio / 100)
      .round()
      .clamp(0, widget.chore.points);
  int get _wifePt => widget.chore.points - _husbandPt;

  Future<void> _pickDate() async {
    if (_isPreset) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: now,
      locale: const Locale('ja'),
    );
    if (!mounted) return;
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

  DateTime get _recordDate => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        DateTime.now().hour,
        DateTime.now().minute,
      );

  void _record() {
    switch (_selection) {
      case _Selection.husband:
        widget.store.recordChore(widget.chore, Person.husband,
            date: _recordDate);
      case _Selection.wife:
        widget.store.recordChore(widget.chore, Person.wife, date: _recordDate);
      case _Selection.both:
        if (_husbandPt > 0) {
          widget.store.recordChore(widget.chore, Person.husband,
              date: _recordDate, overridePoints: _husbandPt);
        }
        if (_wifePt > 0) {
          widget.store.recordChore(widget.chore, Person.wife,
              date: _recordDate, overridePoints: _wifePt);
        }
      case _Selection.none:
        return;
    }
    setState(() => _recorded = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (context.mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSlider = _selection == _Selection.both;
    final double height =
        (_isPreset ? 400 : 460) + (showSlider ? 110 : 0);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 24),
              const Text('誰がやりましたか？',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(widget.chore.name,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 16)),
              Text('+${widget.chore.points} pt',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              const SizedBox(height: 10),

              // Date selector
              GestureDetector(
                onTap: _isPreset ? null : _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(_dateLabel,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87)),
                      if (!_isPreset) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_drop_down,
                            size: 15, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selection buttons: 夫 / 妻 / 二人で（タップで選択・再タップで解除・他をタップで上書き）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SelectButton(
                    label: Person.husband.displayName,
                    icon: Person.husband.icon,
                    color: Person.husband.color,
                    selected: _selection == _Selection.husband,
                    onTap: () => setState(() => _selection =
                        _selection == _Selection.husband
                            ? _Selection.none
                            : _Selection.husband),
                  ),
                  const SizedBox(width: 12),
                  _SelectButton(
                    label: Person.wife.displayName,
                    icon: Person.wife.icon,
                    color: Person.wife.color,
                    selected: _selection == _Selection.wife,
                    onTap: () => setState(() => _selection =
                        _selection == _Selection.wife
                            ? _Selection.none
                            : _Selection.wife),
                  ),
                  const SizedBox(width: 12),
                  _BothButton(
                    selected: _selection == _Selection.both,
                    onTap: () => setState(() => _selection =
                        _selection == _Selection.both
                            ? _Selection.none
                            : _Selection.both),
                  ),
                ],
              ),

              // Ratio slider (二人で選択時のみ)
              if (showSlider) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RatioLabel(
                              person: Person.husband,
                              pts: _husbandPt,
                              pct: _husbandRatio.round()),
                          _RatioLabel(
                              person: Person.wife,
                              pts: _wifePt,
                              pct: (100 - _husbandRatio).round()),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.blue.shade300,
                          inactiveTrackColor: Colors.pink.shade200,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12),
                          overlayColor:
                              Colors.grey.withValues(alpha: 0.2),
                          trackHeight: 8,
                        ),
                        child: Slider(
                          value: _husbandRatio,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (v) =>
                              setState(() => _husbandRatio = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('👨 夫',
                              style: TextStyle(
                                  color: Colors.blue.shade400,
                                  fontSize: 11)),
                          Text('👩 妻',
                              style: TextStyle(
                                  color: Colors.pink.shade400,
                                  fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // 記録するボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selection == _Selection.none
                          ? Colors.grey.shade300
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed:
                        _selection == _Selection.none ? null : _record,
                    child: Text(
                      _selection == _Selection.both
                          ? '記録する（👨 ${_husbandPt}pt / 👩 ${_wifePt}pt）'
                          : '記録する',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル',
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
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

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color,
              width: selected ? 2.5 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
      ),
    );
  }
}

class _BothButton extends StatelessWidget {
  const _BothButton({
    required this.selected,
    required this.onTap,
  });
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: selected
                  ? [Colors.blue.shade200, Colors.pink.shade200]
                  : [
                      Colors.blue.withValues(alpha: 0.08),
                      Colors.pink.withValues(alpha: 0.08)
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purple.shade300,
              width: selected ? 2.5 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👫', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              Text('二人で',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade400)),
            ],
          ),
        ),
      );
  }
}

class _RatioLabel extends StatelessWidget {
  const _RatioLabel(
      {required this.person, required this.pts, required this.pct});
  final Person person;
  final int pts;
  final int pct;

  @override
  Widget build(BuildContext context) {
    final color =
        person == Person.husband ? Colors.blue.shade400 : Colors.pink.shade400;
    return Column(
      children: [
        Text(person.icon, style: const TextStyle(fontSize: 26)),
        Text('$pct%',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text('${pts}pt', style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class PersonButton extends StatelessWidget {
  const PersonButton(
      {super.key, required this.person, required this.onTap, this.size = 130});
  final Person person;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: person.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: person.color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(person.icon, style: TextStyle(fontSize: size * 0.4)),
            const SizedBox(height: 6),
            Text(
              person.displayName,
              style: TextStyle(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.bold,
                  color: person.color),
            ),
          ],
        ),
      ),
    );
  }
}
