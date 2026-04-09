import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/language_model.dart';
import '../services/language_service.dart';
import '../widgets/topbar.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _flagController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _flagController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({LanguageModel? language}) {
    if (language != null) {
      _nameController.text = language.name;
      _codeController.text = language.code;
      _flagController.text = language.flag ?? '';
    } else {
      _nameController.clear();
      _codeController.clear();
      _flagController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(language == null ? 'Add Language' : 'Edit Language'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Language Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Language Code (ISO 639-1) *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., en, es, fr, de',
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _flagController,
                decoration: const InputDecoration(
                  labelText: 'Flag Emoji (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 🇺🇸, 🇬🇧, 🇫🇷',
                ),
                maxLength: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and code are required')),
                );
                return;
              }

              final languageData = LanguageModel(
                id: language?.id ?? '',
                name: _nameController.text.trim(),
                code: _codeController.text.trim().toLowerCase(),
                flag: _flagController.text.trim(),
                isActive: language?.isActive ?? true,
                isDefault: language?.isDefault ?? false,
                createdAt: language?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                if (language == null) {
                  await LanguageService.addLanguage(languageData);
                } else {
                  await LanguageService.updateLanguage(languageData);
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        language == null
                            ? 'Language added successfully'
                            : 'Language updated successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Language Settings', subtitle: 'Manage app languages'),
        Expanded(
          child: StreamBuilder<List<LanguageModel>>(
            stream: LanguageService.watchAllLanguages(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final languages = snapshot.data ?? [];

              if (languages.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No languages added yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Language')),
                    DataColumn(label: Text('Code')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Default')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: languages.map((language) {
                    return DataRow(
                      cells: [
                        DataCell(Row(
                          children: [
                            if (language.flag != null) ...[
                              Text(language.flag!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                            ],
                            Text(language.name),
                          ],
                        )),
                        DataCell(Text(language.code.toUpperCase())),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: language.isActive
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              language.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: language.isActive
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          language.isDefault
                              ? const Icon(Icons.star, color: Colors.amber)
                              : const SizedBox.shrink(),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showAddEditDialog(language: language),
                                tooltip: 'Edit',
                              ),
                              if (!language.isDefault)
                                IconButton(
                                  icon: const Icon(Icons.star_border, color: Colors.amber),
                                  onPressed: () async {
                                    await LanguageService.setDefaultLanguage(language.id);
                                  },
                                  tooltip: 'Set as Default',
                                ),
                              IconButton(
                                icon: Icon(
                                  language.isActive ? Icons.toggle_on : Icons.toggle_off,
                                  size: 18,
                                  color: language.isActive ? Colors.green : Colors.red,
                                ),
                                onPressed: () async {
                                  await LanguageService.toggleLanguageStatus(
                                    language.id,
                                    !language.isActive,
                                  );
                                },
                                tooltip: language.isActive ? 'Deactivate' : 'Activate',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Language'),
                                      content: Text(
                                        'Are you sure you want to delete "${language.name}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await LanguageService.deleteLanguage(language.id);
                                  }
                                },
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Language'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
