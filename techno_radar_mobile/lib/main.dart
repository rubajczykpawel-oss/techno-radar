import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: isLoggedIn ? const EventListPage() : const LoginPage(),
    );
  }
}

/* ================= API HELPER ================= */

class ApiHelper {
  // Backend lokalny — używany podczas pracy na komputerze z uruchomionym FastAPI.
  static const String localBaseUrl = 'http://127.0.0.1:8000';

  // Backend produkcyjny — publiczny backend uruchomiony na Railway.
  static const String prodBaseUrl = 'https://web-production-5db5f.up.railway.app';

  // Aktualnie używany backend.
  // Na produkcji używamy Railway.
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

/* ================= IMAGE HELPER ================= */

Widget eventImage(String? imageUrl, {double height = 160}) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.white38),
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: double.infinity,
          color: Colors.grey[850],
          child: const Center(
            child: Text("Nie udało się wczytać zdjęcia"),
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

        await Future.delayed(const Duration(milliseconds: 850));

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

  Widget loginCharacterImage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Image.asset(
        eyesOpen
            ? "assets/images/login_open.png"
            : "assets/images/login_closed.png",
        key: ValueKey<bool>(eyesOpen),
        height: 170,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.deepPurple),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.35),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              loginCharacterImage(),
              const SizedBox(height: 12),
              const Text(
                "TECHNO RADAR",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                eyesOpen
                    ? "Zalogowano. Witaj w radarze."
                    : "Zaloguj się, żeby wejść do świata eventów.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: email,
                enabled: !isLoggingIn,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                enabled: !isLoggingIn,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Hasło",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onSubmitted: (_) => login(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoggingIn ? null : login,
                  child: isLoggingIn
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Zaloguj"),
                ),
              ),
              TextButton(
                onPressed: isLoggingIn ? null : goRegister,
                child: const Text("Nie masz konta? Zarejestruj się"),
              ),
            ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rejestracja"),
      ),
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/login_closed.png",
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              const Text(
                "Utwórz konto",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: "Nazwa użytkownika",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Hasło",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 22),
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
    return Colors.deepPurple;
  }

  Widget eventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              eventImage(event["image_url"], height: 170),
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
              Text("📅 ${event["date"] ?? ""}"),
              Text("🏢 ${event["club"] ?? ""}"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      color: Colors.black,
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
      body: Column(
        children: [
          if (isAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.deepPurple.withOpacity(0.35),
              child: const Text(
                "Tryb administratora: możesz dodawać, edytować i usuwać eventy.",
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: searchController,
              onChanged: searchEvents,
              decoration: const InputDecoration(
                hintText: "Szukaj po nazwie, mieście, klubie lub typie muzyki",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicType = event["music_type"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Szczegóły eventu"),
      ),
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              eventImage(event["image_url"], height: 250),
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
              detailRow("Miasto", event["city"] ?? "", Icons.location_city),
              detailRow("Data", event["date"] ?? "", Icons.calendar_month),
              detailRow("Klub", event["club"] ?? "", Icons.apartment),
              detailRow("Typ muzyki", musicType, Icons.music_note),
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
    ];

    String? selectedMusicType;

    if (musicType.text.isNotEmpty && musicTypes.contains(musicType.text)) {
      selectedMusicType = musicType.text;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Container(
          width: 430,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: "Nazwa",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: const InputDecoration(
                  labelText: "Miasto",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: date,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Data",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                onTap: () => chooseDate(context),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: club,
                decoration: const InputDecoration(
                  labelText: "Klub",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMusicType,
                decoration: const InputDecoration(
                  labelText: "Typ muzyki",
                  border: OutlineInputBorder(),
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
                  border: OutlineInputBorder(),
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
                    uploadingImage ? "Wysyłanie zdjęcia..." : "Wybierz zdjęcie",
                  ),
                ),
              ),
              const SizedBox(height: 14),
              eventImage(imageUrl.text, height: 120),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zdjęcie wysłane")),
      );
    } else {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Zdjęcie wysłane")),
      );
    } else {
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

  Widget publicEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: eventImage(event["image_url"], height: 150),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: Text(event["name"] ?? ""),
            subtitle: Text("${event["city"] ?? ""} • ${event["date"] ?? ""}"),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Dodaj"),
              onPressed: () => addToMyList(event["id"]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publiczne eventy"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              value: year,
              decoration: const InputDecoration(
                labelText: "Wybierz rok",
                border: OutlineInputBorder(),
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

  Widget myEventCard(Map event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: eventImage(event["image_url"], height: 150),
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text(event["name"] ?? ""),
            subtitle: Text("${event["city"] ?? ""} • ${event["date"] ?? ""}"),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text("Usuń"),
              onPressed: () => removeFromMyList(event["id"]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moje eventy"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? const Center(child: Text("Brak eventów na Twojej liście"))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (_, index) {
                    return myEventCard(events[index]);
                  },
                ),
    );
  }
}