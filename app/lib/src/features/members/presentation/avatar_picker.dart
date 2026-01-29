import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../ui/theme/app_theme.dart';

class AvatarPicker extends ConsumerStatefulWidget {
  final String? memberId;
  final String? initialAvatarPath;
  final int? initialAvatarColor;
  final void Function(String? path, int? color) onSelectionChanged;

  const AvatarPicker({
    super.key,
    this.memberId,
    this.initialAvatarPath,
    this.initialAvatarColor,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  String? _currentPath;
  int? _currentColor;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialAvatarPath;
    _currentColor = widget.initialAvatarColor;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (widget.memberId == null) {
      // If no memberId is provided, we can't save the avatar via service.
      // This case should be avoided by the caller for this version.
      return;
    }

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        setState(() => _isProcessing = true);
        final avatarService = ref.read(avatarServiceProvider);
        final path = await avatarService.saveAvatar(
          widget.memberId!,
          File(pickedFile.path),
        );
        setState(() {
          _currentPath = path;
          _currentColor = null;
          _isProcessing = false;
        });
        widget.onSelectionChanged(_currentPath, _currentColor);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _selectColor(int colorValue) {
    setState(() {
      _currentColor = colorValue;
      _currentPath = null;
    });
    widget.onSelectionChanged(_currentPath, _currentColor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Avatar',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),
            // Preview
            Center(
              child: Semantics(
                label: 'Avatar preview',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _currentColor != null
                          ? Color(_currentColor!)
                          : theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: _currentPath != null
                          ? FileImage(File(_currentPath!))
                          : null,
                      child: _currentPath == null && _currentColor == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    if (_isProcessing) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            // Image source actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                _ActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'Or select a color',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space16),
            // Color Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: AppTheme.space12,
                mainAxisSpacing: AppTheme.space12,
              ),
              itemCount: Member.presetColors.length,
              itemBuilder: (context, index) {
                final colorValue = Member.presetColors[index];
                final isSelected = _currentColor == colorValue;
                return Semantics(
                  button: true,
                  label: 'Preset color ${index + 1}',
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () => _selectColor(colorValue),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white, // Ensure visibility
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.space16),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentPath = null;
                  _currentColor = null;
                });
                widget.onSelectionChanged(null, null);
              },
              child: const Text('Clear Avatar'),
            ),
            const SizedBox(height: AppTheme.space8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 32,
            padding: const EdgeInsets.all(AppTheme.space16),
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTouchTarget,
              minHeight: AppTheme.minTouchTarget,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          ExcludeSemantics(child: Text(label)),
        ],
      ),
    );
  }
}
