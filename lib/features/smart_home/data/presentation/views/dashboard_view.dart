import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/core/theme/app_theme.dart';
import 'package:smarthome/features/smart_home/data/Models/device_model.dart';
import 'package:smarthome/features/smart_home/data/Models/room_model.dart';
import 'package:smarthome/features/smart_home/data/presentation/cubit/home_cubit.dart';
import 'package:smarthome/features/smart_home/data/presentation/views/profile_view.dart';
import 'package:smarthome/features/smart_home/data/repositories/smart_home_repository.dart';


const _kPurple = Color(0xFF7B6EF5);
const _kPurpleDark = Color(0xFF9E5CF6);


class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _homeId = 'home_alpha';
  StreamSubscription? _homeSub;

  @override
  void initState() {
    super.initState();
    _subscribeToUserHome();
  }

  void _subscribeToUserHome() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _homeSub = FirebaseDatabase.instance
          .ref('users/${user.uid}/homeId')
          .onValue
          .listen((event) {
        if (!mounted) return;
        final val = event.snapshot.value;
        if (val is String && val.isNotEmpty && val != _homeId) {
          setState(() => _homeId = val);
        }
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _homeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(_homeId),
      create: (_) =>
          HomeCubit(SmartHomeRepository())..initStreams(_homeId, 'living_room'),
      child: _DashboardScaffold(homeId: _homeId, roomId: 'living_room'),
    );
  }
}


class _DashboardScaffold extends StatefulWidget {
  final String homeId;
  final String roomId;
  const _DashboardScaffold({required this.homeId, required this.roomId});

  @override
  State<_DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<_DashboardScaffold>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Room, 1 = Devices
  int _navIndex = 0;

  late final _micController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _micController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCol,
      extendBody: true,
      body: IndexedStack(
        index: _navIndex,
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildWeatherCard()),
                SliverToBoxAdapter(child: _buildQuickScenesBar()),
                SliverToBoxAdapter(child: _buildTabSelector()),
                if (_selectedTab == 1)
                  SliverToBoxAdapter(
                    child: BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) {
                        if (state is! HomeLoaded || state.rooms.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final currentRoomId = state.selectedRoomId ??
                            (state.rooms.isNotEmpty ? state.rooms.first.id : '');
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: state.rooms.map((r) {
                                final isSel = r.id == currentRoomId;
                                return GestureDetector(
                                  onTap: () => context
                                      .read<HomeCubit>()
                                      .selectRoom(r.id),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? _kPurple : context.cardCol,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSel
                                              ? _kPurple.withValues(alpha: 0.3)
                                              : Colors.black.withValues(
                                                  alpha: context.isDarkMode
                                                      ? 0.2
                                                      : 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.meeting_room_rounded,
                                          size: 14,
                                          color: isSel
                                              ? Colors.white
                                              : context.textSecondaryCol,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          r.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isSel
                                                ? Colors.white
                                                : context.textPrimaryCol,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  sliver: BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoading) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: _kPurple),
                          ),
                        );
                      }
                      if (state is HomeError) {
                        return SliverFillRemaining(
                          child: Center(
                              child: Text(state.message,
                                  style: const TextStyle(
                                      color: Colors.redAccent))),
                        );
                      }
                      if (state is HomeLoaded) {
                        return _selectedTab == 0
                            ? _RoomGrid(
                                rooms: state.rooms,
                                homeId: widget.homeId,
                                onSelectRoom: (roomId) {
                                  context.read<HomeCubit>().selectRoom(roomId);
                                  setState(() => _selectedTab = 1);
                                },
                              )
                            : _DeviceGrid(
                                devices: state.devices,
                                homeId: widget.homeId,
                                roomId: state.selectedRoomId ?? widget.roomId,
                              );
                      }
                      return const SliverToBoxAdapter(child: SizedBox());
                    },
                  ),
                ),
              ],
            ),
          ),
          const ProfileView(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildMicFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  Widget _buildHeader() {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) =>
          curr is HomeLoaded &&
          (prev is! HomeLoaded || prev.homeName != curr.homeName),
      builder: (context, state) {
        final title = (state is HomeLoaded &&
                state.homeName != null &&
                state.homeName!.isNotEmpty)
            ? state.homeName!
            : 'Home';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimaryCol,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  _FamilyAvatars(
                    homeId: widget.homeId,
                    onTap: () => setState(() => _navIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  const _ThemeToggleButton(),
                  const SizedBox(width: 8),
                  _SettingsButton(onTap: () => setState(() => _navIndex = 1)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildWeatherCard() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        String location = 'My Villa';
        String statusText = 'Sensors Normal';
        String tempDisplay = '26.5°';
        String subText = 'Indoor Climate';
        IconData weatherIcon = Icons.wb_sunny_rounded;

        if (state is HomeLoaded) {
          if (state.homeName != null && state.homeName!.isNotEmpty) {
            location = state.homeName!;
          }

          RoomModel? sensorRoom;
          if (state.selectedRoomId != null) {
            try {
              sensorRoom = state.rooms.firstWhere(
                (r) =>
                    r.id == state.selectedRoomId &&
                    r.sensors?.temperature != null,
              );
            } catch (_) {}
          }
          if (sensorRoom == null && state.rooms.isNotEmpty) {
            for (final r in state.rooms) {
              if (r.sensors?.temperature != null) {
                sensorRoom = r;
                break;
              }
            }
          }

          if (sensorRoom != null && sensorRoom.sensors != null) {
            location = sensorRoom.name;
            final t = sensorRoom.sensors!.temperature;
            final h = sensorRoom.sensors!.humidity;
            if (t != null) {
              tempDisplay = '${t.toStringAsFixed(1)}°';
            }
            if (h != null) {
              statusText = 'Humidity: ${h.toInt()}%';
              subText = 'Live RTDB Sensor';
              weatherIcon = Icons.thermostat_rounded;
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B80F9), Color(0xFF9B5DFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Environment',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(weatherIcon, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tempDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildQuickScenesBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Scenes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryCol,
                ),
              ),
              Text(
                '1-Tap Automation',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondaryCol,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ScenePill(
                  icon: Icons.nightlight_round,
                  label: 'Night Mode',
                  subtitle: 'Turn Off All',
                  accentColor: const Color(0xFF5DBEF5),
                  onTap: () async {
                    await context.read<HomeCubit>().toggleAllDevicesInHome(false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.nightlight_round,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('🌙 Night mode activated: All devices turned OFF'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF191C2E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                _ScenePill(
                  icon: Icons.lightbulb_rounded,
                  label: 'Awake Mode',
                  subtitle: 'Turn On All',
                  accentColor: const Color(0xFFF5A25D),
                  onTap: () async {
                    await context.read<HomeCubit>().toggleAllDevicesInHome(true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.lightbulb_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('💡 Awake mode activated: All devices turned ON'),
                            ],
                          ),
                          backgroundColor: _kPurple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                _ScenePill(
                  icon: context.isDarkMode
                      ? Icons.wb_sunny_rounded
                      : Icons.dark_mode_rounded,
                  label: context.isDarkMode ? 'Light UI' : 'Night UI',
                  subtitle: 'Toggle Theme',
                  accentColor: const Color(0xFF9E5CF6),
                  onTap: () => toggleAppTheme(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF191C2E)
              : const Color(0xFFEAECF4),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _TabPill(
              label: 'Room',
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _TabPill(
              label: 'Devices',
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoiceAssistantModal(
        homeId: widget.homeId,
        homeCubit: context.read<HomeCubit>(),
      ),
    );
  }


  Widget _buildMicFAB() {
    return AnimatedBuilder(
      animation: _micController,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kPurple
                    .withValues(alpha: 0.25 + 0.15 * _micController.value),
                blurRadius: 20 + 10 * _micController.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton(
        backgroundColor: context.cardCol,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: () => _showVoiceAssistantSheet(context),
        child: const Icon(Icons.mic_rounded, color: _kPurple, size: 30),
      ),
    );
  }


  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
              const Spacer(), // room for FAB
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: _navIndex == 1,
                onTap: () => setState(() => _navIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? context.cardCol : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: context.isDarkMode ? 0.2 : 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isSelected ? context.textPrimaryCol : context.textSecondaryCol,
            ),
          ),
        ),
      ),
    );
  }
}


class _FamilyAvatars extends StatelessWidget {
  final String homeId;
  final VoidCallback onTap;

  const _FamilyAvatars({
    required this.homeId,
    required this.onTap,
  });

  static const _gradients = [
    [Color(0xFF7B6EF5), Color(0xFF9E5CF6)],
    [Color(0xFF5DBEF5), Color(0xFF3892F7)],
    [Color(0xFFF5A25D), Color(0xFFFA7268)],
    [Color(0xFFF55D8A), Color(0xFFE040FB)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
  ];

  void _openFamilySheet(
      BuildContext context, List<Map<String, dynamic>> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FamilyMembersSheet(
        homeId: homeId,
        members: members,
        onGoToProfile: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('homes/$homeId/members').onValue,
      builder: (context, snapshot) {
        final members = <Map<String, dynamic>>[];
        final val = snapshot.data?.snapshot.value;

        if (val is Map) {
          final map = Map<dynamic, dynamic>.from(val);
          int i = 0;
          map.forEach((k, v) {
            if (v is Map) {
              final name = (v['name'] as String?) ?? 'Member';
              final role = (v['role'] as String?) ?? 'Member';
              members.add({
                'id': k.toString(),
                'name': name,
                'role': '${role[0].toUpperCase()}${role.substring(1)}',
                'initial': name.isNotEmpty ? name[0].toUpperCase() : 'M',
                'gradient': _gradients[i % _gradients.length],
              });
              i++;
            }
          });
        }

        if (members.isEmpty) {
          final user = FirebaseAuth.instance.currentUser;
          final userInit = (user?.displayName?.isNotEmpty == true)
              ? user!.displayName![0].toUpperCase()
              : ((user?.email?.isNotEmpty == true)
                  ? user!.email![0].toUpperCase()
                  : 'M');
          members.add({
            'id': user?.uid ?? 'user_1',
            'name': user?.displayName ?? 'You (Owner)',
            'role': 'Owner',
            'initial': userInit,
            'gradient': _gradients[0],
          });
        }

        final visibleCount = members.length > 3 ? 3 : members.length;
        final extraCount = members.length - visibleCount;
        final stackWidth =
            (visibleCount * 22.0) + (extraCount > 0 ? 32.0 : 18.0);

        return GestureDetector(
          onTap: () => _openFamilySheet(context, members),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: context.cardCol,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: context.isDarkMode ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(
              width: stackWidth,
              height: 32,
              child: Stack(
                children: [
                  ...List.generate(visibleCount, (i) {
                    final m = members[i];
                    final grad = m['gradient'] as List<Color>;
                    return Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: grad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: grad[0].withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m['initial'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (extraCount > 0)
                    Positioned(
                      left: visibleCount * 20.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.cardSubtleCol,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.cardCol,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$extraCount',
                          style: TextStyle(
                            color: context.textPrimaryCol,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class _FamilyMembersSheet extends StatefulWidget {
  final String homeId;
  final List<Map<String, dynamic>> members;
  final VoidCallback onGoToProfile;

  const _FamilyMembersSheet({
    required this.homeId,
    required this.members,
    required this.onGoToProfile,
  });

  @override
  State<_FamilyMembersSheet> createState() => _FamilyMembersSheetState();
}

class _FamilyMembersSheetState extends State<_FamilyMembersSheet> {
  void _showAddMemberDialog() {
    final nameCtrl = TextEditingController();
    String selectedRole = 'Member';
    final roles = ['Admin', 'Member', 'Child', 'Guest'];

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: context.cardCol,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.person_add_rounded, color: _kPurple),
              const SizedBox(width: 8),
              Text(
                'Add Family Member',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: context.textPrimaryCol,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter family member name and role in your home.',
                style: TextStyle(fontSize: 12, color: context.textSecondaryCol),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: context.textPrimaryCol),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: context.textSecondaryCol),
                  hintText: 'e.g. Sarah Miller',
                  hintStyle: TextStyle(color: context.textSecondaryCol),
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: context.textSecondaryCol,
                  ),
                  filled: true,
                  fillColor: context.inputFillCol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Role',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryCol,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: roles.map((r) {
                  final isSel = selectedRole == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: isSel,
                    selectedColor: _kPurple,
                    backgroundColor: context.cardSubtleCol,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : context.textPrimaryCol,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setDlgState(() => selectedRole = r),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.textSecondaryCol),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dlgCtx);

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final memberId =
                    'member_${DateTime.now().millisecondsSinceEpoch}';
                await FirebaseDatabase.instance
                    .ref('homes/${widget.homeId}/members/$memberId')
                    .set({
                  'name': name,
                  'role': selectedRole.toLowerCase(),
                });

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('$name added to family members!'),
                      backgroundColor: _kPurple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Add Member',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white24
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimaryCol,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.members.length} members with property access',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryCol,
                    ),
                  ),
                ],
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: _kPurple.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_rounded,
                    color: _kPurple, size: 20),
                onPressed: _showAddMemberDialog,
              ),
            ],
          ),
          const SizedBox(height: 18),

          ...widget.members.map((m) {
            final grad = (m['gradient'] is List<Color>)
                ? m['gradient'] as List<Color>
                : [const Color(0xFF7B6EF5), const Color(0xFF9E5CF6)];
            final role = (m['role'] as String?) ?? 'Member';
            final isOwnerOrAdmin =
                role.toLowerCase() == 'owner' || role.toLowerCase() == 'admin';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.cardSubtleCol,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: grad,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (m['initial'] as String?) ?? 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  (m['name'] as String?) ?? 'Member',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.textPrimaryCol,
                  ),
                ),
                subtitle: Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryCol,
                  ),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOwnerOrAdmin
                        ? _kPurple.withValues(alpha: 0.12)
                        : (context.isDarkMode
                            ? const Color(0xFF23273D)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isOwnerOrAdmin
                          ? _kPurple
                          : context.textSecondaryCol,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kPurple),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.person_add_rounded,
                      color: _kPurple, size: 18),
                  label: const Text('Add Member',
                      style: TextStyle(
                          color: _kPurple, fontWeight: FontWeight.bold)),
                  onPressed: _showAddMemberDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPurple,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 18),
                  label: const Text('Manage',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onGoToProfile();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: () => toggleAppTheme(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(isDark),
            color: isDark ? const Color(0xFFF5A25D) : _kPurple,
            size: 20,
          ),
        ),
      ),
    );
  }
}


class _ScenePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ScenePill({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 16),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryCol,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondaryCol,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _SettingsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: context.isDarkMode ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.settings_outlined,
            color: context.textPrimaryCol, size: 20),
      ),
    );
  }
}


class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? _kPurple : context.textSecondaryCol,
                size: 26),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: selected ? 18 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: _kPurple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _RoomGrid extends StatelessWidget {
  final List<RoomModel> rooms;
  final String homeId;
  final ValueChanged<String>? onSelectRoom;

  const _RoomGrid({
    required this.rooms,
    required this.homeId,
    this.onSelectRoom,
  });

  static final _demoRooms = [
    RoomModel(
      id: 'living_room',
      name: 'Living Room',
      deviceCount: 2,
      status: 0,
      imageAsset: 'assets/rooms/living.jpg',
      sensors: const RoomSensors(temperature: 26.5, humidity: 45),
    ),
    RoomModel(
      id: 'master_bedroom',
      name: 'Master Bedroom',
      deviceCount: 4,
      status: 1,
      imageAsset: 'assets/rooms/bedroom.jpg',
      sensors: const RoomSensors(temperature: 24.0, humidity: 50),
    ),
    RoomModel(
      id: 'dining_room',
      name: 'Dining Room',
      deviceCount: 3,
      status: 0,
      imageAsset: 'assets/rooms/dining.jpg',
    ),
    RoomModel(
      id: 'laundry',
      name: 'Laundry',
      deviceCount: 2,
      status: 0,
      imageAsset: 'assets/rooms/laundry.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayRooms = rooms.isEmpty ? _demoRooms : rooms;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final room = displayRooms[index];
          return _RoomCard(
            room: room,
            homeId: homeId,
            onTap: () => onSelectRoom?.call(room.id),
          );
        },
        childCount: displayRooms.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
    );
  }
}


class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final String homeId;
  final VoidCallback? onTap;

  const _RoomCard({
    required this.room,
    required this.homeId,
    this.onTap,
  });

  static const _roomGradients = {
    'living_room': [Color(0xFF11998E), Color(0xFF38EF7D)],
    'master_bedroom': [Color(0xFF667EEA), Color(0xFF764BA2)],
    'dining_room': [Color(0xFFFC4A1A), Color(0xFFF7B733)],
    'laundry': [Color(0xFF4776E6), Color(0xFF8E54E9)],
  };

  @override
  Widget build(BuildContext context) {
    final isOn = room.status == 1;
    final gradColors = _roomGradients[room.id] ??
        [const Color(0xFF7B6EF5), const Color(0xFF9E5CF6)];

    return Container(
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: context.isDarkMode ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    if (!isOn)
                      Container(
                        color: context.isDarkMode
                            ? Colors.black.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    Positioned(
                      top: 8,
                      right: 4,
                      child: _MoreButton(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryCol,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${room.deviceCount} Devices',
                          style: TextStyle(
                              fontSize: 11, color: context.textSecondaryCol),
                        ),
                        if (room.sensors != null &&
                            (room.sensors!.temperature != null ||
                                room.sensors!.humidity != null))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                if (room.sensors!.temperature != null) ...[
                                  const Icon(Icons.thermostat_rounded,
                                      size: 13, color: _kPurple),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${room.sensors!.temperature!.toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryCol,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (room.sensors!.humidity != null) ...[
                                  const Icon(Icons.water_drop_rounded,
                                      size: 11, color: Colors.blueAccent),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${room.sensors!.humidity!.toInt()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryCol,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isOn ? _kPurple : context.textSecondaryCol,
                        ),
                      ),
                      _SmallSwitch(
                        value: isOn,
                        onChanged: (_) => context
                            .read<HomeCubit>()
                            .toggleRoom(homeId, room),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DeviceGrid extends StatelessWidget {
  final List<DeviceModel> devices;
  final String homeId;
  final String roomId;

  const _DeviceGrid({
    required this.devices,
    required this.homeId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.devices_other_rounded,
                    color: _kPurple, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'No Devices Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryCol,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a room with devices above or add new devices in Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.textSecondaryCol),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final device = devices[index];
          return _DeviceCard(
            device: device,
            homeId: homeId,
            roomId: roomId,
          );
        },
        childCount: devices.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
      ),
    );
  }
}


class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final String homeId;
  final String roomId;

  const _DeviceCard({
    required this.device,
    required this.homeId,
    required this.roomId,
  });

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeviceDetailsSheet(
        device: device,
        homeId: homeId,
        roomId: roomId,
        homeCubit: context.read<HomeCubit>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOn = device.status == 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetails(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? _kPurple.withValues(alpha: 0.12)
                  : Colors.black
                      .withValues(alpha: context.isDarkMode ? 0.2 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DeviceIconWidget(
                  type: device.type,
                  deviceId: device.id,
                  isOn: isOn,
                ),
                if (device.mode != null && device.mode!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final modes = ['cool', 'heat', 'fan', 'auto'];
                      final current = device.mode!.toLowerCase();
                      final next =
                          modes[(modes.indexOf(current) + 1) % modes.length];
                      context
                          .read<HomeCubit>()
                          .setDeviceMode(homeId, roomId, device, next);
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOn
                            ? _kPurple.withValues(alpha: 0.15)
                            : context.cardSubtleCol,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            device.mode!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isOn ? _kPurple : context.textSecondaryCol,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 11,
                            color: isOn ? _kPurple : context.textSecondaryCol,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _MoreButton(onTap: () => _openDetails(context)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.textPrimaryCol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  device.subtitle,
                  style: TextStyle(color: context.textSecondaryCol, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isOn ? _kPurple : context.textSecondaryCol,
                  ),
                ),
                _SmallSwitch(
                  value: isOn,
                  onChanged: (_) => context
                      .read<HomeCubit>()
                      .toggleDevice(homeId, roomId, device),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _DeviceIconWidget extends StatelessWidget {
  final String type;
  final String deviceId;
  final bool isOn;

  const _DeviceIconWidget({
    required this.type,
    required this.deviceId,
    required this.isOn,
  });

  IconData _icon() {
    final t = type.toLowerCase();
    final dId = deviceId.toLowerCase();

    if (t == 'climate' || t == 'ac') {
      return Icons.ac_unit_rounded;
    }
    if (t == 'relay') {
      if (dId.contains('light') || dId.contains('lamp')) {
        return Icons.lightbulb_rounded;
      }
      return Icons.power_rounded;
    }
    switch (t) {
      case 'heater':
        return Icons.heat_pump_rounded;
      case 'light':
        return Icons.lightbulb_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'speaker':
        return Icons.speaker_rounded;
      case 'fan':
        return Icons.cyclone_rounded;
      default:
        return Icons.power_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: isOn
            ? [_kPurple, _kPurpleDark]
            : [context.textSecondaryCol, context.textSecondaryCol],
      ).createShader(bounds),
      child: Icon(_icon(), size: 40, color: Colors.white),
    );
  }
}


class _MoreButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _MoreButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.cardSubtleCol,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz_rounded,
            color: context.textSecondaryCol, size: 16),
      ),
    );
  }
}

class _SmallSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SmallSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: Switch.adaptive(
        value: value,
        activeThumbColor: _kPurple,
        activeTrackColor: _kPurple.withValues(alpha: 0.5),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: context.isDarkMode
            ? const Color(0xFF383C56)
            : const Color(0xFFDEDFF0),
        onChanged: onChanged,
      ),
    );
  }
}


class _VoiceAssistantModal extends StatefulWidget {
  final String homeId;
  final HomeCubit homeCubit;

  const _VoiceAssistantModal({
    required this.homeId,
    required this.homeCubit,
  });

  @override
  State<_VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<_VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  final TextEditingController _cmdCtrl = TextEditingController();
  String _assistantFeedback = 'Listening... Say or select a command below.';
  bool _isProcessing = false;

  @override
  void dispose() {
    _pulseController.dispose();
    _cmdCtrl.dispose();
    super.dispose();
  }

  void _executeCommand(String command) async {
    final lower = command.toLowerCase().trim();
    setState(() {
      _isProcessing = true;
      _assistantFeedback = 'Processing: "$command"...';
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (lower.contains('night') ||
        (lower.contains('off') &&
            (lower.contains('all') || lower.contains('everything')))) {
      await widget.homeCubit.toggleAllDevicesInHome(false);
      if (mounted) {
        setState(() {
          _assistantFeedback = '🌙 Night mode activated: All devices turned OFF.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('on') &&
        (lower.contains('all') || lower.contains('everything'))) {
      await widget.homeCubit.toggleAllDevicesInHome(true);
      if (mounted) {
        setState(() {
          _assistantFeedback = '💡 All devices turned ON.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('cool') || lower.contains('cold')) {
      final state = widget.homeCubit.state;
      if (state is HomeLoaded) {
        for (final d in state.devices) {
          if (d.type == 'climate' || d.type == 'ac') {
            await widget.homeCubit.setDeviceMode(
              widget.homeId,
              state.selectedRoomId ?? 'living_room',
              d,
              'cool',
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _assistantFeedback = '❄️ Climate mode switched to COOL.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('heat') || lower.contains('warm')) {
      final state = widget.homeCubit.state;
      if (state is HomeLoaded) {
        for (final d in state.devices) {
          if (d.type == 'climate' || d.type == 'ac') {
            await widget.homeCubit.setDeviceMode(
              widget.homeId,
              state.selectedRoomId ?? 'living_room',
              d,
              'heat',
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _assistantFeedback = '🔥 Climate mode switched to HEAT.';
          _isProcessing = false;
        });
      }
    } else if (lower.contains('eco') || lower.contains('fan')) {
      final state = widget.homeCubit.state;
      if (state is HomeLoaded) {
        for (final d in state.devices) {
          if (d.type == 'climate' || d.type == 'ac') {
            await widget.homeCubit.setDeviceMode(
              widget.homeId,
              state.selectedRoomId ?? 'living_room',
              d,
              'fan',
            );
          }
        }
      }
      if (mounted) {
        setState(() {
          _assistantFeedback = '🌱 Eco mode enabled.';
          _isProcessing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _assistantFeedback =
              'Command recognized: "$command". Devices synchronized.';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Smart Voice Assistant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryCol,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick smart commands & voice automation',
            style: TextStyle(fontSize: 13, color: context.textSecondaryCol),
          ),
          const SizedBox(height: 22),

          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kPurple, _kPurpleDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withValues(
                          alpha: 0.25 + 0.25 * _pulseController.value),
                      blurRadius: 18 + 12 * _pulseController.value,
                      spreadRadius: 4 * _pulseController.value,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: const Center(
              child: Icon(Icons.mic_rounded, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardSubtleCol,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPurple),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    _assistantFeedback,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryCol,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickCommandPill(
                  icon: Icons.lightbulb_rounded,
                  label: 'Turn ON All',
                  onTap: () => _executeCommand('Turn on all devices'),
                ),
                _QuickCommandPill(
                  icon: Icons.nightlight_round,
                  label: 'Night Mode',
                  onTap: () => _executeCommand('Night mode turn off all'),
                ),
                _QuickCommandPill(
                  icon: Icons.ac_unit_rounded,
                  label: 'Cool Climate',
                  onTap: () => _executeCommand('Set climate to cool'),
                ),
                _QuickCommandPill(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Heat Climate',
                  onTap: () => _executeCommand('Set climate to heat'),
                ),
                _QuickCommandPill(
                  icon: Icons.eco_rounded,
                  label: 'Eco Mode',
                  onTap: () => _executeCommand('Eco mode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cmdCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type custom voice command...',
                    hintStyle: TextStyle(
                        fontSize: 13, color: context.textSecondaryCol),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: context.cardSubtleCol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _executeCommand(val);
                      _cmdCtrl.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: _kPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white),
                onPressed: () {
                  final text = _cmdCtrl.text.trim();
                  if (text.isNotEmpty) {
                    _executeCommand(text);
                    _cmdCtrl.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCommandPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickCommandPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardSubtleCol,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.dividerCol),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _kPurple),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DeviceDetailsSheet extends StatefulWidget {
  final DeviceModel device;
  final String homeId;
  final String roomId;
  final HomeCubit homeCubit;

  const _DeviceDetailsSheet({
    required this.device,
    required this.homeId,
    required this.roomId,
    required this.homeCubit,
  });

  @override
  State<_DeviceDetailsSheet> createState() => _DeviceDetailsSheetState();
}

class _DeviceDetailsSheetState extends State<_DeviceDetailsSheet> {
  late bool _isOn;
  late String _currentMode;
  late double _targetTemp;

  @override
  void initState() {
    super.initState();
    _isOn = widget.device.status == 1;
    _currentMode = widget.device.mode?.toLowerCase() ?? 'cool';
    _targetTemp = widget.device.targetTemp ?? 24.0;
  }

  String _formatTimeAgo(int? timestamp) {
    if (timestamp == null) return 'Live RTDB';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (now - timestamp) ~/ 1000;
    if (diff < 60) return 'Just now';
    if (diff < 3600) return '${diff ~/ 60}m ago';
    if (diff < 86400) return '${diff ~/ 3600}h ago';
    return '${diff ~/ 86400}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isClimate = widget.device.type.toLowerCase() == 'climate' ||
        widget.device.type.toLowerCase() == 'ac';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: context.cardCol,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isOn
                        ? [_kPurple, _kPurpleDark]
                        : [const Color(0xFFDDDFF0), const Color(0xFFC8CBDD)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _DeviceIconWidget(
                    type: widget.device.type,
                    deviceId: widget.device.id,
                    isOn: _isOn,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.roomId.replaceAll('_', ' ').toUpperCase()} • ${widget.device.type.toUpperCase()}',
                      style: TextStyle(fontSize: 11, color: context.textSecondaryCol),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch.adaptive(
                  value: _isOn,
                  activeThumbColor: _kPurple,
                  activeTrackColor: _kPurple.withValues(alpha: 0.5),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: context.isDarkMode
                      ? const Color(0xFF383C56)
                      : const Color(0xFFDEDFF0),
                  onChanged: (val) {
                    setState(() => _isOn = val);
                    widget.homeCubit.toggleDevice(
                      widget.homeId,
                      widget.roomId,
                      widget.device.copyWith(status: val ? 0 : 1),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isClimate) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardSubtleCol,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Temperature',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryCol,
                        ),
                      ),
                      Text(
                        'Range: 16° - 30°C',
                        style: TextStyle(fontSize: 11, color: context.textSecondaryCol),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.cardCol,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.remove_rounded,
                            color: _kPurple, size: 20),
                        onPressed: _targetTemp > 16.0
                            ? () {
                                final next = _targetTemp - 0.5;
                                setState(() => _targetTemp = next);
                                widget.homeCubit.setDeviceTemperature(
                                    widget.roomId, widget.device, next);
                              }
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '${_targetTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimaryCol,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.cardCol,
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.add_rounded,
                            color: _kPurple, size: 20),
                        onPressed: _targetTemp < 30.0
                            ? () {
                                final next = _targetTemp + 0.5;
                                setState(() => _targetTemp = next);
                                widget.homeCubit.setDeviceTemperature(
                                    widget.roomId, widget.device, next);
                              }
                            : null,
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetTemp.clamp(16.0, 30.0),
                    min: 16.0,
                    max: 30.0,
                    divisions: 28,
                    activeColor: _kPurple,
                    inactiveColor: context.isDarkMode
                        ? const Color(0xFF383C56)
                        : const Color(0xFFDEDFF0),
                    onChanged: (val) {
                      setState(() => _targetTemp = val);
                      widget.homeCubit.setDeviceTemperature(
                          widget.roomId, widget.device, val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Operating Mode',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryCol,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ModeChip(
                  icon: Icons.ac_unit_rounded,
                  label: 'Cool',
                  isSelected: _currentMode == 'cool',
                  onTap: () {
                    setState(() => _currentMode = 'cool');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'cool');
                  },
                ),
                _ModeChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Heat',
                  isSelected: _currentMode == 'heat',
                  onTap: () {
                    setState(() => _currentMode = 'heat');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'heat');
                  },
                ),
                _ModeChip(
                  icon: Icons.cyclone_rounded,
                  label: 'Fan',
                  isSelected: _currentMode == 'fan',
                  onTap: () {
                    setState(() => _currentMode = 'fan');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'fan');
                  },
                ),
                _ModeChip(
                  icon: Icons.auto_mode_rounded,
                  label: 'Auto',
                  isSelected: _currentMode == 'auto',
                  onTap: () {
                    setState(() => _currentMode = 'auto');
                    widget.homeCubit.setDeviceMode(
                        widget.homeId, widget.roomId, widget.device, 'auto');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardSubtleCol,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _TelemetryRow(label: 'Device Key', value: widget.device.id),
                const SizedBox(height: 6),
                _TelemetryRow(
                  label: 'Hardware Status',
                  value: _isOn ? 'Relay Active (1)' : 'Relay Idle (0)',
                ),
                const SizedBox(height: 6),
                _TelemetryRow(
                  label: 'Last Sync',
                  value: _formatTimeAgo(widget.device.lastUpdated),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPurple : context.cardSubtleCol,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kPurple : context.dividerCol,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : context.textPrimaryCol),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : context.textPrimaryCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondaryCol)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryCol,
          ),
        ),
      ],
    );
  }
}
