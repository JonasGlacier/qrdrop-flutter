import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isClearing = false;

  Future<void> _clearAppData() async {
    setState(() => _isClearing = true);
    try {
      // Clear cache directory
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      // Clear app data (files directory)
      final appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App data and cache cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  Future<void> _deleteReceivedFiles() async {
    setState(() => _isClearing = true);
    try {
      Directory? baseDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final pathParts = extDir.path.split('/');
          final storageIndex = pathParts.indexOf('Android');
          if (storageIndex > 0) {
            final storagePath = pathParts.sublist(0, storageIndex).join('/');
            baseDir = Directory('$storagePath/Download/QR Drop');
          }
        }
      }
      
      baseDir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/TXQR');

      if (await baseDir.exists()) {
        await baseDir.delete(recursive: true);
        await baseDir.create(recursive: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All received files deleted')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No received files found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting files: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isClearing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.orange),
                  title: const Text('Clear App Data & Cache'),
                  subtitle: const Text('Deletes temporary files and app state'),
                  onTap: () => _showConfirmDialog(
                    context,
                    'Clear App Data?',
                    'This will delete all app cache and internal data. This action cannot be undone.',
                    _clearAppData,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                  title: const Text('Delete Received Files'),
                  subtitle: const Text('Removes all files in the "QR Drop" folder'),
                  onTap: () => _showConfirmDialog(
                    context,
                    'Delete All Files?',
                    'This will permanently delete all files you have received using QR Drop.',
                    _deleteReceivedFiles,
                  ),
                ),
              ],
            ),
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
