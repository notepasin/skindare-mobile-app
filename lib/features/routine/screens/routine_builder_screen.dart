import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
  String selectedTime = "Morning";
  List<Map<String, dynamic>> routineSteps = [];

  int getPriority(String type) {
    switch (type) {
      case "Cleanser":
        return 1;
      case "Toner":
        return 2;
      case "Serum":
        return 3;
      case "Vitamin C":
        return 4;
      case "BHA":
        return 5;
      case "Retinol":
        return 6;
      case "Moisturizer":
        return 7;
      case "Sunscreen":
        return 8;
      default:
        return 99;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB),
      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF6EA8DC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Routine Builder",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// TOGGLE + GENERATE
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeButton("Morning"),
                    const SizedBox(width: 12),
                    _buildTimeButton("Night"),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: generateRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A90E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Auto Generate Routine"),
                ),
              ],
            ),
          ),

          /// PRODUCT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final data = products[index].data() as Map<String, dynamic>;

                    final name = data['name'] ?? "";
                    final type = data['type'] ?? "";

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(type),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF4A90E2),
                        ),
                        onPressed: () {
                          final exists = routineSteps.any(
                            (e) => e['name'] == name,
                          );

                          if (!exists) {
                            setState(() {
                              routineSteps.add({"name": name, "type": type});

                              routineSteps.sort(
                                (a, b) => getPriority(
                                  a['type'],
                                ).compareTo(getPriority(b['type'])),
                              );
                            });
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// PREVIEW
          buildPreview(user),
        ],
      ),
    );
  }

  Widget buildPreview(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$selectedTime Routine",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          if (routineSteps.isEmpty) const Text("No steps added yet."),

          if (routineSteps.isNotEmpty)
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = routineSteps.removeAt(oldIndex);
                  routineSteps.insert(newIndex, item);
                });
              },
              children: [
                for (int i = 0; i < routineSteps.length; i++)
                  Container(
                    key: ValueKey(i),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(routineSteps[i]['name']),
                      subtitle: Text(routineSteps[i]['type']),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            routineSteps.removeAt(i);
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: routineSteps.isEmpty
                  ? null
                  : () async {
                      final warnings = checkConflicts();

                      if (warnings.isNotEmpty) {
                        showWarningDialog(warnings, user);
                      } else {
                        await saveRoutine(user);
                      }
                    },
              child: const Text("Save Routine"),
            ),
          ),
        ],
      ),
    );
  }

  /// AUTO GENERATE (NEW LOGIC - RULE BASED)
  Future<void> generateRoutine() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    /// 🔹 ดึง profile
    final profileDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final skinType = profileDoc.data()?['skinType'] ?? "";
    final concerns = List<String>.from(profileDoc.data()?['concerns'] ?? []);

    /// 🔹 ดึง products
    final productSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .get();

    final products = productSnapshot.docs.map((doc) => doc.data()).toList();

    List<Map<String, dynamic>> generated = [];

    /// สร้าง map ไว้หยิบ type ได้ง่าย
    Map<String, Map<String, dynamic>> productMap = {
      for (var p in products) p['type']: p,
    };

    bool isSensitive = concerns.contains("Sensitivity");
    bool hasWrinkles = concerns.contains("Wrinkles");
    bool hasAcne = concerns.contains("Acne");
    bool hasDarkSpot = concerns
        .map((e) => e.toLowerCase())
        .contains("dark spots");
    void addIfExists(String type) {
      if (productMap.containsKey(type)) {
        generated.add(productMap[type]!);
      }
    }

    /// ==============================
    /// 🛡️ SAFE MODE (Sensitivity)
    /// ==============================
    if (isSensitive) {
      addIfExists("Cleanser");
      addIfExists("Toner");
      addIfExists("Serum");
      addIfExists("Moisturizer");

      if (selectedTime == "Morning") {
        addIfExists("Sunscreen");
      }

      finishGenerate(generated);
      return;
    }

    /// ==============================
    /// 🧱 BASE LAYER
    /// ==============================
    addIfExists("Cleanser");
    addIfExists("Toner");

    /// ==============================
    /// 🌞 MORNING
    /// ==============================
    if (selectedTime == "Morning") {
      if (hasDarkSpot) {
        addIfExists("Vitamin C");
      } else {
        addIfExists("Serum");
      }

      addIfExists("Moisturizer");
      addIfExists("Sunscreen");
    }

    /// ==============================
    /// 🌙 NIGHT
    /// ==============================
    if (selectedTime == "Night") {
      Map<String, dynamic>? active;

      /// เลือก active ได้แค่ 1 ตัว
      if (hasWrinkles) {
        active = productMap["Retinol"];
      } else if (hasAcne) {
        active = productMap["BHA"];
      } else if (hasDarkSpot) {
        active = productMap["Retinol"];
      }

      /// ❗ Dry-Retinol Constraint
      if (skinType == "Dry" && !hasWrinkles) {
        active = null;
      }

      if (active != null) {
        generated.add(active);
      } else {
        addIfExists("Serum");
      }

      addIfExists("Moisturizer");
    }

    finishGenerate(generated);
  }

  /// 🔥 Finalize + sort + setState
  void finishGenerate(List<Map<String, dynamic>> generated) {
    /// กันซ้ำ
    final unique = <String>{};
    generated = generated.where((p) => unique.add(p['name'])).toList();

    /// เรียงลำดับตาม layer
    generated.sort(
      (a, b) => getPriority(a['type']).compareTo(getPriority(b['type'])),
    );

    setState(() {
      routineSteps = generated
          .map((e) => {"name": e['name'], "type": e['type']})
          .toList();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Routine generated!")));
  }

  List<String> checkConflicts() {
    final types = routineSteps.map((e) => e['type']).toList();

    List<String> warnings = [];

    if (types.contains("BHA") && types.contains("Retinol")) {
      warnings.add("BHA + Retinol may cause irritation.");
    }

    if (types.contains("Vitamin C") && types.contains("BHA")) {
      warnings.add("Vitamin C + BHA increases acidity.");
    }

    return warnings;
  }

  void showWarningDialog(List<String> warnings, User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠ Warning"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: warnings.map((w) => Text(w)).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Edit"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await saveRoutine(user);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> saveRoutine(User user) async {
    final timeKey = selectedTime.toLowerCase();

    final stepsWithOrder = routineSteps
        .asMap()
        .entries
        .map(
          (entry) => {
            "name": entry.value['name'],
            "type": entry.value['type'],
            "order": entry.key,
          },
        )
        .toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('routines')
        .doc(timeKey)
        .set({"steps": stepsWithOrder});

    if (selectedTime == "Morning") {
      setState(() {
        selectedTime = "Night";
        routineSteps.clear();
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildTimeButton(String label) {
    final isSelected = selectedTime == label;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF4A90E2) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          selectedTime = label;
          routineSteps.clear();
        });
      },
      child: Text(label),
    );
  }
}
