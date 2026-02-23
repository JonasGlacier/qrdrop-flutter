import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'receive_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
// Light mode
const _colorBackgroundLight = Color(0xFFF1F5F9); // slate/100
const _colorSectionBgLight = Color(0xFFF8FAFC); // slate/50
const _colorDarkLight = Color(0xFF314158); // slate/700
const _colorMutedLight = Color(0xFF90A1B9); // slate/400
const _colorBorderLight = Color(0xFFE2E8F0); // slate/200
const _colorGreenLight = Color(0xFF58CC02);
const _colorGreenShadowLight = Color(0xFF46A302);
const _colorBlueLight = Color(0xFF1CB0F6);
const _colorBlueShadowLight = Color(0xFF1899D6);

// Dark mode
const _colorBackgroundDark = Color(0xFF0F172B); // slate/900
const _colorSectionBgDark = Color(0xFF1D293D); // slate/800
const _colorDarkDark = Color(0xFFF1F5F9); // slate/100
const _colorMutedDark = Color(0xFFCAD5E2); // slate/300
const _colorBorderDark = Color(0xFF314158); // slate/700
const _colorGreenDark = Color(0xFF22C55E); // lime-600
const _colorGreenShadowDark = Color(0xFF15803D);
const _colorBlueDark = Color(0xFF0EA5E9); // sky-500
const _colorBlueShadowDark = Color(0xFF0369A1);

// Helper to get colors based on brightness
({
  Color background,
  Color sectionBg,
  Color dark,
  Color muted,
  Color border,
  Color green,
  Color greenShadow,
  Color blue,
  Color blueShadow,
}) _getColors(bool isDark) {
  return isDark
      ? (
          background: _colorBackgroundDark,
          sectionBg: _colorSectionBgDark,
          dark: _colorDarkDark,
          muted: _colorMutedDark,
          border: _colorBorderDark,
          green: _colorGreenDark,
          greenShadow: _colorGreenShadowDark,
          blue: _colorBlueDark,
          blueShadow: _colorBlueShadowDark,
        )
      : (
          background: _colorBackgroundLight,
          sectionBg: _colorSectionBgLight,
          dark: _colorDarkLight,
          muted: _colorMutedLight,
          border: _colorBorderLight,
          green: _colorGreenLight,
          greenShadow: _colorGreenShadowLight,
          blue: _colorBlueLight,
          blueShadow: _colorBlueShadowLight,
        );
}

// ─── File type ────────────────────────────────────────────────────────────────
enum _FileType { document, image, audio, video, other }

_FileType _typeForFile(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  const docs = {
    'pdf', 'doc', 'docx', 'txt', 'md', 'xls', 'xlsx', 'ppt', 'pptx',
    'csv', 'rtf', 'odt', 'pages', 'numbers', 'key',
  };
  const images = {
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'webp', 'heic', 'heif',
    'tiff', 'tif',
  };
  const audio = {'mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma', 'opus'};
  const video = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v', '3gp', 'ts',
  };
  if (docs.contains(ext)) return _FileType.document;
  if (images.contains(ext)) return _FileType.image;
  if (audio.contains(ext)) return _FileType.audio;
  if (video.contains(ext)) return _FileType.video;
  return _FileType.other;
}

// ─── Filter type ──────────────────────────────────────────────────────────────
enum _FilterType { all, documents, images, audio, video, other }

extension _FilterTypeX on _FilterType {
  String get label => switch (this) {
        _FilterType.all => 'All',
        _FilterType.documents => 'Documents',
        _FilterType.images => 'Images',
        _FilterType.audio => 'Audio',
        _FilterType.video => 'Video',
        _FilterType.other => 'Other',
      };

  IconData get icon => switch (this) {
        _FilterType.all => Icons.apps_rounded,
        _FilterType.documents => Icons.description_outlined,
        _FilterType.images => Icons.image_outlined,
        _FilterType.audio => Icons.music_note_rounded,
        _FilterType.video => Icons.videocam_outlined,
        _FilterType.other => Icons.insert_drive_file_outlined,
      };

  // Maps a filter to the corresponding _FileType (null = all)
  _FileType? get fileType => switch (this) {
        _FilterType.all => null,
        _FilterType.documents => _FileType.document,
        _FilterType.images => _FileType.image,
        _FilterType.audio => _FileType.audio,
        _FilterType.video => _FileType.video,
        _FilterType.other => _FileType.other,
      };
}

// ─── File model ───────────────────────────────────────────────────────────────
class _ReceivedFile {
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
  final _FileType type;

  const _ReceivedFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.type,
  });

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(modifiedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[modifiedAt.month - 1]} '
        '${modifiedAt.day.toString().padLeft(2, '0')} '
        '${modifiedAt.year}';
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<_ReceivedFile> _allFiles = [];
  _FilterType _filter = _FilterType.all;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  // Same directory resolution logic as receive_screen.dart
  Future<Directory> _getQrDropDirectory() async {
    Directory? baseDir;

    if (Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
      if (baseDir != null) {
        final parts = baseDir.path.split('/');
        final androidIdx = parts.indexOf('Android');
        if (androidIdx > 0) {
          final storagePath = parts.sublist(0, androidIdx).join('/');
          baseDir = Directory('$storagePath/Download/QR Drop');
        }
      }
    }

    baseDir ??=
        Directory('${(await getApplicationDocumentsDirectory()).path}/TXQR');

    return baseDir;
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final dir = await _getQrDropDirectory();
      if (!await dir.exists()) {
        setState(() {
          _allFiles = [];
          _isLoading = false;
        });
        return;
      }

      final entities = await dir.list().toList();
      final files = <_ReceivedFile>[];

      for (final entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          final name = entity.path.split(Platform.pathSeparator).last;
          files.add(_ReceivedFile(
            name: name,
            path: entity.path,
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
            type: _typeForFile(name),
          ));
        }
      }

      // Newest first
      files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      setState(() {
        _allFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('HomeScreen: error loading files – $e');
      setState(() {
        _allFiles = [];
        _isLoading = false;
      });
    }
  }

  // ── Derived data ──────────────────────────────────────────────────────────

  List<_ReceivedFile> get _filteredFiles {
    final target = _filter.fileType;
    if (target == null) return _allFiles;
    return _allFiles.where((f) => f.type == target).toList();
  }

  List<MapEntry<String, List<_ReceivedFile>>> get _groupedFiles {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <_ReceivedFile>[];
    final yesterdayList = <_ReceivedFile>[];
    final olderList = <_ReceivedFile>[];

    for (final file in _filteredFiles) {
      final fileDay = DateTime(
          file.modifiedAt.year, file.modifiedAt.month, file.modifiedAt.day);
      if (fileDay.isAtSameMomentAs(today)) {
        todayList.add(file);
      } else if (fileDay.isAtSameMomentAs(yesterday)) {
        yesterdayList.add(file);
      } else {
        olderList.add(file);
      }
    }

    return [
      if (todayList.isNotEmpty) MapEntry('Today', todayList),
      if (yesterdayList.isNotEmpty) MapEntry('Yesterday', yesterdayList),
      if (olderList.isNotEmpty) MapEntry('Older', olderList),
    ];
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        current: _filter,
        onChanged: (f) {
          setState(() => _filter = f);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _openFile(_ReceivedFile file) async {
    final result = await OpenFilex.open(file.path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      final msg = switch (result.type) {
        ResultType.noAppToOpen => 'No app found to open this file type',
        ResultType.fileNotFound => 'File not found',
        ResultType.permissionDenied => 'Permission denied',
        _ => 'Could not open file',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _shareFile(file),
          ),
        ),
      );
    }
  }

  Future<void> _shareFile(_ReceivedFile file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteFile(_ReceivedFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${file.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await File(file.path).delete();
        _loadFiles();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final colors = _getColors(isDark);
    final filtered = _filteredFiles;
    final groups = _groupedFiles;
    final filterActive = _filter != _FilterType.all;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Drop',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: colors.dark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Transfer Files\nVia QR Codes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colors.dark,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.settings_outlined,
                        color: colors.dark,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      label: 'Send',
                      sublabel: 'Display QR codes',
                      color: colors.green,
                      shadowColor: colors.greenShadow,
                      icon: Icons.arrow_upward_rounded,
                      decorIcon: Icons.qr_code_2_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SendScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      label: 'Receive',
                      sublabel: 'Scan QR codes',
                      color: colors.blue,
                      shadowColor: colors.blueShadow,
                      icon: Icons.arrow_downward_rounded,
                      decorIcon: Icons.document_scanner_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReceiveScreen()),
                      ).then((_) => _loadFiles()), // reload after receiving
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Received Files section ────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.sectionBg,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        children: [
                          Text(
                            'Received Files',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: colors.dark,
                            ),
                          ),
                          const Spacer(),
                          // Active filter badge
                          if (filterActive)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _filter.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Icon(
                              Icons.filter_list_rounded,
                              color: filterActive ? colors.blue : colors.muted,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // File list / states
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.muted,
                              ),
                            )
                          : filtered.isEmpty
                              ? _EmptyState(
                                  hasAnyFiles: _allFiles.isNotEmpty,
                                  filterLabel: _filter.label,
                                  colors: colors,
                                  onClearFilter: filterActive
                                      ? () => setState(
                                          () => _filter = _FilterType.all)
                                      : null,
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadFiles,
                                  color: colors.blue,
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 24),
                                    children: [
                                      ...groups.map(
                                        (entry) => _FileGroup(
                                          groupLabel: entry.key,
                                          files: entry.value,
                                          colors: colors,
                                          onOpen: _openFile,
                                          onShare: _shareFile,
                                          onDelete: _deleteFile,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Text(
                                          'END OF LIST',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: colors.muted,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasAnyFiles;
  final String filterLabel;
  final VoidCallback? onClearFilter;
  final ({
    Color background,
    Color sectionBg,
    Color dark,
    Color muted,
    Color border,
    Color green,
    Color greenShadow,
    Color blue,
    Color blueShadow,
  }) colors;

  const _EmptyState({
    required this.hasAnyFiles,
    required this.filterLabel,
    required this.colors,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyFiles
                  ? Icons.filter_list_off_rounded
                  : Icons.inbox_outlined,
              size: 52,
              color: colors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyFiles ? 'No $filterLabel found' : 'No files yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyFiles
                  ? 'Try a different filter'
                  : 'Files you receive will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear filter'),
                style: TextButton.styleFrom(foregroundColor: colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  final _FilterType current;
  final ValueChanged<_FilterType> onChanged;

  const _FilterSheet({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final colors = _getColors(isDark);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'Filter by Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: colors.dark,
              ),
            ),
          ),
          ..._FilterType.values.map((filter) {
            final selected = filter == current;
            return ListTile(
              leading: Icon(
                filter.icon,
                color: selected ? colors.green : colors.muted,
              ),
              title: Text(
                filter.label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                  color: colors.dark,
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_rounded, color: colors.green)
                  : null,
              onTap: () => onChanged(filter),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Action card (Send / Receive) ─────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final Color shadowColor;
  final IconData icon;
  final IconData decorIcon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.shadowColor,
    required this.icon,
    required this.decorIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.24,
                  ),
                ),
              ],
            ),
            // Decorative icon – top-right
            Positioned(
              top: -8,
              right: -8,
              child: Icon(
                decorIcon,
                color: Colors.white.withValues(alpha: 0.20),
                size: 72,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── File group (Today / Yesterday / Older) ───────────────────────────────────
class _FileGroup extends StatelessWidget {
  final String groupLabel;
  final List<_ReceivedFile> files;
  final ValueChanged<_ReceivedFile> onOpen;
  final ValueChanged<_ReceivedFile> onShare;
  final ValueChanged<_ReceivedFile> onDelete;
  final ({
    Color background,
    Color sectionBg,
    Color dark,
    Color muted,
    Color border,
    Color green,
    Color greenShadow,
    Color blue,
    Color blueShadow,
  }) colors;

  const _FileGroup({
    required this.groupLabel,
    required this.files,
    required this.colors,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FileCard(
                file: file,
                colors: colors,
                onOpen: () => onOpen(file),
                onShare: () => onShare(file),
                onDelete: () => onDelete(file),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── File card ────────────────────────────────────────────────────────────────
class _FileCard extends StatelessWidget {
  final _ReceivedFile file;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final ({
    Color background,
    Color sectionBg,
    Color dark,
    Color muted,
    Color border,
    Color green,
    Color greenShadow,
    Color blue,
    Color blueShadow,
  }) colors;

  const _FileCard({
    required this.file,
    required this.colors,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  ({Color bg, Color icon, IconData iconData}) get _iconInfo {
    return switch (file.type) {
      _FileType.document => (
          bg: const Color(0x267C86FF),
          icon: const Color(0xFF7C86FF),
          iconData: Icons.description_outlined,
        ),
      _FileType.image => (
          bg: const Color(0x26FF8904),
          icon: const Color(0xFFFF8904),
          iconData: Icons.image_outlined,
        ),
      _FileType.audio => (
          bg: const Color(0x26FB64B6),
          icon: const Color(0xFFFB64B6),
          iconData: Icons.music_note_rounded,
        ),
      _FileType.video => (
          bg: const Color(0x261CB0F6),
          icon: const Color(0xFF1CB0F6),
          iconData: Icons.videocam_outlined,
        ),
      _FileType.other => (
          bg: const Color(0x2690A1B9),
          icon: const Color(0xFF90A1B9),
          iconData: Icons.insert_drive_file_outlined,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = _iconInfo;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: colors.sectionBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors.background,
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // File type icon
            Container(
              decoration: BoxDecoration(
                color: info.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(info.iconData, color: info.icon, size: 24),
            ),
            const SizedBox(width: 16),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        file.sizeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 4,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.muted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          file.timeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Share button
            IconButton(
              onPressed: onShare,
              icon: Icon(Icons.share_outlined,
                  color: colors.muted, size: 20),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            // Delete button
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
