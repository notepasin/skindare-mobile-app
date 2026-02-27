import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SkinProfileScreen extends StatefulWidget {
  const SkinProfileScreen({super.key});

  @override
  State<SkinProfileScreen> createState() => _SkinProfileScreenState();
}

class _SkinProfileScreenState extends State<SkinProfileScreen> {
  String? selectedSkinType;

  final List<String> skinTypes = ["Oily", "Normal", "Dry"];

  final List<String> concerns = [
    "Acne",
    "Wrinkles",
    "Dark Spots",
    "Sensitivity",
    "No specific concern",
  ];

  List<String> selectedConcerns = [];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB),
      body: Column(
        children: [
          /// 🔵 HEADER
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
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Skin Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// ⚪ BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Your Skin Type",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// 🔵 Skin Type (เลือกได้ 1)
                    ...skinTypes.map(
                      (type) => RadioListTile<String>(
                        value: type,
                        groupValue: selectedSkinType,
                        activeColor: const Color(0xFF4A90E2),
                        title: Text(type),
                        onChanged: (value) {
                          setState(() {
                            selectedSkinType = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Select Your Skin Concerns",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// 🟢 Concerns (เลือกได้หลาย)
                    ...concerns.map(
                      (concern) => CheckboxListTile(
                        value: selectedConcerns.contains(concern),
                        activeColor: const Color(0xFF4A90E2),
                        title: Text(concern),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedConcerns.add(concern);
                            } else {
                              selectedConcerns.remove(concern);
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// 💾 SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedSkinType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a skin type"),
                              ),
                            );
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .set({
                                'skinType': selectedSkinType,
                                'concerns': selectedConcerns,
                              }, SetOptions(merge: true));

                          if (!mounted) return;

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Save Profile",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
