import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  bool _acceptTerms = false;
  bool _isPasswordVisible = false;
  bool _isRePasswordVisible = false;

  // Function to handle registration and save data in Realtime Database
  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Generate a unique ID using the Firebase UID
        String uniqueId = userCredential.user!.uid;

        // Modify the phone number to include the +6 prefix
        String formattedPhoneNumber = '+6${_phoneController.text.trim()}';

        // Store user details in Realtime Database under 'user_database' -> 'uniqueId' -> 'user_detail'
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('user_database')
            .child(uniqueId)
            .child('user_detail');

        await userRef.set({
          'UniqueId': uniqueId,
          'First Name': _firstNameController.text.trim(),
          'Last Name': _lastNameController.text.trim(),
          'Email': _emailController.text.trim(),
          'Phone No':
              formattedPhoneNumber, // Use the phone number with +6 prefix
          'Password': _passwordController.text.trim(),
        });

        // Show success popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: Color.fromRGBO(163, 25, 25, 1), size: 120),
                  const SizedBox(height: 15),
                  const Text(
                    "Successful!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your account has been created.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      backgroundColor: const Color.fromRGBO(163, 25, 25, 1),
                      minimumSize: const Size(230, 50),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 255, 255, 255)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: ${e.toString()}")),
        );
      }
    } else if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please accept the terms and conditions.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Matching LoginPage height
        child: AppBar(
          automaticallyImplyLeading: false, // Removes back button
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Center(
              child: Image.asset(
                'assets/bn_logo.png', // Image path
                height: 250,
                width: 250,
              ),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0, // Removes shadow
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Let's Get Started!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Come and join us to get special deals!',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(217, 217, 217, 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  labelStyle:
                                      const TextStyle(color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your first name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  labelStyle:
                                      const TextStyle(color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your last name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^\d{3}-\d{7,8}$').hasMatch(value)) {
                              return 'Enter phone number(e.g.019-2340099)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^[\w-\.]+@gmail\.com$')
                                    .hasMatch(value)) {
                              return 'Enter a valid Gmail address (example@gmail.com)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-_]).{6,12}$')
                                    .hasMatch(value)) {
                              return 'Password must be : \n*6-12 characters, \n*with uppercase and lowercase, \n*number, \n*special character';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _rePasswordController,
                          obscureText: !_isRePasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Re-Password',
                            labelStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(23),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isRePasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isRePasswordVisible = !_isRePasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value!;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I accept the ',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                  children: [
                                    TextSpan(
                                      text: 'Terms and Conditions ',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(
                                        text: 'and ',
                                        style: TextStyle(color: Colors.black)),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(163, 25, 25, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _register,
                            child: const Text(
                              'Register Now',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Color.fromRGBO(255, 255, 255, 1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Log In Now!',
                        style: TextStyle(
                          color: Color.fromRGBO(163, 25, 25, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
