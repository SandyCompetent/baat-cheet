import 'package:chatbud/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isHidden = true;

  void _toggleVisibility() {
    setState(() {
      _isHidden = !_isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.redAccent,
      body: Container(
        padding: const EdgeInsets.only(
            top: 100.0, right: 20.0, left: 20.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'ChatBud',
              style: TextStyle(
                fontSize: 65.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 40.0,
            ),
            const Text(
              "Connecting to close one",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 40.0,
            ),
            _buildTextField("Email", false),
            const SizedBox(
              height: 20.0,
            ),
            _buildTextField("Password", true),
            const SizedBox(
              height: 20.0,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50.0),
            _buildButtonContainer(),
            const SizedBox(
              height: 10.0,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Already have an account?",
                    style: TextStyle(
                      color: Colors.white,
                    )),
                SizedBox(
                  width: 10.0,
                ),
                Text("Sign in",
                    style: TextStyle(
                      color: Colors.white,
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, bool isPassword) {
    return TextField(
        obscureText: isPassword ? _isHidden : false,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: _toggleVisibility,
                  icon: _isHidden
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                )
              : null,
        ));
  }

  Widget _buildButtonContainer() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(homeRoute),
      child: Container(
        height: 56.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23.0),
          gradient: const LinearGradient(
              colors: [Color(0xFFf2f2f2), Color(0xFFf2f2f2)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft),
        ),
        child: const Center(
          child: Text(
            "Login / Sign Up",
            style: TextStyle(
              color: Colors.red,
              fontSize: 18.0,
            ),
          ),
        ),
      ),
    );
  }
}
