import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_helper.dart';
import '../constants/app_assets.dart';
import '../widgets/music_background.dart';
import '../widgets/glass_panel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> register() async {
    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username.text.trim(),
        "email": email.text.trim(),
        "password": password.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    if (data["message"] == "User registered") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konto utworzone. Możesz się zalogować.")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Użytkownik już istnieje")));
    }
  }

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 520;

    return Scaffold(
      appBar: AppBar(title: const Text("Rejestracja")),
      body: MusicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
              child: GlassPanel(
                width: isSmallScreen ? double.infinity : 430,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        AppAssets.loginClosed,
                        height: isSmallScreen ? 160 : 210,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 18),
                    Text(
                      "Utwórz konto",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    TextField(
                      controller: username,
                      decoration: const InputDecoration(
                        labelText: "Nazwa użytkownika",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 14),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 14),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Hasło",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: register,
                        child: const Text("Zarejestruj się"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
