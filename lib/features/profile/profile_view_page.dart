// lib/features/profile/profile_view_page.dart
import 'package:flutter/material.dart';

class ProfileViewPage extends StatelessWidget {
  const ProfileViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text('Your Profile'),
            subtitle: Text('+91 9999999999'),
          ),
          Divider(),
          ListTile(leading: Icon(Icons.event), title: Text('Visits')),
          ListTile(leading: Icon(Icons.help_outline), title: Text('About Us')),
          ListTile(leading: Icon(Icons.call), title: Text('Contact Us')),
        ],
      ),
    );
  }
}
