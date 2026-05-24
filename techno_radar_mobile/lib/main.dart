import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

/* ================= APP ================= */

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    setState(() {
      isLoggedIn = token != null;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.deepPurple,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withOpacity(0.85),
          elevation: 0,
          centerTitle: false,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.black.withOpacity(0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
        ),
      ),
      home: isLoggedIn ? const EventListPage() : const LoginPage(),
    );
  }
}

/* ================= API HELPER ================= */

class ApiHelper {
  static const String localBaseUrl = 'http://127.0.0.1:8000';

  static const String prodBaseUrl =
      'https://web-production-5db5f.up.railway.app';

  static const String baseUrl = prodBaseUrl;

  static Future<Map<String, String>> headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("is_admin") ?? false;
  }
}

/* ================= ASSETS ================= */

class AppAssets {
  static const String loginClosed = 'assets/images/login_closed.png';
  static const String loginOpen = 'assets/images/login_open.png';
  static const String electronicBackground =
      'assets/images/electronic_background.png';
}

/* ================= COMMON UI HELPERS ================= */

String eventDateWithDay(Map event) {
  final date = (event["date"] ?? "").toString();
  final dayOfWeek = (event["day_of_week"] ?? "").toString();

  if (date.isEmpty && dayOfWeek.isEmpty) {
    return "";
  }

  if (dayOfWeek.isEmpty) {
    return date;
  }

  if (date.isEmpty) {
    return dayOfWeek;
  }

  return "$date • $dayOfWeek";
}

class MusicBackground extends StatelessWidget {
  final Widget child;

  const MusicBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            AppAssets.electronicBackground,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.78),
          ),
        ),
        child,
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.22),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

/* ================= IMAGE HELPER ================= */

Widget eventImage(String? imageUrl, {double height = 190}) {
  final normalizedUrl = imageUrl?.trim() ?? "";

  if (normalizedUrl.isEmpty) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.18),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.withOpacity(0.35),
                    Colors.black.withOpacity(0.80),
                    Colors.blueAccent.withOpacity(0.20),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.graphic_eq,
                  size: 58,
                  color: Colors.deepPurpleAccent,
                ),
                SizedBox(height: 12),
                Text(
                  "Brak zdjęcia z Ticketmastera",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Techno Radar",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white10),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.network(
      normalizedUrl,
      fit: BoxFit.fill,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black.withOpacity(0.78),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 56,
                  color: Colors.deepPurpleAccent,
                ),
                SizedBox(height: 12),
                Text(
                  "Nie udało się wczytać zdjęcia",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/* ================= LOGIN ================= */

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Błędne dane logowania")),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoggingIn = false;
        eyesOpen = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd połączenia: $error")),
      );
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
        borderRadius: BorderRadius.circular(18),
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
                          ? "Zalogowano. Witaj w radarze."
                          : "Zaloguj się i odkrywaj eventy techno w całej Polsce",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: isSmallScreen ? 13 : 14,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Zaloguj"),
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

/* ================= REGISTER ================= */

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Użytkownik już istnieje")),
      );
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
      appBar: AppBar(
        title: const Text("Rejestracja"),
      ),
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
                      borderRadius: BorderRadius.circular(18),
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
                        child: const Text("Zarejestruj"),
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

/* ================= MAIN EVENT LIST ================= */

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List events = [];

  final searchController = TextEditingController();

  int page = 1;
  final int limit = 5;
  bool isLoading = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    loadAdmin();
    fetchEvents();
  }

  Future<void> loadAdmin() async {
    final admin = await ApiHelper.isAdmin();

    setState(() {
      isAdmin = admin;
    });
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
    });

    final searchText = searchController.text.trim();

    String url = "${ApiHelper.baseUrl}/events?page=$page&limit=$limit";

    if (searchText.isNotEmpty) {
      url += "&search=${Uri.encodeComponent(searchText)}";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    setState(() {
      events = data is List ? data : [];
      isLoading = false;
    });
  }

  Future<void> deleteEvent(int id) async {
    await http.delete(
      Uri.parse("${ApiHelper.baseUrl}/events/$id"),
      headers: await ApiHelper.headers(),
    );

    fetchEvents();
  }

  void nextPage() {
    if (events.length < limit) return;

    setState(() {
      page++;
    });

    fetchEvents();
  }

  void previousPage() {
    if (page <= 1) return;

    setState(() {
      page--;
    });

    fetchEvents();
  }

  void searchEvents(String value) {
    setState(() {
      page = 1;
    });

    fetchEvents();
  }

  void goAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEventPage()),
    );

    fetchEvents();
  }

  void goEdit(Map event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEventPage(event: event)),
    );

    fetchEvents();
  }

  void goDetails(Map event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          event: event,
          isAdmin: isAdmin,
          onDelete: () async {
            await deleteEvent(event["id"]);
          },
          onEdit: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditEventPage(event: event)),
            );

            fetchEvents();
          },
        ),
      ),
    );

    fetchEvents();
  }

  void goPublicEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublicEventsPage()),
    );
  }

  void goMyEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyEventsPage()),
    );
  }

  void goPendingImportedEvents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingImportedEventsPage()),
    );

    fetchEvents();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("is_admin");

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Color getColor(String type) {
    if (type == "Techno") return Colors.deepPurple;
    if (type == "Hard Techno") return Colors.red;
    if (type == "Acid Techno") return Colors.green;
    if (type == "Minimal") return Colors.orange;
    if (type == "Industrial Techno") return Colors.blueGrey;
    if (type == "House") return Colors.pink;
    if (type == "Tech House") return Colors.teal;
    if (type == "Deep House") return Colors.purpleAccent;
    if (type == "Trance") return Colors.blue;
    if (type == "Psytrance") return Colors.lightBlueAccent;
    if (type == "Drum and Bass") return Colors.lime;
    if (type == "Dubstep") return Colors.indigo;
    if (type == "EDM") return Colors.cyan;
    if (type == "Rave") return Colors.deepOrange;
    if (type == "Electronic") return Colors.deepPurpleAccent;
    return Colors.deepPurple;
  }

  Widget eventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => goDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              eventImage(event["image_url"], height: 190),
              const SizedBox(height: 12),
              Text(
                event["name"] ?? "",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("📍 ${event["city"] ?? ""}"),
              Text("📅 ${eventDateWithDay(event)}"),
              Text("🏢 ${event["club"] ?? ""}"),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: getColor(event["music_type"] ?? ""),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  event["music_type"] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => goDetails(event),
                  ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => goEdit(event),
                    ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteEvent(event["id"]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paginationBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black.withOpacity(0.45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: page == 1 ? null : previousPage,
            icon: const Icon(Icons.chevron_left),
            label: const Text("Poprzednia"),
          ),
          Text(
            "Strona $page",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: events.length < limit ? null : nextPage,
            icon: const Icon(Icons.chevron_right),
            label: const Text("Następna"),
          ),
        ],
      ),
    );
  }

  Widget welcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              AppAssets.loginOpen,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Witaj w Techno Radar",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? "Masz dostęp administratora. Możesz zarządzać eventami i importem."
                      : "Przeglądaj wydarzenia, zapisuj ulubione i odkrywaj nowe brzmienia.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "Techno Radar Admin" : "Techno Radar"),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: "Eventy do zatwierdzenia",
              onPressed: goPendingImportedEvents,
              icon: const Icon(Icons.fact_check),
            ),
          IconButton(
            tooltip: "Publiczne eventy",
            onPressed: goPublicEvents,
            icon: const Icon(Icons.public),
          ),
          IconButton(
            tooltip: "Moje eventy",
            onPressed: goMyEvents,
            icon: const Icon(Icons.favorite),
          ),
          IconButton(
            tooltip: "Wyloguj",
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: MusicBackground(
        child: Column(
          children: [
            welcomeBanner(),
            if (isAdmin)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Tryb administratora: możesz dodawać, edytować, usuwać i zatwierdzać eventy.",
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: searchController,
                onChanged: searchEvents,
                decoration: const InputDecoration(
                  hintText:
                      "Szukaj po nazwie, mieście, klubie lub typie muzyki",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? const Center(
                          child: Text(
                            "Brak eventów",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (_, index) {
                            return eventCard(events[index]);
                          },
                        ),
            ),
            paginationBar(),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: goAdd,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/* ================= EVENT DETAILS ================= */

class EventDetailsPage extends StatelessWidget {
  final Map event;
  final bool isAdmin;
  final Future<void> Function() onDelete;
  final Future<void> Function() onEdit;

  const EventDetailsPage({
    super.key,
    required this.event,
    required this.isAdmin,
    required this.onDelete,
    required this.onEdit,
  });

  Widget detailRow(String label, String value, IconData icon) {
    return Card(
      color: Colors.black.withOpacity(0.68),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Future<void> addToMyList(BuildContext context) async {
    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/my-events/${event["id"]}"),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data["message"] ?? data["error"] ?? "Gotowe"),
      ),
    );
  }

  Future<void> openTicketLink(BuildContext context) async {
    final sourceUrl = (event["source_url"] ?? "").toString().trim();

    if (sourceUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Brak linku do biletów")),
      );
      return;
    }

    final uri = Uri.tryParse(sourceUrl);

    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Niepoprawny link do biletów: $sourceUrl")),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: "_blank",
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nie udało się otworzyć linku")),
        );
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd otwierania linku: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicType = event["music_type"] ?? "";
    final sourceUrl = (event["source_url"] ?? "").toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Szczegóły eventu"),
      ),
      body: MusicBackground(
        child: Center(
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eventImage(event["image_url"], height: 280),
                      const SizedBox(height: 18),
                      Text(
                        event["name"] ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      detailRow(
                        "Miasto",
                        event["city"] ?? "",
                        Icons.location_city,
                      ),
                      detailRow(
                        "Data",
                        eventDateWithDay(event),
                        Icons.calendar_month,
                      ),
                      detailRow(
                        "Klub / miejsce",
                        event["club"] ?? "",
                        Icons.apartment,
                      ),
                      detailRow(
                        "Typ muzyki",
                        musicType,
                        Icons.music_note,
                      ),
                      if (sourceUrl.isNotEmpty)
                        detailRow(
                          "Źródło",
                          "Ticketmaster",
                          Icons.confirmation_number,
                        ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => addToMyList(context),
                          icon: const Icon(Icons.favorite),
                          label: const Text("Dodaj do moich eventów"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: sourceUrl.isEmpty
                              ? null
                              : () => openTicketLink(context),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Kup / zobacz bilety"),
                        ),
                      ),
                      if (isAdmin) const SizedBox(height: 20),
                      if (isAdmin)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await onEdit();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Edytuj"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await onDelete();
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text("Usuń"),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= EVENT FORM ================= */

class EventForm extends StatelessWidget {
  final String title;
  final String buttonText;

  final TextEditingController name;
  final TextEditingController city;
  final TextEditingController date;
  final TextEditingController club;
  final TextEditingController musicType;
  final TextEditingController imageUrl;

  final VoidCallback onPressed;
  final VoidCallback onPickImage;
  final bool uploadingImage;

  const EventForm({
    super.key,
    required this.title,
    required this.buttonText,
    required this.name,
    required this.city,
    required this.date,
    required this.club,
    required this.musicType,
    required this.imageUrl,
    required this.onPressed,
    required this.onPickImage,
    required this.uploadingImage,
  });

  Future<void> chooseDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selectedDate != null) {
      date.text =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    const musicTypes = [
      "Techno",
      "Hard Techno",
      "Acid Techno",
      "Minimal",
      "Industrial Techno",
      "House",
      "Tech House",
      "Deep House",
      "Trance",
      "Psytrance",
      "Drum and Bass",
      "Dubstep",
      "EDM",
      "Rave",
      "Electronic",
    ];

    String? selectedMusicType;

    if (musicType.text.isNotEmpty && musicTypes.contains(musicType.text)) {
      selectedMusicType = musicType.text;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: MusicBackground(
        child: Center(
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(20),
            child: GlassPanel(
              padding: const EdgeInsets.all(25),
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: "Nazwa",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(
                      labelText: "Miasto",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: date,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Data",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () => chooseDate(context),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: club,
                    decoration: const InputDecoration(
                      labelText: "Klub",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMusicType,
                    decoration: const InputDecoration(
                      labelText: "Typ muzyki",
                    ),
                    items: musicTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      musicType.text = value ?? "";
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrl,
                    decoration: const InputDecoration(
                      labelText: "Link do zdjęcia / flyera",
                      hintText: "Możesz wkleić link albo wybrać plik",
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: uploadingImage ? null : onPickImage,
                      icon: uploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        uploadingImage
                            ? "Wysyłanie zdjęcia..."
                            : "Wybierz zdjęcie",
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  eventImage(imageUrl.text, height: 170),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: uploadingImage ? null : onPressed,
                      child: Text(buttonText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= ADD EVENT ================= */

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final name = TextEditingController();
  final city = TextEditingController();
  final date = TextEditingController();
  final club = TextEditingController();
  final musicType = TextEditingController();
  final imageUrl = TextEditingController();
  final cloudinaryPublicId = TextEditingController();

  bool uploadingImage = false;

  bool isEmpty() {
    return name.text.trim().isEmpty ||
        city.text.trim().isEmpty ||
        date.text.trim().isEmpty ||
        club.text.trim().isEmpty ||
        musicType.text.trim().isEmpty;
  }

  Future<void> pickAndUploadImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) {
      return;
    }

    final file = result.files.first;

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się odczytać pliku")),
      );
      return;
    }

    setState(() {
      uploadingImage = true;
    });

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiHelper.baseUrl}/upload-image"),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        file.bytes!,
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    setState(() {
      uploadingImage = false;
    });

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(responseBody);

      setState(() {
        imageUrl.text = data["image_url"] ?? "";
        cloudinaryPublicId.text = data["public_id"] ?? "";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zdjęcie wysłane")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd uploadu: $responseBody")),
      );
    }
  }

  Future<void> addEvent() async {
    if (isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uzupełnij wszystkie wymagane pola")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/events"),
      headers: await ApiHelper.headers(),
      body: jsonEncode({
        "name": name.text.trim(),
        "city": city.text.trim(),
        "date": date.text.trim(),
        "club": club.text.trim(),
        "music_type": musicType.text.trim(),
        "image_url": imageUrl.text.trim(),
        "cloudinary_public_id": cloudinaryPublicId.text.trim(),
        "source_name": "manual",
        "source_url": "",
        "external_id": "",
        "is_verified": 1,
        "imported_at": "",
      }),
    );

    if (response.statusCode == 200 && mounted) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd dodawania: ${response.body}")),
      );
    }
  }

  @override
  void dispose() {
    name.dispose();
    city.dispose();
    date.dispose();
    club.dispose();
    musicType.dispose();
    imageUrl.dispose();
    cloudinaryPublicId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EventForm(
      title: "Dodaj event",
      buttonText: "Dodaj",
      name: name,
      city: city,
      date: date,
      club: club,
      musicType: musicType,
      imageUrl: imageUrl,
      onPressed: addEvent,
      onPickImage: pickAndUploadImage,
      uploadingImage: uploadingImage,
    );
  }
}

/* ================= EDIT EVENT ================= */

class EditEventPage extends StatefulWidget {
  final Map event;

  const EditEventPage({
    super.key,
    required this.event,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final name = TextEditingController();
  final city = TextEditingController();
  final date = TextEditingController();
  final club = TextEditingController();
  final musicType = TextEditingController();
  final imageUrl = TextEditingController();
  final cloudinaryPublicId = TextEditingController();

  bool uploadingImage = false;

  @override
  void initState() {
    super.initState();

    name.text = widget.event["name"] ?? "";
    city.text = widget.event["city"] ?? "";
    date.text = widget.event["date"] ?? "";
    club.text = widget.event["club"] ?? "";
    musicType.text = widget.event["music_type"] ?? "";
    imageUrl.text = widget.event["image_url"] ?? "";
    cloudinaryPublicId.text = widget.event["cloudinary_public_id"] ?? "";
  }

  bool isEmpty() {
    return name.text.trim().isEmpty ||
        city.text.trim().isEmpty ||
        date.text.trim().isEmpty ||
        club.text.trim().isEmpty ||
        musicType.text.trim().isEmpty;
  }

  Future<void> pickAndUploadImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) {
      return;
    }

    final file = result.files.first;

    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie udało się odczytać pliku")),
      );
      return;
    }

    setState(() {
      uploadingImage = true;
    });

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiHelper.baseUrl}/upload-image"),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        file.bytes!,
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    setState(() {
      uploadingImage = false;
    });

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(responseBody);

      setState(() {
        imageUrl.text = data["image_url"] ?? "";
        cloudinaryPublicId.text = data["public_id"] ?? "";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zdjęcie wysłane")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd uploadu: $responseBody")),
      );
    }
  }

  Future<void> updateEvent() async {
    if (isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uzupełnij wszystkie wymagane pola")),
      );
      return;
    }

    final response = await http.put(
      Uri.parse("${ApiHelper.baseUrl}/events/${widget.event["id"]}"),
      headers: await ApiHelper.headers(),
      body: jsonEncode({
        "name": name.text.trim(),
        "city": city.text.trim(),
        "date": date.text.trim(),
        "club": club.text.trim(),
        "music_type": musicType.text.trim(),
        "image_url": imageUrl.text.trim(),
        "cloudinary_public_id": cloudinaryPublicId.text.trim(),
        "source_name": widget.event["source_name"] ?? "manual",
        "source_url": widget.event["source_url"] ?? "",
        "external_id": widget.event["external_id"] ?? "",
        "is_verified": widget.event["is_verified"] ?? 1,
        "imported_at": widget.event["imported_at"] ?? "",
      }),
    );

    if (response.statusCode == 200 && mounted) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd edycji: ${response.body}")),
      );
    }
  }

  @override
  void dispose() {
    name.dispose();
    city.dispose();
    date.dispose();
    club.dispose();
    musicType.dispose();
    imageUrl.dispose();
    cloudinaryPublicId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EventForm(
      title: "Edytuj event",
      buttonText: "Zapisz",
      name: name,
      city: city,
      date: date,
      club: club,
      musicType: musicType,
      imageUrl: imageUrl,
      onPressed: updateEvent,
      onPickImage: pickAndUploadImage,
      uploadingImage: uploadingImage,
    );
  }
}

/* ================= PUBLIC EVENTS ================= */

class PublicEventsPage extends StatefulWidget {
  const PublicEventsPage({super.key});

  @override
  State<PublicEventsPage> createState() => _PublicEventsPageState();
}

class _PublicEventsPageState extends State<PublicEventsPage> {
  List events = [];
  int year = 2026;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPublicEvents();
  }

  Future<void> fetchPublicEvents() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse("${ApiHelper.baseUrl}/public-events?year=$year"),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    setState(() {
      events = data is List ? data : [];
      isLoading = false;
    });
  }

  Future<void> addToMyList(int eventId) async {
    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/my-events/$eventId"),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"] ?? data["error"] ?? "Gotowe")),
    );
  }

  void goDetails(Map event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          event: event,
          isAdmin: false,
          onDelete: () async {},
          onEdit: () async {},
        ),
      ),
    );
  }

  Widget publicEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.72),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => goDetails(event),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: eventImage(event["image_url"], height: 190),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(event["name"] ?? ""),
              subtitle:
                  Text("${event["city"] ?? ""} • ${eventDateWithDay(event)}"),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Dodaj"),
                onPressed: () => addToMyList(event["id"]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publiczne eventy"),
      ),
      body: MusicBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<int>(
                value: year,
                decoration: const InputDecoration(
                  labelText: "Wybierz rok",
                ),
                items: [2024, 2025, 2026, 2027, 2028]
                    .map(
                      (itemYear) => DropdownMenuItem<int>(
                        value: itemYear,
                        child: Text(itemYear.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    year = value;
                  });

                  fetchPublicEvents();
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? const Center(child: Text("Brak publicznych eventów"))
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (_, index) {
                            return publicEventCard(events[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= PENDING IMPORTED EVENTS ================= */

class PendingImportedEventsPage extends StatefulWidget {
  const PendingImportedEventsPage({super.key});

  @override
  State<PendingImportedEventsPage> createState() =>
      _PendingImportedEventsPageState();
}

class _PendingImportedEventsPageState extends State<PendingImportedEventsPage> {
  List events = [];
  bool isLoading = false;
  bool isImporting = false;

  @override
  void initState() {
    super.initState();
    fetchPendingEvents();
  }

  Future<void> fetchPendingEvents() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse("${ApiHelper.baseUrl}/admin/imported-events/pending"),
      headers: await ApiHelper.headers(),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        events = data is List ? data : [];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd pobierania eventów: ${response.body}"),
        ),
      );
    }
  }

  Future<void> importFromTicketmaster() async {
    if (isImporting) return;

    setState(() {
      isImporting = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${ApiHelper.baseUrl}/admin/import-ticketmaster-events"),
        headers: await ApiHelper.headers(),
      );

      if (!mounted) return;

      setState(() {
        isImporting = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Import zakończony. Dodano: ${data["imported_count"]}, pominięto: ${data["skipped_count"]}",
            ),
          ),
        );

        fetchPendingEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Błąd importu: ${response.body}"),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd połączenia podczas importu: $error"),
        ),
      );
    }
  }

  Future<void> approveEvent(int eventId) async {
    final response = await http.put(
      Uri.parse("${ApiHelper.baseUrl}/admin/events/$eventId/verify"),
      headers: await ApiHelper.headers(),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event zatwierdzony")),
      );

      fetchPendingEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd zatwierdzania: ${response.body}"),
        ),
      );
    }
  }

  Widget pendingEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eventImage(event["image_url"], height: 190),
            const SizedBox(height: 12),
            Text(
              event["name"] ?? "",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text("📍 Miasto: ${event["city"] ?? ""}"),
            Text("📅 Data: ${eventDateWithDay(event)}"),
            Text("🏢 Klub: ${event["club"] ?? ""}"),
            Text("🎵 Typ: ${event["music_type"] ?? ""}"),
            const SizedBox(height: 8),
            Text("Źródło: ${event["source_name"] ?? ""}"),
            Text(
              "Link: ${event["source_url"] ?? ""}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Zaimportowano: ${event["imported_at"] ?? ""}",
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => approveEvent(event["id"]),
                icon: const Icon(Icons.check),
                label: const Text("Zatwierdź event"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eventy do zatwierdzenia"),
        actions: [
          IconButton(
            tooltip: "Importuj z Ticketmaster",
            onPressed: isImporting ? null : importFromTicketmaster,
            icon: isImporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download),
          ),
          IconButton(
            tooltip: "Odśwież",
            onPressed: isLoading ? null : fetchPendingEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: MusicBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : events.isEmpty
                ? const Center(
                    child: Text(
                      "Brak eventów do zatwierdzenia",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (_, index) {
                      return pendingEventCard(events[index]);
                    },
                  ),
      ),
    );
  }
}

/* ================= MY EVENTS ================= */

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  List events = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMyEvents();
  }

  Future<void> fetchMyEvents() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse("${ApiHelper.baseUrl}/my-events"),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    setState(() {
      events = data is List ? data : [];
      isLoading = false;
    });
  }

  Future<void> removeFromMyList(int eventId) async {
    final response = await http.delete(
      Uri.parse("${ApiHelper.baseUrl}/my-events/$eventId"),
      headers: await ApiHelper.headers(),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data["message"] ?? data["error"] ?? "Gotowe")),
    );

    fetchMyEvents();
  }

  void goDetails(Map event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(
          event: event,
          isAdmin: false,
          onDelete: () async {},
          onEdit: () async {},
        ),
      ),
    ).then((_) {
      fetchMyEvents();
    });
  }

  Widget myEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.72),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => goDetails(event),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: eventImage(event["image_url"], height: 190),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(event["name"] ?? ""),
              subtitle:
                  Text("${event["city"] ?? ""} • ${eventDateWithDay(event)}"),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text("Usuń"),
                onPressed: () => removeFromMyList(event["id"]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje eventy"),
      ),
      body: MusicBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : events.isEmpty
                ? const Center(child: Text("Brak eventów na Twojej liście"))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (_, index) {
                      return myEventCard(events[index]);
                    },
                  ),
      ),
    );
  }
}