import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_helper.dart';
import '../constants/app_assets.dart';
import '../helpers/dropdown_items.dart';
import '../helpers/event_helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_image.dart';
import '../widgets/music_background.dart';
import '../widgets/neon_tag.dart';
import 'add_event_page.dart';
import 'edit_event_page.dart';
import 'event_details_page.dart';
import 'login_page.dart';
import 'my_events_page.dart';
import 'pending_imported_events_page.dart';
import 'public_events_page.dart';

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

    if (!mounted) return;

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

    if (!mounted) return;

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    final data = jsonDecode(response.body);

    if (!mounted) return;

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

    if (!mounted) return;

    if (response.statusCode == 401) {
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

    if (!mounted) return;

    fetchEvents();
  }

  void goEdit(Map event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEventPage(event: event)),
    );

    if (!mounted) return;

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

            if (!mounted) return;

            fetchEvents();
          },
        ),
      ),
    );

    if (!mounted) return;

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

    if (!mounted) return;

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
        border: Border.all(color: accentColor.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.black.withValues(alpha: 0.76),
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
                    color: Colors.white.withValues(alpha: 0.78),
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
      color: Colors.black.withValues(alpha: 0.55),
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
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.12),
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
                    color: Colors.white.withValues(alpha: 0.74),
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
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
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
                    initialValue: selectedCity,
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
                    initialValue: selectedMusicType,
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
                    initialValue: selectedYear,
                    decoration: const InputDecoration(
                      labelText: "Rok",
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: yearDropdownItems(),
                    onChanged: changeYear,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
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