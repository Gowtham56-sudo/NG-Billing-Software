import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../database/sqlite_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _paperSize = '80mm';
  String _dbPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final db = await SqliteService.database;
      final maps = await db.query('settings');
      final Map<String, String> settingsMap = {
        for (var m in maps) m['key'] as String: m['value'] as String? ?? ''
      };

      _shopNameController.text = settingsMap['shop_name'] ?? 'NextGen Supermarket';
      _gstController.text = settingsMap['gst_number'] ?? '33AAAAA0000A1Z5';
      _addressController.text = settingsMap['address'] ?? '123 Main Road, City';
      _phoneController.text = settingsMap['phone'] ?? '+91 9876543210';
      _paperSize = settingsMap['paper_size'] ?? '80mm';

      final databasesPath = await databaseFactoryFfi.getDatabasesPath();
      _dbPath = p.join(databasesPath, 'nextgen_billing.db');
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final db = await SqliteService.database;
      final Map<String, String> toSave = {
        'shop_name': _shopNameController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'paper_size': _paperSize,
      };

      for (var entry in toSave.entries) {
        await db.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Shop Information saved successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _backupDatabase() async {
    try {
      final dbFile = File(_dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found at $_dbPath');
      }

      final desktopDir = Directory(p.join(Platform.environment['USERPROFILE'] ?? '', 'Desktop'));
      final targetDir = await desktopDir.exists() ? desktopDir : Directory.current;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final backupFileName = 'nextgen_billing_backup_$timestamp.db';
      final backupPath = p.join(targetDir.path, backupFileName);

      await dbFile.copy(backupPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Database backup saved to Desktop: $backupFileName'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store & Application Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Shop & Billing Information'),
            _buildTextField('Shop / Store Name', _shopNameController),
            _buildTextField('GST / Tax Number', _gstController),
            _buildTextField('Address', _addressController),
            _buildTextField('Contact Phone', _phoneController),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Shop Info'),
            ),
            
            const Divider(height: 48),
            _buildSectionHeader(context, 'Printer & Receipt Configuration'),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('Default Thermal Printer'),
              subtitle: const Text('ESC/POS Thermal Receipt Printer (USB / Network)'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.blue),
              title: const Text('Receipt Paper Size'),
              subtitle: Text(_paperSize),
              trailing: DropdownButton<String>(
                value: _paperSize,
                items: ['58mm', '80mm', 'A4']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _paperSize = val);
                    _saveSettings();
                  }
                },
              ),
            ),
            
            const Divider(height: 48),
            _buildSectionHeader(context, 'Database & Backup Management'),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.green),
              title: const Text('Local SQLite Database File'),
              subtitle: Text(_dbPath.isNotEmpty ? _dbPath : 'nextgen_billing.db'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _backupDatabase,
              icon: const Icon(Icons.backup),
              label: const Text('Backup Database to Desktop'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
