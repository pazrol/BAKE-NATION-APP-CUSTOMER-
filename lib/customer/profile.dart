import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bakenation_customer/customer/login.dart';
import 'package:bakenation_customer/addresses/address.dart';
import 'package:bakenation_customer/order/my_order.dart';
import 'package:bakenation_customer/customer/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.callbackPage, super.key});

  final Function(String selectedDetaildPage, Widget page) callbackPage;

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _firstName = 'Unknown';
  bool _isLoading = true;
  String _aboutUsText = '';
  String _contactNumber = ''; // Variable to store the contact phone number

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAboutUsData();
    _loadContactInfo(); // Fetch contact info (phone number)
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('user_database')
            .child(user.uid)
            .child('user_detail');

        DatabaseEvent userEvent = await userRef.once();
        DataSnapshot userSnapshot = userEvent.snapshot;

        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>?;
          setState(() {
            _firstName = userData?['First Name'] ?? 'Unknown';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAboutUsData() async {
    try {
      DatabaseReference aboutUsRef =
          FirebaseDatabase.instance.ref().child('aboutUs').child('aboutUsText');

      DatabaseEvent aboutUsEvent = await aboutUsRef.once();
      DataSnapshot aboutUsSnapshot = aboutUsEvent.snapshot;

      if (aboutUsSnapshot.exists) {
        setState(() {
          _aboutUsText = aboutUsSnapshot.value as String;
        });
      }
    } catch (e) {
      print("Error loading About Us data: $e");
    }
  }

  Future<void> _loadContactInfo() async {
    try {
      DatabaseReference contactRef = FirebaseDatabase.instance
          .ref()
          .child('contactInfo')
          .child('phoneNumber');

      DatabaseEvent contactEvent = await contactRef.once();
      DataSnapshot contactSnapshot = contactEvent.snapshot;

      if (contactSnapshot.exists) {
        setState(() {
          _contactNumber = contactSnapshot.value as String;
        });
      }
    } catch (e) {
      print("Error loading contact information: $e");
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Us'),
          content: Text(
            _aboutUsText.isEmpty ? 'TEXT TAK KELUAR' : _aboutUsText,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to open WhatsApp with the contact number
  /*void _openWhatsApp() async {
    final String message = 'Hi Bake Nation Team!';
    final String whatsAppUrl =
        'https://wa.me/${Uri.encodeComponent(_contactNumber)}?text=${Uri.encodeComponent(message)}';

    print('WhatsApp URL: $whatsAppUrl'); // Debugging URL

    if (await canLaunch(whatsAppUrl)) {
      await launch(whatsAppUrl);
    } else {
      print('Could not open WhatsApp.');
    }
  }*/

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  Widget buildMenuOption(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color.fromRGBO(163, 25, 25, 1),
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          color: Color.fromRGBO(163, 25, 25, 1)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hello,',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      _firstName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(163, 25, 25, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 20),
              buildMenuOption('My Personal Information', () {
                widget.callbackPage(
                  'tukarPage',
                  const EditProfilePage(),
                );
              }),
              buildMenuOption('My Orders', () {
                widget.callbackPage(
                  'tukarPage',
                  const MyOrderPage(),
                );
              }),
              buildMenuOption('My Address', () {
                widget.callbackPage(
                  'tukarPage',
                  const AddressScreen(),
                );
              }),
              const Divider(),
              // Menu item for WhatsApp contact
              /*ListTile(
                title: const Text(
                  'Our Contact',
                  style: TextStyle(
                    color: Color.fromRGBO(163, 25, 25, 1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Color.fromRGBO(163, 25, 25, 1)),
                onTap: _openWhatsApp,
              ),*/
              // About Us
              ListTile(
                title: const Text(
                  'About Us',
                  style: TextStyle(
                    color: Color.fromRGBO(163, 25, 25, 1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Color.fromRGBO(163, 25, 25, 1)),
                onTap: _showAboutUsDialog,
              ),
              const Divider(),
              // Log Out
              ListTile(
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color.fromRGBO(163, 25, 25, 1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.logout,
                    color: Color.fromRGBO(163, 25, 25, 1)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
