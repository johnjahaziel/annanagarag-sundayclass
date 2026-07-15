import 'package:attendance/features/class_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'add_teacher.dart';
import 'add_student.dart';
import 'add_class.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
  }

  @override
  void dispose() {
    Get.delete<HomeController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatCard(
        title: 'Teachers',
        value: '24',
        icon: Icons.school,
        color: const Color(0xFF7E57C2),
      ),
      _StatCard(
        title: 'Students',
        value: '180',
        icon: Icons.groups,
        color: const Color(0xFF26A69A),
      ),
      _StatCard(
        title: 'Classes',
        value: '12',
        icon: Icons.class_,
        color: const Color(0xFFEF6C00),
      ),
      _StatCard(
        title: 'Transfer',
        value: '8',
        icon: Icons.swap_horiz,
        color: const Color(0xFFEC407A),
      ),
    ];

    final actions = [
      _ActionTile(
        title: 'Add Teachers',
        icon: Icons.person_add_alt_1,
        color: const Color(0xFF7E57C2),
      ),
      _ActionTile(
        title: 'Add Students',
        icon: Icons.group_add,
        color: const Color(0xFF26A69A),
      ),
      _ActionTile(
        title: 'Add Classes',
        icon: Icons.add_box_outlined,
        color: const Color(0xFF00ACC1),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Attendance Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Welcome back! Manage students, teachers and classes with ease.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE082),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFFEF6C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: stats.map((stat) => stat).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                children: actions
                    .map((action) => _ActionTileWidget(action: action))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _HighlightPanelCard(
                title: 'Class List',
                subtitle: 'Active groups and learning levels',
                accentColor: const Color(0xFF5E35B1),
                icon: Icons.menu_book_rounded,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }
                  if (controller.loadError.value != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.loadError.value!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.loadClasses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final divisionNames = controller.divisionNames;
                  if (divisionNames.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No classes yet — add one to get started.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var index = 0; index < divisionNames.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RawMaterialButton(
                            onPressed: () {
                              Get.to(
                                () => ClassDetail(
                                  className: divisionNames[index],
                                ),
                              );
                            },
                            fillColor: const Color(0xFFF3E5F5),
                            splashColor: const Color.fromARGB(
                              255,
                              209,
                              187,
                              253,
                            ),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: const Color(0xFF5E35B1),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    divisionNames[index],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xFF5E35B1),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 12),
              _HighlightPanelCard(
                title: 'Reports',
                subtitle: 'Overview of requests and progress',
                accentColor: const Color(0xFF00ACC1),
                icon: Icons.insights_rounded,
                child: Column(
                  children: const [
                    _ReportItem(
                      label: 'Request Section',
                      icon: Icons.request_page,
                      color: Color(0xFF00ACC1),
                    ),
                    _ReportItem(
                      label: 'Weekly Report',
                      icon: Icons.calendar_view_week,
                      color: Color(0xFF26A69A),
                    ),
                    _ReportItem(
                      label: 'Monthly Report',
                      icon: Icons.bar_chart,
                      color: Color(0xFFEF6C00),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () {
        // Handle card tap
      },
      elevation: 2,
      fillColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: Colors.black54)),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
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

class _ActionTile {
  final String title;
  final IconData icon;
  final Color color;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class _ActionTileWidget extends StatelessWidget {
  final _ActionTile action;

  const _ActionTileWidget({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (action.title == 'Add Teachers') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTeacher()),
          );
        } else if (action.title == 'Add Students') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudent()),
          );
        } else if (action.title == 'Add Classes') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClass()),
          );
        }
        // Handle other action taps here
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: action.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: action.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightPanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _HighlightPanelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, accentColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ReportItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () {},
      splashColor: const Color.fromARGB(255, 199, 243, 245),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      fillColor: Colors.white,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
