import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_helper.dart';
import '../helpers/event_helpers.dart';
import '../widgets/event_form.dart';

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

    if (!mounted) return;

    setState(() {
      uploadingImage = false;
    });

    if (streamedResponse.statusCode == 401) {
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

    if (!mounted) return;

    if (response.statusCode == 401) {
      await handleUnauthorized(context);
      return;
    }

    if (response.statusCode == 200) {
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