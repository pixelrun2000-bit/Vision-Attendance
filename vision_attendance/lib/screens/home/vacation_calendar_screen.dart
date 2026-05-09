import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class VacationCalendarScreen extends StatefulWidget {
  const VacationCalendarScreen({super.key});

  @override
  State<VacationCalendarScreen> createState() => _VacationCalendarScreenState();
}

class _VacationCalendarScreenState extends State<VacationCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacation Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
        ),
      ),
    );
  }
}
