import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' if (dart.library.html) 'dart:html';

void main() {
  runApp(const SmartAgriApp());
}

class SmartAgriApp extends StatelessWidget {
  const SmartAgriApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAgri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5B4FFF),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Georgia',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScannerScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.eco,
                          size: 90, color: Colors.green);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'MADE IN INDIA',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SmartAgri',
              style: TextStyle(
                fontSize: 32,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'WE FOCUS ON FARMER GROWTH',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  List<String> _labels = [];
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    if (kIsWeb) {
      // TFLite is not supported on web
      print('Running on web - TFLite model not available');
      return;
    }
    try {
      String? res = await Tflite.loadModel(
        model: "assets/crop_disease_model.tflite",
        labels: "assets/labels.txt",
      );
      print('Model loaded successfully: $res');
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
      _showSnackBar('Model not found. Please add model to assets/',
          isError: true);
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels =
          labelData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      print('Error loading labels: $e');
      _labels = [
        'Apple Apple scab',
        'Apple Black rot',
        'Cedar apple rust',
        'Apple healthy',
        'Corn Cercospora leaf spot',
        'Potato Early blight'
      ];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  Future<void> _classifyImage() async {
    if (kIsWeb) {
      _showWebDemoDialog();
      return;
    }

    if (_selectedImage == null) {
      _showSnackBar('Please select an image first', isError: true);
      return;
    }

    if (!_modelLoaded) {
      _showSnackBar('Model not loaded. Please restart the app.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var recognitions = await Tflite.runModelOnImage(
        path: _selectedImage!.path,
        numResults: 6,
        threshold: 0.5,
        imageMean: 0.0,
        imageStd: 255.0,
      );

      setState(() {
        _isLoading = false;
      });

      if (recognitions != null && recognitions.isNotEmpty) {
        String disease = recognitions[0]['label'];
        double confidence = (recognitions[0]['confidence'] * 100);

        // Only accept predictions with confidence >= 90%
        if (confidence < 90.0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvalidImageScreen(image: _selectedImage!),
            ),
          );
          return;
        }

        Map<String, String> diseaseInfo = _getDiseaseInfo(disease);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              diseaseName: disease,
              confidence: confidence,
              image: _selectedImage!,
              description: diseaseInfo['description']!,
              symptoms: diseaseInfo['symptoms']!,
              treatment: diseaseInfo['treatment']!,
            ),
          ),
        );
      } else {
        _showSnackBar('Could not classify image', isError: true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Classification error: $e', isError: true);
    }
  }

  Map<String, String> _getDiseaseInfo(String disease) {
    String diseaseLower = disease.toLowerCase();

    if (diseaseLower.contains('invalid image')) {
      return {
        'description':
            'The uploaded image is not suitable for disease detection. Please upload a clear crop or leaf image.',
        'symptoms':
            'This could be a person, object, or blurry image that the model cannot classify as a plant or crop.',
        'treatment':
            'Upload a clear image of a crop leaf or plant affected area. Ensure proper lighting and focus for accurate detection.',
      };
    } else if (diseaseLower.contains('apple scab')) {
      return {
        'description':
            'Apple scab is a fungal disease caused by Venturia inaequalis that affects apple trees, causing serious economic losses in commercial orchards.',
        'symptoms':
            'Olive-green to brown spots on leaves and fruit. Velvety or fuzzy appearance on lesions. Premature leaf drop and fruit deformation.',
        'treatment':
            'Remove fallen leaves and infected fruit. Apply fungicides during wet periods. Plant resistant varieties. Prune for better air circulation.',
      };
    } else if (diseaseLower.contains('black rot')) {
      return {
        'description':
            'Black rot is a fungal disease caused by Botryosphaeria obtusa affecting apples, causing leaf spots, fruit rot, and limb cankers.',
        'symptoms':
            'Brown leaf spots with purple borders. Fruit develops brown rotted areas with concentric rings. Black pimple-like structures on infected tissue.',
        'treatment':
            'Remove infected fruit and prune dead branches. Apply copper-based fungicides. Practice good sanitation by removing mummified fruit.',
      };
    } else if (diseaseLower.contains('cedar apple rust') ||
        diseaseLower.contains('cedar rust')) {
      return {
        'description':
            'Cedar apple rust is caused by Gymnosporangium juniperi-virginianae, a fungal pathogen that requires both apple and cedar trees to complete its life cycle.',
        'symptoms':
            'Bright orange-yellow spots on upper leaf surfaces. Horn-like projections on fruit. Premature leaf and fruit drop.',
        'treatment':
            'Remove nearby cedar trees if possible. Apply protective fungicides in spring. Plant resistant apple varieties. Rake and destroy fallen leaves.',
      };
    } else if (diseaseLower.contains('apple') &&
        diseaseLower.contains('healthy')) {
      return {
        'description':
            'Your apple tree appears healthy with no visible signs of disease. Continue proper care and monitoring.',
        'symptoms':
            'Green, vibrant foliage. Normal fruit development. No discoloration, spots, or lesions on leaves or fruit.',
        'treatment':
            'Maintain regular watering and fertilization. Monitor for early signs of disease. Prune for good air circulation. Apply preventive sprays if needed.',
      };
    } else if (diseaseLower.contains('cercospora') ||
        diseaseLower.contains('gray leaf spot')) {
      return {
        'description':
            'Gray leaf spot is a fungal disease caused by Cercospora zeae-maydis, one of the most damaging foliar diseases of corn worldwide.',
        'symptoms':
            'Small rectangular gray to brown lesions parallel to leaf veins. Lesions may merge causing entire leaves to die. Lower leaves affected first.',
        'treatment':
            'Plant resistant hybrids. Practice crop rotation with non-host crops. Apply foliar fungicides when symptoms first appear. Tillage to bury infected residue.',
      };
    } else if (diseaseLower.contains('early blight')) {
      return {
        'description':
            'Early blight is a common fungal disease of potatoes caused by Alternaria solani, resulting in significant yield losses if not managed properly.',
        'symptoms':
            'Dark brown spots with concentric rings (target pattern) on older leaves. Yellowing around lesions. Stem lesions near soil line. Tuber infections appear as dark, sunken spots.',
        'treatment':
            'Remove and destroy infected leaves. Apply copper-based or chlorothalonil fungicides. Practice 2-3 year crop rotation. Use certified disease-free seed potatoes. Mulch to prevent soil splash.',
      };
    } else if (diseaseLower.contains('late blight')) {
      return {
        'description':
            'Late blight is a devastating disease caused by Phytophthora infestans affecting potatoes and tomatoes.',
        'symptoms':
            'Water-soaked spots on leaves turning brown. White fuzzy growth on leaf undersides. Rapid plant collapse.',
        'treatment':
            'Apply fungicides immediately. Remove infected plants. Avoid overhead irrigation. Plant resistant varieties.',
      };
    } else if (diseaseLower.contains('healthy')) {
      return {
        'description':
            'Your crop appears healthy with no visible signs of disease. Continue good agricultural practices.',
        'symptoms':
            'Green, vibrant foliage. Normal growth patterns. No discoloration or lesions.',
        'treatment':
            'Maintain regular watering and fertilization. Monitor for pests. Ensure proper spacing for air circulation.',
      };
    }

    return {
      'description':
          'Disease detected. Please consult with an agricultural expert for detailed diagnosis.',
      'symptoms':
          'Visual inspection recommended for accurate symptom identification.',
      'treatment':
          'Consult local agricultural extension services for appropriate treatment recommendations.',
    };
  }

  void _showWebDemoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF5B4FFF)),
            SizedBox(width: 8),
            Text('Web Demo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a UI demo of SmartAgri.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'The AI-powered crop disease detection requires the TensorFlow Lite engine which only runs on mobile devices.',
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF5B4FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: Color(0xFF5B4FFF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download the Android/iOS app for full functionality.',
                      style: TextStyle(color: Color(0xFF5B4FFF), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: Color(0xFF5B4FFF))),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.eco, color: Colors.green);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SmartAgri',
                    style: TextStyle(
                      fontSize: 30,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_selectedImage != null)
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      )
                    else
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -2,
                              left: -2,
                              child: _buildCornerBracket(topLeft: true),
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: _buildCornerBracket(topRight: true),
                            ),
                            Positioned(
                              bottom: -2,
                              left: -2,
                              child: _buildCornerBracket(bottomLeft: true),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: _buildCornerBracket(bottomRight: true),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    Text(
                      _selectedImage == null
                          ? 'SCAN YOUR\nCROPS'
                          : 'IMAGE SELECTED\nREADY TO ANALYZE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        letterSpacing: 2,
                        color:
                            _selectedImage == null ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF5B4FFF)),
                    ),
                    SizedBox(height: 16),
                    Text('Analyzing crop disease...'),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B4FFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B4FFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _classifyImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4FFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ANALYZE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? const BorderSide(color: Colors.black, width: 6)
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? const BorderSide(color: Colors.black, width: 6)
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? const BorderSide(color: Colors.black, width: 6)
              : BorderSide.none,
          right: topRight || bottomRight
              ? const BorderSide(color: Colors.black, width: 6)
              : BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}

class ResultScreen extends StatefulWidget {
  final String diseaseName;
  final double confidence;
  final File image;
  final String description;
  final String symptoms;
  final String treatment;

  const ResultScreen({
    Key? key,
    required this.diseaseName,
    required this.confidence,
    required this.image,
    required this.description,
    required this.symptoms,
    required this.treatment,
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speakDiseaseInfo() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      setState(() {
        _isSpeaking = true;
      });

      String textToSpeak = '''
        Disease detected: ${widget.diseaseName}.
        Confidence: ${widget.confidence.toStringAsFixed(1)} percent.
        Description: ${widget.description}
        Symptoms: ${widget.symptoms}
        Treatment: ${widget.treatment}
      ''';

      await _flutterTts.speak(textToSpeak);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isHealthy = widget.diseaseName.toLowerCase().contains('healthy');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.diseaseName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHealthy ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            isHealthy ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.image,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHealthy ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isHealthy ? Icons.check_circle : Icons.warning,
                      color: isHealthy ? Colors.green[700] : Colors.orange[700],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isHealthy
                            ? 'Your crop is healthy!'
                            : 'Disease detected - Action required',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isHealthy
                              ? Colors.green[900]
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                  'Description', widget.description, Icons.info_outline),
              const SizedBox(height: 20),
              _buildSection(
                  'Symptoms', widget.symptoms, Icons.medical_services_outlined),
              const SizedBox(height: 20),
              _buildSection(
                  'Treatment', widget.treatment, Icons.healing_outlined),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4FFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4FFF).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.stop : Icons.volume_up,
                      size: 32,
                      color: Colors.white,
                    ),
                    onPressed: _speakDiseaseInfo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF5B4FFF)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class InvalidImageScreen extends StatelessWidget {
  final File image;

  const InvalidImageScreen({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invalid Image',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Invalid Image',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The uploaded image is not suitable for disease detection. This could be a person, object, or unclear image.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'Please upload a clear image of a crop leaf or plant affected area for accurate detection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Re-upload Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
