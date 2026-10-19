import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/core/constants/app_constants.dart';
import 'package:smarthome/core/theme/app_theme.dart';

class FamilyAvatarsWidget extends StatelessWidget {
  final String homeId;
  final VoidCallback onTap;

  const FamilyAvatarsWidget({
    super.key,
    required this.homeId,
    required this.onTap,
  });

  void _openFamilySheet(
      BuildContext context, List<Map<String, dynamic>> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyMembersSheet(
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
                'gradient': AppConstants.avatarGradients[i % AppConstants.avatarGradients.length],
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
            'gradient': AppConstants.avatarGradients[0],
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

class FamilyMembersSheet extends StatefulWidget {
  final String homeId;
  final List<Map<String, dynamic>> members;
  final VoidCallback onGoToProfile;

  const FamilyMembersSheet({
    super.key,
    required this.homeId,
    required this.members,
    required this.onGoToProfile,
  });

  @override
  State<FamilyMembersSheet> createState() => _FamilyMembersSheetState();
}

class _FamilyMembersSheetState extends State<FamilyMembersSheet> {
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
              const Icon(Icons.person_add_rounded, color: AppConstants.primaryPurple),
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
                    selectedColor: AppConstants.primaryPurple,
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
                backgroundColor: AppConstants.primaryPurple,
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
                      backgroundColor: AppConstants.primaryPurple,
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
                  backgroundColor: AppConstants.primaryPurple.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_rounded,
                    color: AppConstants.primaryPurple, size: 20),
                onPressed: _showAddMemberDialog,
              ),
            ],
          ),
          const SizedBox(height: 18),

          ...widget.members.map((m) {
            final grad = (m['gradient'] is List<Color>)
                ? m['gradient'] as List<Color>
                : [AppConstants.primaryPurple, AppConstants.primaryPurpleDark];
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
                        ? AppConstants.primaryPurple.withValues(alpha: 0.12)
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
                          ? AppConstants.primaryPurple
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
                    side: const BorderSide(color: AppConstants.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.person_add_rounded,
                      color: AppConstants.primaryPurple, size: 18),
                  label: const Text('Add Member',
                      style: TextStyle(
                          color: AppConstants.primaryPurple, fontWeight: FontWeight.bold)),
                  onPressed: _showAddMemberDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryPurple,
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
