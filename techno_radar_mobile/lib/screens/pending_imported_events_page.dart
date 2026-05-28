import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_helper.dart';
import '../helpers/event_helpers.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_image.dart';
import '../widgets/music_background.dart';

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
      color: Colors.black.withValues(alpha: 0.74),
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