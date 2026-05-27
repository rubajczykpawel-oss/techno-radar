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
        primaryColor: Colors.deepPurpleAccent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black.withOpacity(0.92),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.42),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(
              color: Colors.deepPurpleAccent.withOpacity(0.9),
              width: 1.5,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.black.withOpacity(0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
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
  final formattedDate = (event["formatted_date"] ?? "").toString();
  final date = (event["date"] ?? "").toString();
  final dayOfWeek = (event["day_of_week"] ?? "").toString();

  if (formattedDate.isNotEmpty) {
    return formattedDate;
  }

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

String eventCityName(Map event) {
  final cityDisplay = (event["city_display"] ?? "").toString();
  final city = (event["city"] ?? "").toString();

  if (cityDisplay.isNotEmpty) {
    return cityDisplay;
  }

  return city;
}

String eventDaysUntil(Map event) {
  return (event["days_until"] ?? "").toString();
}

String eventSourceName(Map event) {
  final source = (event["source_name"] ?? "").toString();

  if (source == "manual") {
    return "Dodany ręcznie";
  }

  if (source == "Ticketmaster") {
    return "Ticketmaster";
  }

  if (source.isEmpty) {
    return "Nieznane źródło";
  }

  return source;
}

String eventMusicTypeName(Map event) {
  final type = (event["music_type"] ?? "").toString();

  if (type == "Electronic") {
    return "Muzyka elektroniczna";
  }

  return type;
}

List<DropdownMenuItem<int>> yearDropdownItems() {
  return const [
    DropdownMenuItem(
      value: 0,
      child: Text("Wszystkie lata"),
    ),
    DropdownMenuItem(
      value: 2024,
      child: Text("2024"),
    ),
    DropdownMenuItem(
      value: 2025,
      child: Text("2025"),
    ),
    DropdownMenuItem(
      value: 2026,
      child: Text("2026"),
    ),
    DropdownMenuItem(
      value: 2027,
      child: Text("2027"),
    ),
    DropdownMenuItem(
      value: 2028,
      child: Text("2028"),
    ),
  ];
}

List<DropdownMenuItem<int>> monthDropdownItems() {
  return const [
    DropdownMenuItem(
      value: 0,
      child: Text("Wszystkie miesiące"),
    ),
    DropdownMenuItem(
      value: 1,
      child: Text("Styczeń"),
    ),
    DropdownMenuItem(
      value: 2,
      child: Text("Luty"),
    ),
    DropdownMenuItem(
      value: 3,
      child: Text("Marzec"),
    ),
    DropdownMenuItem(
      value: 4,
      child: Text("Kwiecień"),
    ),
    DropdownMenuItem(
      value: 5,
      child: Text("Maj"),
    ),
    DropdownMenuItem(
      value: 6,
      child: Text("Czerwiec"),
    ),
    DropdownMenuItem(
      value: 7,
      child: Text("Lipiec"),
    ),
    DropdownMenuItem(
      value: 8,
      child: Text("Sierpień"),
    ),
    DropdownMenuItem(
      value: 9,
      child: Text("Wrzesień"),
    ),
    DropdownMenuItem(
      value: 10,
      child: Text("Październik"),
    ),
    DropdownMenuItem(
      value: 11,
      child: Text("Listopad"),
    ),
    DropdownMenuItem(
      value: 12,
      child: Text("Grudzień"),
    ),
  ];
}

Future<void> handleUnauthorized(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove("token");
  await prefs.remove("is_admin");

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Sesja wygasła. Zaloguj się ponownie."),
    ),
  );

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

/* ================= COMMON WIDGETS ================= */

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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.82),
                  Colors.black.withOpacity(0.92),
                ],
              ),
            ),
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
        color: Colors.black.withOpacity(0.64),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.deepPurpleAccent.withOpacity(0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget neonTag({
  required String text,
  IconData? icon,
  Color color = Colors.deepPurpleAccent,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withOpacity(0.55)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 15, color: color),
        if (icon != null) const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  Widget? action,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: GlassPanel(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                height: 1.35,
              ),
            ),
            if (action != null) const SizedBox(height: 18),
            if (action != null) action,
          ],
        ),
      ),
    ),
  );
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.deepPurpleAccent.withOpacity(0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.12),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurpleAccent.withOpacity(0.28),
                    Colors.black.withOpacity(0.88),
                    Colors.blueAccent.withOpacity(0.16),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.graphic_eq,
                    size: 58,
                    color: Colors.deepPurpleAccent,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Brak zdjęcia wydarzenia",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Organizator nie udostępnił grafiki dla tego wydarzenia.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.60),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
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
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white10),
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.network(
      normalizedUrl,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black.withOpacity(0.78),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
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
                        color: Colors.white.withOpacity(0.75),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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

/* ================= MAIN EVENT LIST ================= */

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List events = [];

  final searchController = TextEditingController();

  String selectedCity = "";
  String selectedMusicType = "";

  int selectedYear = 0;
  int selectedMonth = 0;

  int page = 1;
  final int limit = 5;
  bool isLoading = false;
  bool isAdmin = false;
  bool filtersExpanded = true;

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

    if (selectedCity.isNotEmpty) {
      url += "&city=${Uri.encodeComponent(selectedCity)}";
    }

    if (selectedMusicType.isNotEmpty) {
      url += "&music_type=${Uri.encodeComponent(selectedMusicType)}";
    }

    if (selectedYear > 0) {
      url += "&year=$selectedYear";
    }

    if (selectedYear > 0 && selectedMonth > 0) {
      url += "&month=$selectedMonth";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await ApiHelper.headers(),
    );

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

    final data = jsonDecode(response.body);

    setState(() {
      events = data is List ? data : [];
      isLoading = false;
    });
  }

  Future<void> deleteEvent(int id) async {
    final response = await http.delete(
      Uri.parse("${ApiHelper.baseUrl}/events/$id"),
      headers: await ApiHelper.headers(),
    );

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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

  void changeCity(String? value) {
    setState(() {
      selectedCity = value ?? "";
      page = 1;
    });

    fetchEvents();
  }

  void changeMusicType(String? value) {
    setState(() {
      selectedMusicType = value ?? "";
      page = 1;
    });

    fetchEvents();
  }

  void changeYear(int? value) {
    setState(() {
      selectedYear = value ?? 0;
      page = 1;

      if (selectedYear == 0) {
        selectedMonth = 0;
      }
    });

    fetchEvents();
  }

  void changeMonth(int? value) {
    setState(() {
      selectedMonth = value ?? 0;
      page = 1;

      if (selectedMonth > 0 && selectedYear == 0) {
        selectedYear = DateTime.now().year;
      }
    });

    fetchEvents();
  }

  void clearFilters() {
    setState(() {
      searchController.clear();
      selectedCity = "";
      selectedMusicType = "";
      selectedYear = 0;
      selectedMonth = 0;
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
    if (type == "Techno") return Colors.deepPurpleAccent;
    if (type == "Hard Techno") return Colors.redAccent;
    if (type == "Acid Techno") return Colors.greenAccent;
    if (type == "Minimal") return Colors.orangeAccent;
    if (type == "Industrial Techno") return Colors.blueGrey;
    if (type == "House") return Colors.pinkAccent;
    if (type == "Tech House") return Colors.tealAccent;
    if (type == "Deep House") return Colors.purpleAccent;
    if (type == "Trance") return Colors.blueAccent;
    if (type == "Psytrance") return Colors.lightBlueAccent;
    if (type == "Drum and Bass") return Colors.limeAccent;
    if (type == "Dubstep") return Colors.indigoAccent;
    if (type == "EDM") return Colors.cyanAccent;
    if (type == "Rave") return Colors.deepOrangeAccent;
    if (type == "Electronic") return Colors.deepPurpleAccent;
    return Colors.deepPurpleAccent;
  }

  Widget eventCard(Map event) {
    final musicType = event["music_type"] ?? "";
    final accentColor = getColor(musicType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.34)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.black.withOpacity(0.76),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => goDetails(event),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                eventImage(event["image_url"], height: 190),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    neonTag(
                      text: eventMusicTypeName(event),
                      icon: Icons.music_note,
                      color: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${eventCityName(event)} • ${event["club"] ?? ""}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    neonTag(
                      text: eventDateWithDay(event),
                      icon: Icons.calendar_month,
                      color: Colors.deepPurpleAccent,
                    ),
                    if (eventDaysUntil(event).isNotEmpty)
                      neonTag(
                        text: eventDaysUntil(event),
                        icon: Icons.hourglass_bottom,
                        color: Colors.cyanAccent,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => goDetails(event),
                        icon: const Icon(Icons.info_outline),
                        label: const Text("Szczegóły"),
                      ),
                    ),
                    if (isAdmin) const SizedBox(width: 8),
                    if (isAdmin)
                      IconButton(
                        tooltip: "Edytuj wydarzenie",
                        icon: const Icon(Icons.edit),
                        onPressed: () => goEdit(event),
                      ),
                    if (isAdmin)
                      IconButton(
                        tooltip: "Usuń wydarzenie",
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteEvent(event["id"]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget paginationBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black.withOpacity(0.55),
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
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.66),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.12),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              AppAssets.loginOpen,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Odkrywaj wydarzenia techno w Polsce",
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? "Tryb administratora: zarządzaj wydarzeniami, importem i zatwierdzaniem."
                      : "Znajdź najbliższe imprezy, sprawdź bilety i zapisuj ulubione wydarzenia.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filtersPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.deepPurpleAccent),
            title: const Text(
              "Filtry wydarzeń",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              "Dopasuj listę do miasta, gatunku i terminu.",
              style: TextStyle(color: Colors.white54),
            ),
            trailing: IconButton(
              icon: Icon(
                filtersExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  filtersExpanded = !filtersExpanded;
                });
              },
            ),
          ),
          if (filtersExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: searchEvents,
                    decoration: const InputDecoration(
                      hintText:
                          "Szukaj po nazwie, mieście, miejscu lub gatunku",
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: const InputDecoration(
                      labelText: "Miasto",
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "",
                        child: Text("Wszystkie miasta"),
                      ),
                      DropdownMenuItem(
                        value: "Warsaw",
                        child: Text("Warszawa"),
                      ),
                      DropdownMenuItem(
                        value: "Kraków",
                        child: Text("Kraków"),
                      ),
                      DropdownMenuItem(
                        value: "Wrocław",
                        child: Text("Wrocław"),
                      ),
                      DropdownMenuItem(
                        value: "Gdańsk",
                        child: Text("Gdańsk"),
                      ),
                      DropdownMenuItem(
                        value: "Katowice",
                        child: Text("Katowice"),
                      ),
                      DropdownMenuItem(
                        value: "Poznań",
                        child: Text("Poznań"),
                      ),
                      DropdownMenuItem(
                        value: "Łódź",
                        child: Text("Łódź"),
                      ),
                    ],
                    onChanged: changeCity,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedMusicType,
                    decoration: const InputDecoration(
                      labelText: "Gatunek muzyki",
                      prefixIcon: Icon(Icons.music_note),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "",
                        child: Text("Wszystkie gatunki"),
                      ),
                      DropdownMenuItem(
                        value: "Techno",
                        child: Text("Techno"),
                      ),
                      DropdownMenuItem(
                        value: "Hard Techno",
                        child: Text("Hard Techno"),
                      ),
                      DropdownMenuItem(
                        value: "Acid Techno",
                        child: Text("Acid Techno"),
                      ),
                      DropdownMenuItem(
                        value: "Minimal",
                        child: Text("Minimal"),
                      ),
                      DropdownMenuItem(
                        value: "Industrial Techno",
                        child: Text("Industrial Techno"),
                      ),
                      DropdownMenuItem(
                        value: "House",
                        child: Text("House"),
                      ),
                      DropdownMenuItem(
                        value: "Tech House",
                        child: Text("Tech House"),
                      ),
                      DropdownMenuItem(
                        value: "Deep House",
                        child: Text("Deep House"),
                      ),
                      DropdownMenuItem(
                        value: "Trance",
                        child: Text("Trance"),
                      ),
                      DropdownMenuItem(
                        value: "Psytrance",
                        child: Text("Psytrance"),
                      ),
                      DropdownMenuItem(
                        value: "Drum and Bass",
                        child: Text("Drum and Bass"),
                      ),
                      DropdownMenuItem(
                        value: "Dubstep",
                        child: Text("Dubstep"),
                      ),
                      DropdownMenuItem(
                        value: "EDM",
                        child: Text("EDM"),
                      ),
                      DropdownMenuItem(
                        value: "Rave",
                        child: Text("Rave"),
                      ),
                      DropdownMenuItem(
                        value: "Electronic",
                        child: Text("Muzyka elektroniczna"),
                      ),
                    ],
                    onChanged: changeMusicType,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: "Rok",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: yearDropdownItems(),
                    onChanged: changeYear,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: "Miesiąc",
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    items: monthDropdownItems(),
                    onChanged: changeMonth,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: clearFilters,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text("Wyczyść filtry"),
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
              tooltip: "Wydarzenia do zatwierdzenia",
              onPressed: goPendingImportedEvents,
              icon: const Icon(Icons.fact_check),
            ),
          IconButton(
            tooltip: "Wszystkie wydarzenia",
            onPressed: goPublicEvents,
            icon: const Icon(Icons.public),
          ),
          IconButton(
            tooltip: "Moje wydarzenia",
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
            filtersPanel(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? emptyState(
                          icon: Icons.search_off,
                          title: "Nie znaleziono wydarzeń",
                          subtitle:
                              "Zmień filtry albo wybierz inny miesiąc, aby zobaczyć więcej wydarzeń.",
                          action: OutlinedButton.icon(
                            onPressed: clearFilters,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text("Wyczyść filtry"),
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
          ? FloatingActionButton.extended(
              onPressed: goAdd,
              icon: const Icon(Icons.add),
              label: const Text("Dodaj"),
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
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value.isEmpty ? "Brak informacji" : value),
      ),
    );
  }

  Future<void> addToMyList(BuildContext context) async {
    final response = await http.post(
      Uri.parse("${ApiHelper.baseUrl}/my-events/${event["id"]}"),
      headers: await ApiHelper.headers(),
    );

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

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
    final musicType = eventMusicTypeName(event);
    final sourceUrl = (event["source_url"] ?? "").toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Szczegóły wydarzenia"),
      ),
      body: MusicBackground(
        child: Center(
          child: Container(
            width: 620,
            padding: const EdgeInsets.all(18),
            child: ListView(
              children: [
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eventImage(event["image_url"], height: 300),
                      const SizedBox(height: 18),
                      Text(
                        event["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          neonTag(
                            text: eventCityName(event),
                            icon: Icons.location_city,
                            color: Colors.deepPurpleAccent,
                          ),
                          neonTag(
                            text: musicType,
                            icon: Icons.music_note,
                            color: Colors.cyanAccent,
                          ),
                          if (eventDaysUntil(event).isNotEmpty)
                            neonTag(
                              text: eventDaysUntil(event),
                              icon: Icons.hourglass_bottom,
                              color: Colors.greenAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      detailRow(
                        "Miasto",
                        eventCityName(event),
                        Icons.location_city,
                      ),
                      detailRow(
                        "Data wydarzenia",
                        eventDateWithDay(event),
                        Icons.calendar_month,
                      ),
                      if (eventDaysUntil(event).isNotEmpty)
                        detailRow(
                          "Czas do wydarzenia",
                          eventDaysUntil(event),
                          Icons.hourglass_bottom,
                        ),
                      detailRow(
                        "Miejsce",
                        event["club"] ?? "",
                        Icons.apartment,
                      ),
                      detailRow(
                        "Gatunek muzyki",
                        musicType,
                        Icons.music_note,
                      ),
                      detailRow(
                        "Źródło informacji",
                        eventSourceName(event),
                        Icons.confirmation_number,
                      ),
                      if (sourceUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Text(
                            "To wydarzenie pochodzi z Ticketmastera. Kliknij poniżej, aby przejść do strony wydarzenia i sprawdzić bilety.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.66),
                              height: 1.35,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => addToMyList(context),
                          icon: const Icon(Icons.favorite),
                          label: const Text("Dodaj do moich wydarzeń"),
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
                              child: OutlinedButton.icon(
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
            width: 500,
            padding: const EdgeInsets.all(18),
            child: GlassPanel(
              padding: const EdgeInsets.all(22),
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: "Nazwa wydarzenia",
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
                      labelText: "Data wydarzenia",
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    onTap: () => chooseDate(context),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: club,
                    decoration: const InputDecoration(
                      labelText: "Miejsce / klub",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMusicType,
                    decoration: const InputDecoration(
                      labelText: "Gatunek muzyki",
                    ),
                    items: musicTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type == "Electronic" ? "Muzyka elektroniczna" : type,
                        ),
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
                      labelText: "Link do zdjęcia / grafiki",
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

    if (streamedResponse.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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
      title: "Dodaj wydarzenie",
      buttonText: "Dodaj wydarzenie",
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

    if (streamedResponse.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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
      title: "Edytuj wydarzenie",
      buttonText: "Zapisz zmiany",
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
  int year = DateTime.now().year;
  int month = 0;
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
      Uri.parse("${ApiHelper.baseUrl}/public-events?year=$year&month=$month"),
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

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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
      color: Colors.black.withOpacity(0.74),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => goDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              eventImage(event["image_url"], height: 190),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  event["name"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    eventDaysUntil(event).isNotEmpty
                        ? "${eventCityName(event)} • ${eventDateWithDay(event)} • ${eventDaysUntil(event)}"
                        : "${eventCityName(event)} • ${eventDateWithDay(event)}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text("Szczegóły"),
                      onPressed: () => goDetails(event),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.favorite),
                      label: const Text("Zapisz"),
                      onPressed: () => addToMyList(event["id"]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void changePublicYear(int? value) {
    setState(() {
      year = value ?? DateTime.now().year;
    });

    fetchPublicEvents();
  }

  void changePublicMonth(int? value) {
    setState(() {
      month = value ?? 0;
    });

    fetchPublicEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wszystkie wydarzenia"),
      ),
      body: MusicBackground(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public, color: Colors.deepPurpleAccent),
                      SizedBox(width: 8),
                      Text(
                        "Przeglądaj wydarzenia",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: year,
                    decoration: const InputDecoration(
                      labelText: "Rok",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 2024,
                        child: Text("2024"),
                      ),
                      DropdownMenuItem(
                        value: 2025,
                        child: Text("2025"),
                      ),
                      DropdownMenuItem(
                        value: 2026,
                        child: Text("2026"),
                      ),
                      DropdownMenuItem(
                        value: 2027,
                        child: Text("2027"),
                      ),
                      DropdownMenuItem(
                        value: 2028,
                        child: Text("2028"),
                      ),
                    ],
                    onChanged: changePublicYear,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: month,
                    decoration: const InputDecoration(
                      labelText: "Miesiąc",
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    items: monthDropdownItems(),
                    onChanged: changePublicMonth,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? emptyState(
                          icon: Icons.event_busy,
                          title: "Brak wydarzeń",
                          subtitle:
                              "Nie znaleziono wydarzeń dla wybranego roku lub miesiąca.",
                        )
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

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

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
          content: Text("Błąd pobierania wydarzeń: ${response.body}"),
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

      if (response.statusCode == 401) {
        await handleUnauthorized(context);
        return;
      }

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

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wydarzenie zatwierdzone")),
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

  Future<void> rejectEvent(int eventId) async {
    final response = await http.delete(
      Uri.parse("${ApiHelper.baseUrl}/events/$eventId"),
      headers: await ApiHelper.headers(),
    );

    if (!mounted) return;

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wydarzenie odrzucone i usunięte")),
      );

      fetchPendingEvents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd odrzucania wydarzenia: ${response.body}"),
        ),
      );
    }
  }

  Future<void> confirmRejectEvent(Map event) async {
    final eventName = (event["name"] ?? "").toString();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Odrzucić wydarzenie?"),
          content: Text(
            "Czy na pewno chcesz odrzucić i usunąć wydarzenie:\n\n$eventName",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Anuluj"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete),
              label: const Text("Odrzuć"),
            ),
          ],
        );
      },
    );

    if (shouldReject == true) {
      await rejectEvent(event["id"]);
    }
  }

  Widget pendingEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.74),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
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
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text("Miasto: ${eventCityName(event)}"),
            Text("Data: ${eventDateWithDay(event)}"),
            if (eventDaysUntil(event).isNotEmpty)
              Text("Czas do wydarzenia: ${eventDaysUntil(event)}"),
            Text("Miejsce: ${event["club"] ?? ""}"),
            Text("Gatunek muzyki: ${eventMusicTypeName(event)}"),
            const SizedBox(height: 8),
            Text("Źródło: ${eventSourceName(event)}"),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => approveEvent(event["id"]),
                    icon: const Icon(Icons.check),
                    label: const Text("Zatwierdź"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => confirmRejectEvent(event),
                    icon: const Icon(Icons.delete),
                    label: const Text("Odrzuć"),
                  ),
                ),
              ],
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
        title: const Text("Wydarzenia do zatwierdzenia"),
        actions: [
          IconButton(
            tooltip: "Importuj z Ticketmastera",
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
                ? emptyState(
                    icon: Icons.fact_check,
                    title: "Brak wydarzeń do zatwierdzenia",
                    subtitle:
                        "Po imporcie z Ticketmastera nowe wydarzenia pojawią się tutaj.",
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

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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

    if (response.statusCode == 401) {
      if (!mounted) return;
      await handleUnauthorized(context);
      return;
    }

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
      color: Colors.black.withOpacity(0.74),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => goDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              eventImage(event["image_url"], height: 190),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite, color: Colors.redAccent),
                title: Text(
                  event["name"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  eventDaysUntil(event).isNotEmpty
                      ? "${eventCityName(event)} • ${eventDateWithDay(event)} • ${eventDaysUntil(event)}"
                      : "${eventCityName(event)} • ${eventDateWithDay(event)}",
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text("Szczegóły"),
                      onPressed: () => goDetails(event),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text("Usuń"),
                      onPressed: () => removeFromMyList(event["id"]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje wydarzenia"),
      ),
      body: MusicBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : events.isEmpty
                ? emptyState(
                    icon: Icons.favorite_border,
                    title: "Nie masz zapisanych wydarzeń",
                    subtitle:
                        "Dodaj wydarzenie do swojej listy, aby łatwo wrócić do niego później.",
                  )
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