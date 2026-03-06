import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:neopop/neopop.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthdayController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedState = '';
  String _selectedCountry = 'India';
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isUploading = false;

  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': 'IN', 'flag': '🇮🇳', 'dialCode': '+91'},
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸', 'dialCode': '+1'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧', 'dialCode': '+44'},
    {'name': 'South Africa', 'code': 'ZA', 'flag': '🇿🇦', 'dialCode': '+27'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user!.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name']?.toString() ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
        _emailController.text = user!.email ?? '';
        _birthdayController.text = data['birthday']?.toString() ?? '';
        _selectedGender = data['gender']?.toString() ?? 'Male';
        _selectedState = data['state']?.toString() ?? 'Uttar Pradesh';
        _selectedCountry = data['country']?.toString() ?? 'India';
        _profileImageUrl = data['profileUrl']?.toString();
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      var status = await Permission.photos.request();
      if (status.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission is required')),
        );
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        String? uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) {
          setState(() {
            _profileImageUrl = uploadedUrl;
          });

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .update({'profileUrl': uploadedUrl});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null || user == null) return null;

    try {
      setState(() => _isUploading = true);

      final storageRef = FirebaseStorage.instance.ref().child(
        'Users/${user!.uid}/profile_image.jpg',
      );

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB7FF1C),
              onPrimary: Colors.black,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user!.uid)
              .update({
                'name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'birthday': _birthdayController.text.trim(),
                'gender': _selectedGender,
                'state': _selectedState,
                'country': _selectedCountry,
                'profileUrl': _profileImageUrl ?? '',
              });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
        }
      }
    }
  }

  Map<String, String> get _selectedCountryData {
    return _countries.firstWhere(
      (country) => country['name'] == _selectedCountry,
      orElse: () => _countries.first,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF2A2A2A),
        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        underline: const SizedBox(),
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: _profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(45),
                                  child: Image.network(
                                    _profileImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey,
                                ),
                        ),
                        if (_isUploading)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFB7FF1C),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                _buildLabel('Name'),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Enter your name',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 12),

                _buildLabel('Phone number'),
                Row(
                  children: [
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountry,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCountry = newValue!;
                            });
                          },
                          dropdownColor: Colors.white,
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          items: _countries.map((country) {
                            return DropdownMenuItem<String>(
                              value: country['name'],
                              child: Row(
                                children: [
                                  Text(
                                    country['flag']!,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    country['code']!,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        hintText:
                            '${_selectedCountryData['dialCode']} (555) 000-0000',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'The phone number associated with your account cannot be modified',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 12),

                _buildLabel('Email'),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _emailController.text.isNotEmpty
                            ? _emailController.text
                            : 'user@tixoo.com',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _buildLabel('Gender'),
                _buildDropdownField(
                  value: _selectedGender,
                  items: ['Male', 'Female', 'Other'],
                  onChanged: (value) =>
                      setState(() => _selectedGender = value!),
                ),
                const SizedBox(height: 12),

                _buildLabel('Birthday'),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _birthdayController.text.isEmpty
                                ? 'Select your birthday'
                                : _birthdayController.text,
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildLabel('State'),
                _buildDropdownField(
                  value: _selectedState,
                  items: [
                    'Uttar Pradesh',
                    'Maharashtra',
                    'Delhi',
                    'Karnataka',
                    'Tamil Nadu',
                    'Gujarat',
                  ],
                  onChanged: (value) => setState(() => _selectedState = value!),
                ),
                const SizedBox(height: 20),

                /// Gradient Button
                GestureDetector(
                  onTap: _saveProfile,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C3E2C), Color(0xFF4A7C4A)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (constraints.maxHeight < 650) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: content,
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: content,
            );
          }
        },
      ),
    );
  }
}
