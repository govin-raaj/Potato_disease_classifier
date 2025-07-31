import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PotatoPredictor(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
    );
  }
}

class PotatoPredictor extends StatefulWidget {
  @override
  _PotatoPredictorState createState() => _PotatoPredictorState();
}

class _PotatoPredictorState extends State<PotatoPredictor> {
  File? _image;
  String _result = "";
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = "";
      });
      _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _loading = true);

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("http://192.168.1.9:7777/predict"), 
    );

    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      setState(() {
        _result =
            "Class: ${data['class']}\nConfidence: ${(data['confidence'] * 100).toStringAsFixed(2)}%";
      });
    } else {
      setState(() {
        _result = "Error: Server responded with status ${response.statusCode}";
      });
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.energy_savings_leaf),
          title: const Text('Potato Leaf Classifier'),
          backgroundColor: Colors.green,
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  "https://imgs.search.brave.com/oiSyer_oYZE120QGj74MDRBO6a1_ozuOcDiZAjivaaA/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMzkv/NjI3LzI0Mi9zbWFs/bC9haS1nZW5lcmF0/ZWQtb3JnYW5pYy1m/cmVzaC1wb3RhdG8t/cGxhbnRzLWZpZWxk/LWNsb3NlLXVwLXZp/ZXctcGhvdG8uanBn"),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : null),
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator()
                      : Text(
                          _result,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            backgroundColor: Colors.black54,
                          ),
                        ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _pickImage,
                    child: const Text('Pick Image',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
