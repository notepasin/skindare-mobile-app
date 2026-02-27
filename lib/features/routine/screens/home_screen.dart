import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMorning = true;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning";
    if (hour >= 12 && hour < 17) return "Good Afternoon";
    if (hour >= 17 && hour < 21) return "Good Evening";
    return "Good Night";
  }

  Map<int, bool> checkedSteps = {};

  int getPriority(String type) {
    switch (type) {
      case "Cleanser":
        return 1;
      case "Toner":
        return 2;
      case "Serum":
        return 3;
      case "Moisturizer":
        return 4;
      case "Sunscreen":
        return 5;
      default:
        return 99;
    }
  }

  Future<void> saveHistory(
    List<Map<String, dynamic>> steps,
    String routineDoc,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}-$routineDoc";

    // 🔥 กัน log ซ้ำวันเดียวกัน
    final existing = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .where('logKey', isEqualTo: todayKey)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Already logged today.")));
      return;
    }

    List<Map<String, dynamic>> usedSteps = [];

    for (int i = 0; i < steps.length; i++) {
      if (checkedSteps[i] == true) {
        usedSteps.add(steps[i]);
      }
    }

    if (usedSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one product.")),
      );
      return;
    }

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .add({
          "date": today,
          "logKey": todayKey,
          "timeOfDay": routineDoc,
          "steps": usedSteps,
          "skinType": profile['skinType'],
          "concerns": profile['concerns'],
        });

    setState(() {
      checkedSteps.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("History saved!")));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final routineDoc = _isMorning ? "morning" : "night";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF6EA8DC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity, // 👈 ใส่อันนี้
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${getGreeting()},",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          final username = data?['username'] ?? "User";

                          return Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Here's your skincare plan for today",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              /// BODY (Scrollable)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Routine",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        /// TOGGLE
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text("Morning"),
                              selected: _isMorning,
                              onSelected: (_) {
                                setState(() {
                                  _isMorning = true;
                                  checkedSteps.clear();
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text("Evening"),
                              selected: !_isMorning,
                              onSelected: (_) {
                                setState(() {
                                  _isMorning = false;
                                  checkedSteps.clear();
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// ROUTINE DATA
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('routines')
                              .doc(routineDoc)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.data!.exists) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "No routine created yet.\nTap 'Make Routine' below.",
                                ),
                              );
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            final steps = List<Map<String, dynamic>>.from(
                              data['steps'] ?? [],
                            );

                            if (steps.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text("No steps added."),
                              );
                            }

                            /// SORT
                            if (steps.first.containsKey("order")) {
                              steps.sort(
                                (a, b) => (a['order'] ?? 0).compareTo(
                                  b['order'] ?? 0,
                                ),
                              );
                            } else {
                              steps.sort(
                                (a, b) => getPriority(
                                  a['type'],
                                ).compareTo(getPriority(b['type'])),
                              );
                            }

                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: steps.length,
                                    itemBuilder: (context, index) {
                                      final step = steps[index];
                                      final type = step['type'];

                                      return CheckboxListTile(
                                        value: checkedSteps[index] ?? false,
                                        activeColor: const Color(0xFF4A90E2),
                                        checkColor: Colors.white,
                                        onChanged: (value) {
                                          setState(() {
                                            checkedSteps[index] =
                                                value ?? false;
                                          });
                                        },
                                        secondary: Image.asset(
                                          getIconPath(type),
                                          width: 28,
                                          height: 28,
                                        ),
                                        title: Text(
                                          step['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            "$type • Step ${index + 1}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                                if (checkedSteps.containsValue(true))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            saveHistory(steps, routineDoc),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF4A90E2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text("Save Today's Log"),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _QuickActionCard(
                              onTap: () {
                                context.push('/add-product');
                              },
                              icon: Icons.add,
                              label: "Add Product",
                            ),
                            _QuickActionCard(
                              onTap: () {
                                context.push('/routine-builder');
                              },
                              icon: Icons.edit,
                              label: "Make Routine",
                            ),
                            _QuickActionCard(
                              onTap: () {
                                context.push('/history');
                              },
                              icon: Icons.history,
                              label: "History",
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String getIconPath(String type) {
  switch (type) {
    case "Cleanser":
      return "assets/icon/face-cleanser_7176183.png";
    case "Toner":
      return "assets/icon/toner_4675450.png";
    case "Serum":
      return "assets/icon/serum_9909516.png";
    case "Moisturizer":
      return "assets/icon/cream_13643369.png";
    case "Sunscreen":
      return "assets/icon/beauty_13834267.png";
    case "BHA":
      return "assets/icon/poison_6400830.png";
    case "Retinol":
      return "assets/icon/drop_10247854.png";
    case "Vitamin C":
      return "assets/icon/vitamin-c_6238048.png";
    default:
      return "assets/icon/default.png";
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionCard({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4A90E2)),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
