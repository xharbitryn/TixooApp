import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    bool hasPermission = await FlutterContacts.requestPermission();

    if (!hasPermission) {
      setState(() {
        isLoading = false;
        contacts = [];
        filteredContacts = [];
      });
      return;
    }

    final allContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    setState(() {
      contacts = allContacts;
      filteredContacts = allContacts;
      isLoading = false;
    });
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() => filteredContacts = contacts);
    } else {
      setState(() {
        filteredContacts = contacts.where((c) {
          final name = c.displayName.toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _inviteContact(Contact contact) async {
    if (contact.phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number available")),
      );
      return;
    }

    final number = contact.phones.first.number;
    const message = "Hey! 👋 Check out this awesome app I'm using!";

    Share.share("$message\nContact: $number", subject: "App Invite");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Select Contact",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _filterContacts,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search contacts...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📱 Contacts list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB7FF1C)),
                  )
                : filteredContacts.isEmpty
                ? Center(
                    child: Text(
                      "No contacts found",
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFB7FF1C),
                          child: Text(
                            (contact.displayName.isNotEmpty)
                                ? contact.displayName[0].toUpperCase()
                                : "?",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        subtitle: contact.phones.isNotEmpty
                            ? Text(
                                contact.phones.first.number,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFB7FF1C),
                          ),
                          onPressed: () => _inviteContact(contact),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
