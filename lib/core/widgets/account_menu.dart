import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';

/// Account actions anchored above the profile control in the navigation bar.
class AccountMenu extends StatefulWidget {
  const AccountMenu({
    super.key,
    required this.userName,
    required this.email,
    required this.role,
    required this.expanded,
    required this.alignRight,
    required this.onChangePassword,
    required this.onLogout,
  });

  final String userName;
  final String email;
  final String role;
  final bool expanded;
  final bool alignRight;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  State<AccountMenu> createState() => _AccountMenuState();
}

class _AccountMenuState extends State<AccountMenu>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );
  OverlayEntry? _entry;

  @override
  void didUpdateWidget(AccountMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _removeMenu();
    _controller.dispose();
    super.dispose();
  }

  void _removeMenu() {
    final entry = _entry;
    _entry = null;
    entry?.remove();
    entry?.dispose();
  }

  void _closeMenu() {
    _removeMenu();
    if (mounted) setState(() {});
  }

  void _toggleMenu() {
    if (_entry != null) {
      _closeMenu();
      return;
    }

    _entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: widget.alignRight
                  ? Alignment.topRight
                  : Alignment.topLeft,
              followerAnchor: widget.alignRight
                  ? Alignment.bottomRight
                  : Alignment.bottomLeft,
              offset: const Offset(0, -8),
              child: FadeTransition(
                opacity: _controller,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutCubic,
                  ),
                  alignment: widget.alignRight
                      ? Alignment.bottomRight
                      : Alignment.bottomLeft,
                  child: _menuPanel(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
    _controller.forward(from: 0);
    setState(() {});
  }

  Widget _menuPanel(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _closeMenu();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: Material(
      key: const Key('account-menu-panel'),
      color: AppColors.surfaceWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (widget.email.isNotEmpty)
                    Text(
                      widget.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    widget.role,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_outline, size: 20),
              title: const Text('Cambiar contraseña'),
              onTap: () {
                _closeMenu();
                widget.onChangePassword();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, size: 20),
              title: const Text('Cerrar sesión'),
              onTap: () {
                _closeMenu();
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _layerLink,
    child: Tooltip(
      message: 'Perfil',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: _toggleMenu,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: widget.expanded
              ? Container(
                  width: 228,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.person_outline,
                          size: 20,
                          color: AppColors.surfaceWhite,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              'Perfil',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _entry == null
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                )
              : const SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_circle_outlined),
                      SizedBox(height: AppSpacing.xs),
                      Text('Perfil'),
                    ],
                  ),
                ),
        ),
      ),
    ),
  );
}
