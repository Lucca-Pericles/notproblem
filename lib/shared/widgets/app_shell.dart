import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/widgets/auth_scope.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentRoute,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String currentRoute;
  final Widget child;
  final List<Widget> actions;

  static const _destinations = [
    _NavigationItem(
      label: 'Visão geral',
      icon: Icons.home_outlined,
      route: AppRoutes.dashboard,
    ),
    _NavigationItem(
      label: 'Ocorrências',
      icon: Icons.warning_amber_rounded,
      route: AppRoutes.occurrences,
    ),
    _NavigationItem(
      label: 'Investigações',
      icon: Icons.search_rounded,
      route: AppRoutes.investigations,
    ),
    _NavigationItem(
      label: 'Ações',
      icon: Icons.task_alt_rounded,
      route: AppRoutes.actions,
    ),
    _NavigationItem(
      label: 'Histórico',
      icon: Icons.history_rounded,
      route: AppRoutes.history,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);
    final user = authController.user!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  currentRoute: currentRoute,
                  destinations: _destinations,
                  user: user,
                ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        actions: actions,
                        user: user,
                        onSignOut: authController.signOut,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: child,
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

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const _Brand(compact: true),
            actions: [
              ...actions,
              IconButton(
                tooltip: 'Sair',
                onPressed: authController.signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: AppColors.sidebar,
            child: SafeArea(
              child: _NavigationList(
                currentRoute: currentRoute,
                destinations: _destinations,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.actions,
    required this.user,
    required this.onSignOut,
  });

  final List<Widget> actions;
  final AppUser user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Spacer(),
          ...actions,
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Sair',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.infoSoft,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentRoute,
    required this.destinations,
    required this.user,
  });

  final String currentRoute;
  final List<_NavigationItem> destinations;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      color: AppColors.sidebar,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _Brand(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: _NavigationList(
              currentRoute: currentRoute,
              destinations: destinations,
            ),
          ),
          _ProfileSummary(user: user),
        ],
      ),
    );
  }
}

class _NavigationList extends StatelessWidget {
  const _NavigationList({
    required this.currentRoute,
    required this.destinations,
  });

  final String currentRoute;
  final List<_NavigationItem> destinations;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: destinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = destinations[index];
        final selected = currentRoute == item.route ||
            (item.route != AppRoutes.dashboard &&
                currentRoute.startsWith(item.route));

        return Material(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Icon(item.icon),
            title: Text(item.label),
            textColor: selected ? Colors.white : const Color(0xFFD7D8E8),
            iconColor: selected ? Colors.white : const Color(0xFFD7D8E8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              if (MediaQuery.sizeOf(context).width < 980) {
                Navigator.of(context).pop();
              }
              if (currentRoute != item.route) {
                Navigator.of(context).pushReplacementNamed(item.route);
              }
            },
          ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.layers_rounded, color: AppColors.primary, size: 30),
        const SizedBox(width: 10),
        Text(
          compact ? 'Agile Knowledge' : 'Agile Knowledge',
          style: TextStyle(
            color: compact ? AppColors.textPrimary : Colors.white,
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.infoSoft,
          child: Text(
            user.initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9EA0B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
