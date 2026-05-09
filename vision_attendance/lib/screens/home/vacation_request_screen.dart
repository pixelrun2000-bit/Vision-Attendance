import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../state/user_profile_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class VacationRequestScreen extends ConsumerStatefulWidget {
  const VacationRequestScreen({super.key});

  @override
  ConsumerState<VacationRequestScreen> createState() =>
      _VacationRequestScreenState();
}

class _VacationRequestScreenState
    extends ConsumerState<VacationRequestScreen> {
  final ApiClient _api = ApiClient(baseUrl: ApiConfig.baseUrl);

  String _selectedType = 'Annual Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;

  final List<String> _leaveTypes = const [
    'Annual Leave',
    'Sick Leave',
    'Personal Leave',
    'Maternity/Paternity',
    'Emergency Leave',
  ];

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final user = ref.read(userProfileProvider);

    if (user == null) return;

    if (user.isStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Students are not allowed to request vacations'),
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _api.postJson(
        "/api/vacations",
        token: user.token,
        body: {
          "type": _selectedType,
          "start_date": _startDate!.toIso8601String().split('T').first,
          "end_date": _endDate!.toIso8601String().split('T').first,
          "reason": _reasonController.text.trim(),
        },
      );

      if (mounted) {
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Leave request submitted successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Leave"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LEAVE TYPE", style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _leaveTypes
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: "Start Date",
                    date: _startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: "End Date",
                    date: _endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Reason",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: const Icon(Icons.send),
                label: _isLoading
                    ? const Text("Sending...")
                    : const Text("Submit Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(
              date == null
                  ? "Select"
                  : "${date!.day}/${date!.month}/${date!.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}