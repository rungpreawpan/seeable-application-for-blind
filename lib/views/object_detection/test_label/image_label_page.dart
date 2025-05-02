import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

class ImageLabelingExample extends StatefulWidget {
  const ImageLabelingExample({super.key});

  @override
  _ImageLabelingExampleState createState() => _ImageLabelingExampleState();
}

class _ImageLabelingExampleState extends State<ImageLabelingExample> {
  File? _image;
  List<ImageLabel> _labels = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final inputImage = InputImage.fromFile(imageFile);
      final imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.7));
      final labels = await imageLabeler.processImage(inputImage);

      setState(() {
        _image = imageFile;
        _labels = labels;
      });

      imageLabeler.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Labeling')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              if (_image != null) Image.file(_image!),
              if (_labels.isNotEmpty)
                ..._labels.map((label) => ListTile(
                  title: Text(label.label),
                  subtitle: Text('Confidence: ${label.confidence.toStringAsFixed(2)}'),
                )),
            ],
          ),
        ),
      ),
    );
  }
}
