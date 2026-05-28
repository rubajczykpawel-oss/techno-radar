import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_helper.dart';
import '../constants/app_assets.dart';
import '../widgets/glass_panel.dart';
import '../widgets/music_background.dart';
import 'event_list_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool isLoggingIn = false;
  bool eyesOpen = false;
  bool imagesPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!imagesPrecached) {
      imagesPrecached = true;

      precacheImage(const AssetImage(AppAssets.loginClosed), context);
      precacheImage(const AssetImage(AppAssets.loginOpen), context);
      precacheImage(const AssetImage(AppAssets.electronicBackground), context);
    }
  }

  Future<void> login() async {
    if (isLoggingIn) return;

    setState(() {
      isLoggingIn = true;
      eyesOpen = false;
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiHelper.baseUrl}/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.text.trim(),
          "password": password.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["message"] == "Login successful") {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", data["token"]);

        bool admin = false;

        if (data["is_admin"] == 1) {
          admin = true;
        }

        await prefs.setBool("is_admin", admin);

        if (!mounted) return;

        setState(() {
          eyesOpen = true;
        });

        await Future.delayed(const Duration(milliseconds: 1200));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EventListPage()),
        );
      } else {
        if (!mounted) return;

        setState(() {
          isLoggingIn = false;
          eyesOpen = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Błędne dane logowania")));
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoggingIn = false;
        eyesOpen = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Błąd połączenia: $error")));
    }
  }

  void goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Widget loginCharacterImage(bool isSmallScreen) {
    final imageHeight = isSmallScreen ? 210.0 : 330.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: ClipRRect(
        key: ValueKey<bool>(eyesOpen),
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          eyesOpen ? AppAssets.loginOpen : AppAssets.loginClosed,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 520 || screenHeight < 760;

    final horizontalPadding = isSmallScreen ? 12.0 : 20.0;
    final panelPadding = isSmallScreen ? 16.0 : 26.0;
    final titleSize = isSmallScreen ? 24.0 : 30.0;
    final panelWidth = isSmallScreen ? double.infinity : 460.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: MusicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isSmallScreen ? 10 : 20,
              ),
              child: GlassPanel(
                width: panelWidth,
                padding: EdgeInsets.all(panelPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    loginCharacterImage(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 12 : 18),
                    Text(
                      "TECHNO RADAR",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      eyesOpen
                          ? "Zalogowano. Witaj w radarze wydarzeń."
                          : "Znajdź wydarzenia techno w Polsce, zapisz ulubione i sprawdź bilety.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: isSmallScreen ? 13 : 14,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 26),
                    TextField(
                      controller: email,
                      enabled: !isLoggingIn,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 14),
                    TextField(
                      controller: password,
                      enabled: !isLoggingIn,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Hasło",
                        prefixIcon: Icon(Icons.lock),
                      ),
                      onSubmitted: (_) => login(),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoggingIn ? null : login,
                        child: isLoggingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Zaloguj się"),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),
                    TextButton(
                      onPressed: isLoggingIn ? null : goRegister,
                      child: const Text("Nie masz konta? Zarejestruj się"),
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
