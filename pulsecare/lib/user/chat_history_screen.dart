import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:pulsecare/constrains/app_toast.dart';
import 'package:pulsecare/constrains/schedule_date_picker_dialog.dart';
import 'package:pulsecare/model/chat_history_entry.dart';
import 'package:pulsecare/repositories/chat_repository.dart';
import 'package:pulsecare/repositories/session_repository.dart';
import 'package:pulsecare/user/app_shell.dart';
import 'package:pulsecare/user/new_ai_chat_screen.dart';
import 'package:pulsecare/user/widgets/consultation_chat_widget.dart';
import '../providers/repository_providers.dart';

const double kChatCardRadius = 20;

class ChatHistoryScreen extends ConsumerStatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  bool _isLoading = true;
  List<ChatHistoryEntry> _entries = const <ChatHistoryEntry>[];
  DateTime? _selectedDate;
  late final ChatRepository _chatRepository;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _chatRepository = ref.read(chatRepositoryProvider);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final currentUser = await ref
          .read(userRepositoryProvider)
          .getUserById(SessionRepository().getCurrentUserId());
      if (!mounted) return;
      _userId = currentUser?.id ?? '';
      await _loadEntries();
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'Failed to load chat history');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEntries() async {
    try {
      final items = await _chatRepository.getHistory(_userId);
      if (!mounted) return;
      setState(() {
        _entries = items;
      });
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'Failed to load chat history');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEntry(ChatHistoryEntry entry) async {
    try {
      await _chatRepository.deleteMessage(entry.id);
      await _loadEntries();
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'Failed to delete chat');
      }
    }
  }

  String _dateLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (day == today) return 'Today';

    final yesterday = today.subtract(const Duration(days: 1));
    if (day == yesterday) return 'Yesterday';

    return DateFormat('dd MMM, EEE').format(dateTime);
  }

  List<_HistoryRow> _buildRows() {
    final filteredEntries = _selectedDate == null
        ? _entries
        : _entries.where((entry) {
            return entry.createdAt.year == _selectedDate!.year &&
                entry.createdAt.month == _selectedDate!.month &&
                entry.createdAt.day == _selectedDate!.day;
          }).toList();

    final sortedEntries = [...filteredEntries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final rows = <_HistoryRow>[];
    String? lastLabel;

    for (final entry in sortedEntries) {
      final label = _dateLabel(entry.createdAt);
      if (label != lastLabel) {
        rows.add(_HistoryRow.header(label));
        lastLabel = label;
      }
      rows.add(_HistoryRow.item(entry));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 20,
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/drLara.png'),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Elara',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Your AI Medical Assistant',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: () async {
                final today = DateTime.now();
                if (_entries.isEmpty) {
                  showAppToast(
                    context,
                    'No chat history yet. Start a chat first.',
                  );
                  return;
                }

                final oldest = _entries
                    .map(
                      (e) => DateTime(
                        e.createdAt.year,
                        e.createdAt.month,
                        e.createdAt.day,
                      ),
                    )
                    .reduce((a, b) => a.isBefore(b) ? a : b);

                final latest = _entries
                    .map(
                      (e) => DateTime(
                        e.createdAt.year,
                        e.createdAt.month,
                        e.createdAt.day,
                      ),
                    )
                    .reduce((a, b) => a.isAfter(b) ? a : b);

                final hasChatToday = _entries.any(
                  (entry) =>
                      entry.createdAt.year == today.year &&
                      entry.createdAt.month == today.month &&
                      entry.createdAt.day == today.day,
                );

                final initial = _selectedDate == null
                    ? (hasChatToday ? today : latest)
                    : DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                      );

                final clampedInitial = initial.isBefore(oldest)
                    ? oldest
                    : (initial.isAfter(today) ? today : initial);

                final picked = await showScheduleDatePicker(
                  context: context,
                  initialDate: clampedInitial,
                  firstDate: oldest,
                  lastDate: today,
                );
                if (picked == null || !mounted) return;
                setState(() {
                  _selectedDate = picked;
                });
              },
              child: SvgPicture.asset('assets/icons/calender.svg', height: 18),
            ),
            const SizedBox(width: 13),
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const NewAiChatScreen()),
                );
              },
              child: SvgPicture.asset('assets/icons/new_chat.svg', height: 20),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No chat history yet. Start a chat and your summaries will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          : Column(
              children: [
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${DateFormat('dd MMM yyyy').format(_selectedDate!)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No chats found for ${DateFormat('dd MMM yyyy').format(_selectedDate!)}.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            if (row.header != null) {
                              return dataHeader(row.header!);
                            }

                            final entry = row.entry!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Dismissible(
                                key: ValueKey(entry.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  padding: const EdgeInsets.only(right: 20),
                                  alignment: Alignment.centerRight,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      kChatCardRadius,
                                    ),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                onDismissed: (_) => _deleteEntry(entry),
                                child: ChatHistoryCard(
                                  entry: entry,
                                  onDelete: () => _deleteEntry(entry),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PopScope(
                                          canPop: false,
                                          onPopInvokedWithResult:
                                              (didPop, result) {
                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const AppShell(
                                                          initialTab: 0,
                                                        ),
                                                  ),
                                                  (route) => false,
                                                );
                                              },
                                          child: Scaffold(
                                            appBar: AppBar(
                                              leadingWidth: 40,
                                              titleSpacing: 0,
                                              toolbarHeight: 85,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          bottom:
                                                              Radius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                  ),
                                              elevation: 0.3,
                                              leading: IconButton(
                                                onPressed: () {
                                                  Navigator.pushAndRemoveUntil(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const AppShell(
                                                            initialTab: 0,
                                                          ),
                                                    ),
                                                    (route) => false,
                                                  );
                                                },
                                                icon: SvgPicture.asset(
                                                  'assets/icons/backarrow.svg',
                                                  width: 24,
                                                  height: 20,
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  const CircleAvatar(
                                                    backgroundImage: AssetImage(
                                                      'assets/images/drLara.png',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Dr. Elara',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Your AI Medical Assistant',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade500,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const NewAiChatScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: SvgPicture.asset(
                                                      'assets/icons/new_chat.svg',
                                                      height: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 13),
                                                  InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const ChatHistoryScreen(),
                                                        ),
                                                      );
                                                    },
                                                    child: SvgPicture.asset(
                                                      'assets/icons/history.svg',
                                                      height: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                              ),
                                            ),
                                            body: ConsultationChatWidget(
                                              conversationId:
                                                  entry.conversationId,
                                              userId: _userId,
                                              showDoctorRecommendations: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class ChatHistoryCard extends StatelessWidget {
  final ChatHistoryEntry entry;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ChatHistoryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kChatCardRadius),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(color: Color.fromARGB(255, 233, 233, 233), blurRadius: 3),
          ],
          color: Colors.white,
          borderRadius: BorderRadius.circular(kChatCardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 10, bottom: 8),
              child: SizedBox(
                height: 88,
                width: 56,
                child: Stack(
                  children: const [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/user.png'),
                    ),
                    Positioned(
                      left: 18,
                      top: 26,
                      child: CircleAvatar(
                        backgroundImage: AssetImage('assets/images/drLara.png'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: entry.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Color(0xff3F67FD),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(entry.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffD9D9D9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 18,
                  width: 18,
                  child: Center(
                    child: SvgPicture.asset('assets/icons/cross.svg'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget dataHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
    child: Row(
      children: [
        const Expanded(
          child: Divider(
            thickness: 2,
            color: Color.fromARGB(255, 225, 225, 225),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const Expanded(
          child: Divider(
            thickness: 2,
            color: Color.fromARGB(255, 225, 225, 225),
          ),
        ),
      ],
    ),
  );
}

class _HistoryRow {
  final String? header;
  final ChatHistoryEntry? entry;

  const _HistoryRow._({this.header, this.entry});

  factory _HistoryRow.header(String title) => _HistoryRow._(header: title);

  factory _HistoryRow.item(ChatHistoryEntry entry) =>
      _HistoryRow._(entry: entry);
}
