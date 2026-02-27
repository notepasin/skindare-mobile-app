import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skindare/core/widgets/app_input.dart';
import 'package:skindare/core/widgets/app_button.dart';

class EditProductScreen extends StatefulWidget {
  final String docId;
  final String name;
  final String type;

  const EditProductScreen({
    super.key,
    required this.docId,
    required this.name,
    required this.type,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late String selectedType;
  bool _loading = false;

  final List<String> types = [
    "Cleanser",
    "Toner",
    "Moisturizer",
    "Vitamin C",
    "BHA",
    "Retinol",
    "Sunscreen",
    "Serum",
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    selectedType = widget.type;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .doc(widget.docId)
        .update({'name': nameController.text.trim(), 'type': selectedType});

    setState(() => _loading = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Edit Product",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 BODY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// PRODUCT NAME
                    AppInput(
                      controller: nameController,
                      hint: "Product Name",
                      icon: Icons.inventory_2_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Product name is required";
                        }
                        if (value.length < 2) {
                          return "Product name is too short";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// DROPDOWN (ทำให้มนเหมือน Login)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: types
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select product type";
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// SAVE BUTTON (gradient แบบ Login)
                    AppButton(
                      text: "Save Changes",
                      onPressed: _saveProduct,
                      loading: _loading,
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
