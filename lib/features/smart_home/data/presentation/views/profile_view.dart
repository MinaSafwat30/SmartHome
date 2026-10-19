import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthome/main.dart';

const _kPurple = Color(0xFF7B6EF5);


class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationEnabled = true;

  StreamSubscription? _userSub;
  StreamSubscription? _homeSub;

  String _fullName = 'Loading...';
  String _email = '';
  String _initial = 'U';
  String _homeName = 'My Villa';
  String _homeId = 'home_alpha';
  String _userRole = 'Admin';
  int _roomCount = 0;
  int _deviceCount = 0;
  List<Map<String, dynamic>> _members = [];

  static const _avatarColors = [
    0xFF7B6EF5,
    0xFF5DBEF5,
    0xFFF5A25D,
    0xFFF55D8A,
    0xFF11998E,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _subscribeToUserData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final isDark = prefs.getBool('dark_mode_enabled') ?? false;
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _darkModeEnabled = isDark;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
      });
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (key == 'dark_mode_enabled') {
      themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void _subscribeToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _fullName = 'Guest User';
        _email = 'Not signed in';
        _initial = 'G';
      });
      return;
    }

    _email = user.email ?? '';

    final db = FirebaseDatabase.instance.ref();

    _userSub = db.child('users/${user.uid}').onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;

      String fName = '';
      String lName = '';
      String hId = 'home_alpha';
      String role = 'Admin';

      if (val is Map) {
        final data = Map<dynamic, dynamic>.from(val);
        fName = (data['firstName'] as String?) ?? '';
        lName = (data['lastName'] as String?) ?? '';
        hId = (data['homeId'] as String?) ?? 'home_alpha';
        role = (data['role'] as String?) ?? 'Admin';
        if (data['email'] is String && (data['email'] as String).isNotEmpty) {
          _email = data['email'] as String;
        }
      }

      final combined = '$fName $lName'.trim();
      final name = combined.isNotEmpty
          ? combined
          : (user.displayName?.isNotEmpty == true
                ? user.displayName!
                : (_email.contains('@') ? _email.split('@').first : 'User'));

      final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

      setState(() {
        _fullName = name;
        _initial = initial;
        _homeId = hId;
        _userRole = '${role[0].toUpperCase()}${role.substring(1)}';
      });

      _listenToHome(hId);
    }, onError: (_) {});
  }

  void _listenToHome(String homeId) {
    _homeSub?.cancel();
    final db = FirebaseDatabase.instance.ref();

    _homeSub = db.child('homes/$homeId').onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val is! Map) return;

      final homeData = Map<dynamic, dynamic>.from(val);

      String hName = 'My Villa';
      if (homeData['metadata'] is Map) {
        final meta = homeData['metadata'] as Map;
        if (meta['name'] is String && (meta['name'] as String).isNotEmpty) {
          hName = meta['name'] as String;
        }
      }

      int rooms = 0;
      int devices = 0;
      if (homeData['rooms'] is Map) {
        final roomsMap = homeData['rooms'] as Map;
        rooms = roomsMap.length;
        roomsMap.forEach((_, rVal) {
          if (rVal is Map && rVal['devices'] is Map) {
            devices += (rVal['devices'] as Map).length;
          }
        });
      }

      final parsedMembers = <Map<String, dynamic>>[];
      if (homeData['members'] is Map) {
        final membersMap = homeData['members'] as Map;
        int i = 0;
        membersMap.forEach((_, mVal) {
          if (mVal is Map) {
            final mName = (mVal['name'] as String?) ?? 'Member';
            final mRole = (mVal['role'] as String?) ?? 'Member';
            parsedMembers.add({
              'name': mName,
              'role': '${mRole[0].toUpperCase()}${mRole.substring(1)}',
              'initial': mName.isNotEmpty ? mName[0].toUpperCase() : 'M',
              'color': _avatarColors[i % _avatarColors.length],
            });
            i++;
          }
        });
      }

      if (parsedMembers.isEmpty) {
        parsedMembers.add({
          'name': _fullName,
          'role': _userRole,
          'initial': _initial,
          'color': _avatarColors[0],
        });
      }

      setState(() {
        _homeName = hName;
        _roomCount = rooms;
        _deviceCount = devices;
        _members = parsedMembers;
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _homeSub?.cancel();
    super.dispose();
  }

  void _showEditProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final parts = _fullName.split(' ');
    final fCtrl = TextEditingController(text: parts.isNotEmpty ? parts[0] : '');
    final lCtrl = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardCol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.textPrimaryCol,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fCtrl,
              style: TextStyle(color: context.textPrimaryCol),
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: TextStyle(color: context.textSecondaryCol),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: context.textSecondaryCol,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lCtrl,
              style: TextStyle(color: context.textPrimaryCol),
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: TextStyle(color: context.textSecondaryCol),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: context.textSecondaryCol,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondaryCol),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newFirst = fCtrl.text.trim();
              final newLast = lCtrl.text.trim();
              final fullName = '$newFirst $newLast'.trim();

              final db = FirebaseDatabase.instance.ref();
              await db.child('users/${user.uid}').update({
                'firstName': newFirst,
                'lastName': newLast,
              });

              await db.child('homes/$_homeId/members/${user.uid}').update({
                'name': fullName,
              });

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSwitchHomeDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instance.ref();
    final snap = await db.child('homes').get();
    if (!mounted) return;

    final homeList = <Map<String, String>>[];
    if (snap.exists && snap.value is Map) {
      final map = snap.value as Map<dynamic, dynamic>;
      map.forEach((k, v) {
        String hName = k.toString();
        if (v is Map && v['metadata'] is Map) {
          final meta = v['metadata'] as Map;
          if (meta['name'] is String && (meta['name'] as String).isNotEmpty) {
            hName = meta['name'] as String;
          }
        }
        homeList.add({'id': k.toString(), 'name': hName});
      });
    }

    if (homeList.isEmpty) {
      homeList.add({'id': 'home_alpha', 'name': 'My Villa'});
    }

    final newHomeCtrl = TextEditingController();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            Text(
              'Switch Active Home',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryCol,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a property to view and control its devices in real-time.',
              style: TextStyle(fontSize: 13, color: context.textSecondaryCol),
            ),
            const SizedBox(height: 18),
            ...homeList.map((h) {
              final isCurrent = h['id'] == _homeId;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? _kPurple.withValues(alpha: 0.08)
                      : context.cardSubtleCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent ? _kPurple : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? _kPurple
                        : (context.isDarkMode
                            ? const Color(0xFF282D46)
                            : const Color(0xFFDDDFF0)),
                    child: Icon(
                      Icons.home_rounded,
                      color: isCurrent ? Colors.white : context.textSecondaryCol,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    h['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? _kPurple : context.textPrimaryCol,
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${h['id']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryCol,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle_rounded, color: _kPurple)
                      : Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.textSecondaryCol,
                        ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await db.child('users/${user.uid}').update({
                      'homeId': h['id'],
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${h['name']}'),
                          backgroundColor: _kPurple,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Or Join / Connect Another Home ID',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryCol,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newHomeCtrl,
                    style: TextStyle(color: context.textPrimaryCol),
                    decoration: InputDecoration(
                      hintText: 'e.g. home_beta, my_villa_2',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryCol,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: context.inputFillCol,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final entered = newHomeCtrl.text.trim();
                    if (entered.isEmpty) return;
                    Navigator.pop(ctx);
                    await db.child('users/${user.uid}').update({
                      'homeId': entered,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to $entered'),
                          backgroundColor: _kPurple,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacySecurityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardCol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: _kPurple),
            const SizedBox(width: 10),
            Text(
              'Privacy & Security',
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
              'Your smart home connection is protected by Firebase Authentication and SSL/TLS encrypted WebSockets.',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondaryCol,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            const _SecurityBadge(
              icon: Icons.lock_outline_rounded,
              title: 'Secure Auth Token',
              subtitle: 'JWT signed by Google Firebase Identity Platform',
            ),
            const SizedBox(height: 8),
            const _SecurityBadge(
              icon: Icons.shield_outlined,
              title: 'Role-Based Access',
              subtitle: 'Admin and Member granular device permissions',
            ),
            const SizedBox(height: 8),
            const _SecurityBadge(
              icon: Icons.devices_rounded,
              title: 'Isolated Hardware Node',
              subtitle: 'Microcontrollers (ESP32) isolated via security rules',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardCol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Color(0xFF5DBEF5)),
            const SizedBox(width: 10),
            Text(
              'Help & Support',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.textPrimaryCol,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: context.textPrimaryCol,
                ),
              ),
              const SizedBox(height: 10),
              const _FaqTile(
                question: 'How do devices sync with hardware?',
                answer:
                    'When you toggle a switch, the app writes status 1 or 0 to Firebase Realtime Database. Your ESP32 / Arduino node listens to changes on that path and activates the physical relay.',
              ),
              const SizedBox(height: 10),
              const _FaqTile(
                question: 'How do room switches work?',
                answer:
                    'Toggling a room switch automatically cascades to all devices inside that room in a single atomic database update.',
              ),
              const SizedBox(height: 10),
              const _FaqTile(
                question: 'Can I control multiple homes?',
                answer:
                    'Yes! Tap your Home Badge in the profile header to instantly switch between homes or add a new property ID.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardCol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFF5A25D)),
            const SizedBox(width: 10),
            Text(
              'About SmartHome',
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
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPurple, Color(0xFF9E5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'SmartHome IoT Controller',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryCol,
                ),
              ),
            ),
            Center(
              child: Text(
                'Version 1.2.0 • Production Build',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryCol,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: context.dividerCol),
            const SizedBox(height: 8),
            _AboutInfoRow(label: 'Connected Home', value: _homeName),
            _AboutInfoRow(label: 'Home ID', value: _homeId),
            _AboutInfoRow(label: 'Total Rooms', value: '$_roomCount Rooms'),
            _AboutInfoRow(
              label: 'Total Devices',
              value: '$_deviceCount Devices',
            ),
            const _AboutInfoRow(label: 'Database', value: 'Firebase RTDB Live'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCol,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader()),

          SliverToBoxAdapter(child: _buildStatsRow()),

          SliverToBoxAdapter(child: _buildSectionLabel('Home Members')),
          SliverToBoxAdapter(child: _buildFamilyMembers()),

          SliverToBoxAdapter(child: _buildSectionLabel('Preferences')),
          SliverToBoxAdapter(child: _buildPreferences()),

          SliverToBoxAdapter(child: _buildSectionLabel('Account')),
          SliverToBoxAdapter(child: _buildAccountItems()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: _buildSignOutButton(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B80F9), Color(0xFF9B5DFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.edit_rounded,
                    onTap: _showEditProfileDialog,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B6EF5), Color(0xFF5DBEF5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showEditProfileDialog,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 15,
                        color: _kPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _showSwitchHomeDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_homeName  •  $_userRole',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatsRow() {
    final memberCount = _members.isNotEmpty ? _members.length : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatCard(
            value: _roomCount.toString(),
            label: 'Rooms',
            icon: Icons.meeting_room_rounded,
          ),
          const SizedBox(width: 12),
          _StatCard(
            value: _deviceCount.toString(),
            label: 'Devices',
            icon: Icons.devices_rounded,
          ),
          const SizedBox(width: 12),
          _StatCard(
            value: memberCount.toString(),
            label: 'Members',
            icon: Icons.people_rounded,
          ),
        ],
      ),
    );
  }


  Widget _buildFamilyMembers() {
    if (_members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Center(
          child: Text(
            'No members found',
            style: TextStyle(color: context.textSecondaryCol, fontSize: 13),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _members.map((m) {
          final colorVal = m['color'] is int ? m['color'] as int : 0xFF7B6EF5;
          final roleStr = (m['role'] as String?) ?? 'Member';
          final isAdmin =
              roleStr.toLowerCase() == 'admin' ||
              roleStr.toLowerCase() == 'owner';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: context.cardCol,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Color(colorVal),
                child: Text(
                  (m['initial'] as String?) ?? 'M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                (m['name'] as String?) ?? 'Member',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryCol,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                roleStr,
                style: TextStyle(color: context.textSecondaryCol, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? _kPurple.withValues(alpha: 0.12)
                      : context.cardSubtleCol,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  roleStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAdmin ? _kPurple : context.textSecondaryCol,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildPreferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _ToggleTile(
              icon: Icons.notifications_rounded,
              iconColor: const Color(0xFFF5A25D),
              label: 'Notifications',
              value: _notificationsEnabled,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                _updatePreference('notifications_enabled', v);
              },
              isFirst: true,
            ),
            _Divider(),
            _ToggleTile(
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF5DBEF5),
              label: 'Dark Mode',
              value: _darkModeEnabled,
              onChanged: (v) {
                setState(() => _darkModeEnabled = v);
                _updatePreference('dark_mode_enabled', v);
              },
            ),
            _Divider(),
            _ToggleTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFF55D8A),
              label: 'Location Access',
              value: _locationEnabled,
              onChanged: (v) {
                setState(() => _locationEnabled = v);
                _updatePreference('location_enabled', v);
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAccountItems() {
    final items = [
      (
        Icons.security_rounded,
        const Color(0xFF7B6EF5),
        'Privacy & Security',
        _showPrivacySecurityDialog,
      ),
      (
        Icons.help_outline_rounded,
        const Color(0xFF5DBEF5),
        'Help & Support',
        _showHelpSupportDialog,
      ),
      (
        Icons.info_outline_rounded,
        const Color(0xFFF5A25D),
        'About',
        _showAboutDialog,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                _ActionTile(
                  icon: item.$1,
                  iconColor: item.$2,
                  label: item.$3,
                  isFirst: i == 0,
                  isLast: i == items.length - 1,
                  onTap: item.$4,
                ),
                if (i < items.length - 1) _Divider(),
              ],
            );
          }),
        ),
      ),
    );
  }


  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: context.cardCol,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.textPrimaryCol,
              ),
            ),
            content: Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: context.textSecondaryCol),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.textSecondaryCol),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFE05454),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await FirebaseAuth.instance.signOut();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF3B1E2B)
              : const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFE05454), size: 20),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                color: Color(0xFFE05454),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: context.textPrimaryCol,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}


class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.cardCol,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPurple, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryCol,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: context.textSecondaryCol),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirst;
  final bool isLast;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 0),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: context.textPrimaryCol,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.85,
          child: Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: _kPurple,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: context.isDarkMode
                ? const Color(0xFF383C56)
                : const Color(0xFFDEDFF0),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 0),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: context.textPrimaryCol,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.textSecondaryCol,
          size: 20,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: context.dividerCol,
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecurityBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.cardSubtleCol,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: context.textPrimaryCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondaryCol,
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

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardSubtleCol,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: context.textPrimaryCol,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondaryCol,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecondaryCol, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.textPrimaryCol,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
