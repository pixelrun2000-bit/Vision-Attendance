// lib/screens/admin/room_live_status_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/api_config.dart';

class RoomLiveStatusScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? roomData;
  const RoomLiveStatusScreen({super.key, this.roomData});

  @override
  ConsumerState<RoomLiveStatusScreen> createState() => _RoomLiveStatusScreenState();
}

class _RoomLiveStatusScreenState extends ConsumerState<RoomLiveStatusScreen> {
  List<dynamic> _attendees = [];
  bool _loading = true;
  String? _error;
  late int _roomId;
  late String _roomName;

  @override
  void initState() {
    super.initState();
    _roomId = widget.roomData?['id'] ?? 0;
    _roomName = widget.roomData?['name'] ?? 'Room Status';
    _fetchAttendees();
  }

  Future<void> _fetchAttendees() async {
    if (_roomId == 0) return;
    try {
      final api = ref.read(apiServiceProvider);
      // We need a specific endpoint for room live status or use getRooms details
      // Assuming GET /api/rooms/:id/live exists
      final res = await api.getRoomLive(_roomId);
      if (mounted) {
        setState(() {
          _attendees = res['attendees'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to socket updates for real-time refresh
    ref.listen(socketServiceProvider, (prev, next) {
      // In a real app, we'd check the payload of the event
      // For simplicity, we refresh the list when any attendance event occurs
      _fetchAttendees();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_roomName, style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() { _loading = true; _fetchAttendees(); }),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _attendees.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _attendees.length,
                              itemBuilder: (context, index) {
                                final person = _attendees[index];
                                return _AttendeeTile(person: person);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _StatBox(label: 'PRESENT', value: _attendees.length.toString(), color: AppColors.success),
          const SizedBox(width: 16),
          _StatBox(label: 'CAPACITY', value: (widget.roomData?['capacity'] ?? '?').toString(), color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No one is in the room yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.displayMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _AttendeeTile extends StatelessWidget {
  final dynamic person;
  const _AttendeeTile({required this.person});

  @override
  Widget build(BuildContext context) {
    final photoUrl = person['photo_url'] ?? '';
    final fullUrl = photoUrl.isNotEmpty 
        ? (photoUrl.startsWith('http') ? photoUrl : '${ApiConfig.baseUrl}$photoUrl')
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: fullUrl.isNotEmpty ? NetworkImage(fullUrl) : null,
            child: fullUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person['full_name_en'] ?? 'Unknown User', style: AppTextStyles.titleLarge),
                Text(person['employee_id'] ?? 'N/A', style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                person['status']?.toUpperCase() ?? 'PRESENT',
                style: AppTextStyles.labelSmall.copyWith(
                  color: person['status'] == 'late' ? AppColors.warning : AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatTime(person['checkin_time']),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return '--:--'; }
  }
}
