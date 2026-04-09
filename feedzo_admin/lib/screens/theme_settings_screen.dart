import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/theme_model.dart';
import '../services/theme_service.dart';
import '../widgets/topbar.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _primaryColorController = TextEditingController(text: '#FF6B35');
  final _secondaryColorController = TextEditingController(text: '#FF9F1C');
  final _bgColorController = TextEditingController(text: '#FFFFFF');
  final _textColorController = TextEditingController(text: '#333333');
  bool _isDark = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _bgColorController.dispose();
    _textColorController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({ThemeModel? theme}) {
    if (theme != null) {
      _nameController.text = theme.name;
      _descriptionController.text = theme.description;
      _primaryColorController.text = theme.primaryColor;
      _secondaryColorController.text = theme.secondaryColor;
      _bgColorController.text = theme.backgroundColor;
      _textColorController.text = theme.textColor;
      _isDark = theme.isDark;
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _primaryColorController.text = '#FF6B35';
      _secondaryColorController.text = '#FF9F1C';
      _bgColorController.text = '#FFFFFF';
      _textColorController.text = '#333333';
      _isDark = false;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(theme == null ? 'Add Theme' : 'Edit Theme'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Theme Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorPicker(
                          _primaryColorController,
                          'Primary Color',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildColorPicker(
                          _secondaryColorController,
                          'Secondary Color',
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorPicker(
                          _bgColorController,
                          'Background Color',
                          Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildColorPicker(
                          _textColorController,
                          'Text Color',
                          Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Theme'),
                    subtitle: const Text('Enable dark mode for this theme'),
                    value: _isDark,
                    onChanged: (v) => setDialogState(() => _isDark = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme name is required')),
                  );
                  return;
                }

                final themeData = ThemeModel(
                  id: theme?.id ?? '',
                  name: _nameController.text.trim(),
                  description: _descriptionController.text.trim(),
                  primaryColor: _primaryColorController.text.trim(),
                  secondaryColor: _secondaryColorController.text.trim(),
                  backgroundColor: _bgColorController.text.trim(),
                  textColor: _textColorController.text.trim(),
                  isDark: _isDark,
                  isActive: theme?.isActive ?? false,
                  createdAt: theme?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  if (theme == null) {
                    await ThemeService.addTheme(themeData);
                  } else {
                    await ThemeService.updateTheme(themeData);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          theme == null
                              ? 'Theme added successfully'
                              : 'Theme updated successfully',
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
      ),
    );
  }

  Widget _buildColorPicker(TextController controller, String label, Color defaultColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(controller.text, defaultColor),
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '#RRGGBB',
                  border: OutlineInputBorder(),
                ),
                maxLength: 7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _parseColor(String color, Color defaultColor) {
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (e) {
      return defaultColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Theme Settings', subtitle: 'Manage app themes'),
        Expanded(
          child: StreamBuilder<List<ThemeModel>>(
            stream: ThemeService.watchAllThemes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final themes = snapshot.data ?? [];

              if (themes.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.palette, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No themes added yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: themes.length,
                  itemBuilder: (context, index) {
                    final theme = themes[index];
                    return Card(
                      elevation: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _parseColor(theme.backgroundColor, Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      theme.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _parseColor(theme.textColor, Colors.black),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (theme.isActive)
                                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _parseColor(theme.primaryColor, Colors.orange),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _parseColor(theme.secondaryColor, Colors.amber),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _showAddEditDialog(theme: theme),
                                    tooltip: 'Edit',
                                  ),
                                  if (!theme.isActive)
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      onPressed: () async {
                                        await ThemeService.setDefaultTheme(theme.id);
                                      },
                                      tooltip: 'Set as Active',
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Theme'),
                                          content: Text(
                                            'Are you sure you want to delete "${theme.name}"?',
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
                                        await ThemeService.deleteTheme(theme.id);
                                      }
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
              label: const Text('Add Theme'),
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
