import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/core/network/api_client.dart';
import 'package:reptran_app/features/profile/services/profile_service.dart';
import 'dart:async';
import 'package:transparent_image/transparent_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _dio = ApiClient().dio;
  bool _hasTypedUsername = false;

  Map<String, dynamic>? _user;
  Timer? _debounce;

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _usernameFocusNode;

  double _uploadProgress = 0;
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;

  File? _imageFile;
  String? _avatarUrl;

  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _nameFocusNode = FocusNode();
    _usernameFocusNode = FocusNode();
    _fetchUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _hasTypedUsername = true;
    if (value.trim() == _user?['username']) {
      setState(() {
        _isUsernameAvailable = true;
        _hasTypedUsername = false;
      });
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.trim().isEmpty) return;
      setState(() => _isCheckingUsername = true);
      try {
        final res = await _dio.get(
          '/user/check-username',
          queryParameters: {'username': value.trim()},
        );
        setState(() => _isUsernameAvailable = res.data['available']);
      } catch (e) {
      } finally {
        setState(() => _isCheckingUsername = false);
      }
    });
  }

  Future<void> _fetchUser() async {
    try {
      final profileService = ProfileService();
      final user = await profileService.getMeSummary();
      setState(() {
        _user = user;
        _nameController.text = user['name'] ?? '';
        _usernameController.text = user['username'] ?? '';
        _avatarUrl = user['avatarUrl'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load profile');
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;

      final imageFile = File(file.path);
      final profileService = ProfileService();

      setState(() {
        _imageFile = imageFile;
        _isUploadingImage = true;
        _uploadProgress = 0;
      });

      final avatarUrl = await profileService.uploadAvatar(
        imageFile,
        onSendProgress: (sent, total) {
          if (total != 0) {
            setState(() => _uploadProgress = (sent / total) * 0.95);
          }
        },
      );

      setState(() => _uploadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _avatarUrl = avatarUrl;
        _imageFile = null;
      });
    } catch (e) {
      _showErrorSnackBar('Image upload failed');
      setState(() => _imageFile = null);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (_usernameController.text.trim().isEmpty) return;

    if (!_isUsernameAvailable) {
      _showErrorSnackBar('Username is already taken');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ProfileService().updateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      if (!mounted) return;
      _showSuccessSnackBar();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      _showErrorSnackBar('Failed to update profile');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
        content: _SuccessSnackBarContent(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 3),
        content: _ErrorSnackBarContent(message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──
                  _Header(onBack: () => context.pop()),

                  const SizedBox(height: AppSpacing.lg),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        // ── AVATAR ──
                        _AvatarSection(
                          imageFile: _imageFile,
                          avatarUrl: _avatarUrl,
                          isUploading: _isUploadingImage,
                          uploadProgress: _uploadProgress,
                          onTap: _pickImage,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── FORM CARD ──
                        Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: AppBorders.boxCard(scheme),
                            boxShadow: AppShadows.e1(scheme),
                          ),
                          child: Column(
                            children: [
                              _InputField(
                                label: 'Full Name',
                                hint: 'Your display name',
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                prefixIcon: PhosphorIconsRegular.user,
                                textCapitalization: TextCapitalization.words,
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: scheme.outline.withValues(alpha: 0.08),
                              ),
                              _InputField(
                                label: 'Username',
                                hint: 'your_handle',
                                controller: _usernameController,
                                focusNode: _usernameFocusNode,
                                onChanged: _onUsernameChanged,
                                prefixIcon: PhosphorIconsRegular.at,
                                suffix: _buildUsernameSuffix(),
                                textCapitalization: TextCapitalization.none,
                              ),
                            ],
                          ),
                        ),

                        // ── USERNAME STATUS ──
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _hasTypedUsername
                              ? _UsernameStatus(
                                  isChecking: _isCheckingUsername,
                                  isAvailable: _isUsernameAvailable,
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // ── SAVE BUTTON ──
                        _SaveButton(
                          isLoading: _isSaving,
                          isDisabled: _isSaving || _isUploadingImage,
                          onTap: _save,
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildUsernameSuffix() {
    if (!_hasTypedUsername) return null;
    if (_isCheckingUsername) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    }
    if (_isUsernameAvailable) {
      return Icon(
        PhosphorIconsFill.checkCircle,
        size: 18,
        color: AppColors.positive,
      );
    }
    return Icon(
      PhosphorIconsFill.xCircle,
      size: 18,
      color: Colors.red.shade400,
    );
  }
}

// ─────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: const Icon(PhosphorIconsRegular.arrowLeft, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
         Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Edit Profile', style: tt.titleLarge),
      const SizedBox(height: 2),
      Text(
        'Update how you appear across RepTran',
        style: tt.bodySmall?.copyWith(
          color: scheme.onSurface.withValues(
            alpha: AppOpacities.secondary,
          ),
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// AVATAR SECTION
// ─────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.imageFile,
    required this.avatarUrl,
    required this.isUploading,
    required this.uploadProgress,
    required this.onTap,
  });

  final File? imageFile;
  final String? avatarUrl;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final displayProgress =
        uploadProgress < 0.05 ? 0.05 : (uploadProgress > 0.95 ? 0.95 : uploadProgress);
    final isProcessing = uploadProgress >= 0.95 && uploadProgress < 1;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring (progress ring or static border)
              SizedBox(
                width: 108,
                height: 108,
                child: isUploading
                    ? CircularProgressIndicator(
                        value: isProcessing ? null : displayProgress,
                        strokeWidth: 3,
                        backgroundColor:
                            scheme.outline.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 3,
                          ),
                        ),
                      ),
              ),

              // Avatar image
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surfaceVariant,
                  border: Border.all(
                    color: scheme.surface,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : avatarUrl != null
                          ? FadeInImage(
                              placeholder: MemoryImage(kTransparentImage),
                              image: NetworkImage(avatarUrl!),
                              fit: BoxFit.cover,
                              fadeInDuration:
                                  const Duration(milliseconds: 200),
                            )
                          : Icon(
                              PhosphorIconsRegular.user,
                              size: 36,
                              color: scheme.onSurface.withValues(alpha: 0.3),
                            ),
                ),
              ),

              // Upload overlay (dim + % text)
              if (isUploading)
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                  child: Center(
                    child: Text(
                      isProcessing
                          ? '...'
                          : '${(uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Camera badge
              if (!isUploading)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      PhosphorIconsFill.camera,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            isUploading ? 'Uploading photo...' : 'Change photo',
            style: tt.bodySmall?.copyWith(
              color: isUploading
                  ? scheme.onSurface.withValues(alpha: 0.4)
                  : AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// INPUT FIELD
// ─────────────────────────────────────────

class _InputField extends StatefulWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    this.onChanged,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final Function(String)? onChanged;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LABEL ──
          Text(
            widget.label,
            style: tt.labelSmall?.copyWith(
              color: _isFocused
                  ? AppColors.primary
                  : scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 6),

          // ── INPUT CONTAINER (adds elevation separation) ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color:
                            AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              textCapitalization: widget.textCapitalization,
              style: tt.bodyMedium,

              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: tt.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),

                // 🔥 KEY FIX: no transparency blending anymore
                filled: true,
           fillColor: scheme.surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),

                // ── PREFIX ──
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: _isFocused
                        ? AppColors.primary
                        : scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0),

                // ── SUFFIX ──
                suffixIcon: widget.suffix != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: widget.suffix,
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0),

                // ── BORDERS ──
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.2),
                  ),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.18),
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadii.md),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────
// USERNAME STATUS CHIP
// ─────────────────────────────────────────

class _UsernameStatus extends StatelessWidget {
  const _UsernameStatus({
    required this.isChecking,
    required this.isAvailable,
  });

  final bool isChecking;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (isChecking) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: AppSpacing.xs),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Checking availability...',
              style: tt.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    final color = isAvailable ? AppColors.positive : Colors.red.shade400;
    final icon = isAvailable
        ? PhosphorIconsFill.checkCircle
        : PhosphorIconsFill.xCircle;
    final label = isAvailable ? 'Username is available' : 'Username is taken';

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled
              ? AppColors.accent.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.whiteUtility,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsFill.checkCircle,
                    size: 18,
                    color: AppColors.whiteUtility,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save Changes',
                    style: tt.titleMedium?.copyWith(
                      color: AppColors.whiteUtility,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SUCCESS SNACKBAR
// ─────────────────────────────────────────

class _SuccessSnackBarContent extends StatelessWidget {
  const _SuccessSnackBarContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E1A),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.positive.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              PhosphorIconsFill.checkCircle,
              size: 18,
              color: AppColors.positive,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Profile updated',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your changes have been saved.',
                style: TextStyle(
                  color: Color(0xFF9CA89C),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ERROR SNACKBAR
// ─────────────────────────────────────────

class _ErrorSnackBarContent extends StatelessWidget {
  const _ErrorSnackBarContent({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1A1A),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              PhosphorIconsFill.xCircle,
              size: 18,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFA89C9C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}