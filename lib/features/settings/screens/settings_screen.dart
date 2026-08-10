import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Shop Information'),
            _buildTextField('Shop Name', 'NextGen Supermarket'),
            _buildTextField('GST Number', '29ABCDE1234F1Z5'),
            _buildTextField('Address', '123 Main Street, City'),
            _buildTextField('Phone Number', '+91 9876543210'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Save Shop Info')),
            
            const Divider(height: 48),
            _buildSectionHeader(context, 'Printer Configuration'),
            ListTile(
              title: const Text('Default Receipt Printer'),
              subtitle: const Text('Generic 80mm Thermal Printer'),
              trailing: ElevatedButton(onPressed: () {}, child: const Text('Change')),
            ),
            ListTile(
              title: const Text('Paper Size'),
              subtitle: const Text('80mm'),
              trailing: DropdownButton<String>(
                value: '80mm',
                items: ['58mm', '80mm', 'A4']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {},
              ),
            ),
            
            const Divider(height: 48),
            _buildSectionHeader(context, 'Database & Backup'),
            ListTile(
              title: const Text('Local Database Path'),
              subtitle: const Text('C:\\Users\\User\\Documents\\nextgen_billing.db'),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.backup),
                  label: const Text('Backup Database'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore Database'),
                ),
              ],
            ),
            
            const Divider(height: 48),
            _buildSectionHeader(context, 'Appearance'),
            SwitchListTile(
              title: const Text('Dark Theme'),
              value: false,
              onChanged: (val) {
                // Toggle theme logic via Riverpod provider
              },
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

  Widget _buildTextField(String label, String placeholder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          hintText: placeholder,
        ),
      ),
    );
  }
}
