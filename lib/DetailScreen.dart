import 'dart:io';
import 'dart:async';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({Key? key}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String selectedItem = '';
  late File pickedImage;
  var imageFile;
  var result = '';

  bool isImageLoaded = false;
  bool isFaceDetected = false;

  List<Rect> rect = [];

  getImageFromGallery() async {
    var tempStore = await ImagePicker().getImage(source: ImageSource.gallery);

    imageFile = await tempStore?.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);
    setState(() {
      pickedImage = File(tempStore!.path);
      isImageLoaded = true;
      isFaceDetected = true;

      imageFile = imageFile;
    });
  }

  readTextFromAnImage() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(myImage);

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            result = result + ' ' + word.text;
          });

          // print(word.text);
        }
      }
    }
  }

  decodeBarcode() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector();
    List barCodes = await barcodeDetector.detectInImage(myImage);
    for (Barcode readableCode in barCodes) {
      setState(() {
        result = readableCode.displayValue;
      });
      // print(readableCode.displayValue);
    }
  }

  Future labelsRead() async {
    result = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
    List labels = await labeler.processImage(myImage);
    for (ImageLabel label in labels) {
      final String text = label.text;
      final double confidence = label.confidence;
      // print('$text    ---    $confidence');
      setState(() {
        result = result + ' ' + '$text      $confidence' + '\n';
      });
    }
  }

  Future detectFace() async {
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
    FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(myImage);
    if (rect.length > 0) {
      rect = [];
    }
    for (Face face in faces) {
      rect.add(face.boundingBox);
    }
  }

  void detectMlFeatures(String selectedFeature) {
    switch (selectedFeature) {
      case 'Text Scanner':
        readTextFromAnImage();
        break;
      case 'Barcode Scanner':
        decodeBarcode();
        break;
      case 'Label Scanner':
        labelsRead();
        break;
      case 'Face Detection':
        detectFace();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedItem = ModalRoute.of(context)!.settings.arguments.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem),
        actions: [
          RaisedButton(
            onPressed: getImageFromGallery,
            color: Colors.blue,
            child: const Icon(
              Icons.add_a_photo,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 100,
            ),
            isImageLoaded && !isFaceDetected
                ? Center(
                    child: Container(
                      height: 250.0,
                      width: 250.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: FileImage(pickedImage), fit: BoxFit.cover),
                      ),
                    ),
                  )
                : isImageLoaded && isFaceDetected
                    ? Center(
                        child: Container(
                          child: FittedBox(
                            child: SizedBox(
                              width: imageFile.width.toDouble(),
                              height: imageFile.height.toDouble(),
                              child: CustomPaint(
                                painter: FacePainter(
                                    rect: rect, imageFile: imageFile),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(),
            const SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(result),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            detectMlFeatures(selectedItem);
          },
          child: const Icon(
            Icons.check,
          )),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Rect> rect;
  var imageFile;

  FacePainter({required this.rect, required this.imageFile});
  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }
    for (Rect rectangle in rect) {
      canvas.drawRect(
        rectangle,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }
}
