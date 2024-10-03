import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mediapipe_genai/mediapipe_genai.dart';
import 'package:intl/intl.dart';
import 'package:klc/klc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FortuneGem',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'FortuneGem'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _birthdayController;
  LlmInferenceEngine? _engine;
  bool _isEngineReady = false;
  String _response = '';
  bool _isLoadingResponse = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _birthdayController = TextEditingController();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    String modelPath = await loadModel();
    bool isGpu = true;
    final options = isGpu
        ? LlmInferenceOptions.gpu(
            modelPath: modelPath,
            sequenceBatchSize: 20,
            maxTokens: 1000,
            temperature: 0,
            topK: 40,
          )
        : LlmInferenceOptions.cpu(
            modelPath: modelPath,
            cacheDir: "",
            maxTokens: 500,
            temperature: 0,
            topK: 40,
          );

    final engine = LlmInferenceEngine(options);

    setState(() {
      _engine = engine;
      _isEngineReady = true;
    });
  }

  void _onSubmit() async {
    if (_birthdayController.text.isEmpty) {
      // Show an error or prompt the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your birthday')),
      );
      return;
    }

    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);

    String korean_birthday = getDateInKorean(_birthdayController.text);
    String korean_today = getDateInKorean(formattedDate);

    String birthday_gapja = getGapja(_birthdayController.text);
    String today_gapja = getGapja(formattedDate);



    // Generate the prompt with the birthday information
    String prompt = "$korean_birthday의 천간지지와 $korean_today의 천간지지를 토대로 해당 날짜의 운세를 10줄 이하로만 알려줘. 다른 설명은 필요 없어\n.$korean_birthday 천간지지: $birthday_gapja\n$korean_today 천간지지: $today_gapja";
    print(prompt);

    // Clear previous response and set loading state
    setState(() {
      _response = '';
      _isLoadingResponse = true;
    });

    List<String> completion = [];

    try {
      // Get the response stream
      final Stream<String> responseStream = _engine!.generateResponse(prompt);

      // Listen to the stream and update _response
      await for (final String responseChunk in responseStream) {
          if (responseChunk.contains("user") && completion.length > 10) {
            break;
          }
          completion.add(responseChunk);
          //print(responseChunk);
      }
    } catch (e) {
      // Handle errors if any
      setState(() {
        _response = 'Error generating response: $e';
      });
    } finally {
      setState(() {
        _response = truncateUselessWords(completion.join(""));
        _isLoadingResponse = false;
        _isSubmitted = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _isEngineReady
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: _birthdayController,
                      decoration: const InputDecoration(
                        labelText: 'Enter your birthday (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    !_isSubmitted ? const SizedBox(height: 16) : const SizedBox.shrink(),
                    !_isSubmitted || _isLoadingResponse ? ElevatedButton(
                      onPressed: _onSubmit,
                      child: const Text('Submit'),
                    ) : const SizedBox.shrink(),
                    const SizedBox(height: 24),
                    _isLoadingResponse
                        ? const CircularProgressIndicator()
                        : Text(
                            _response,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

Future<String> loadModel() async {
  try {
    final docDir = await getApplicationDocumentsDirectory();
    final model = await rootBundle.load('assets/fortunegem.bin');
    final modelBytes = model.buffer.asUint8List(model.offsetInBytes, model.lengthInBytes);
    final filePath = p.join(docDir.path, 'fortunegem.bin');
    await File(filePath).writeAsBytes(modelBytes);
    print('Model saved to $filePath');
    return filePath;
  } catch (e) {
    print('Error loading or saving model: $e');
    return '';
  }
}

String getDateInKorean(date) {
  List<String> dateInList = date.split("-");
  String year = '${int.parse(dateInList[0])}';
  String month = '${int.parse(dateInList[1])}';
  String day = '${int.parse(dateInList[2])}';
    
  String dateInKorean = "${year}년${month}월${day}일";

  return dateInKorean;
}

String getGapja(date) {
  List<String> dateInList = date.split("-");
  setSolarDate(int.parse(dateInList[0]), int.parse(dateInList[1]), int.parse(dateInList[2]));

  return getGapjaString();
}

String truncateUselessWords(String input) {
  String result = "";

  RegExp regExp = RegExp(r"<0x[0-9A-Fa-f]+>");
  input = input.replaceAll(regExp, '');

  int newlineIndex = input.indexOf('오늘은');
  if (newlineIndex != -1) {
    result = input.substring(newlineIndex);
  } else {
    // If no newline is found, return the whole string
    result = input;
  }

  int lastDotIndex = result.lastIndexOf('.');
  if (lastDotIndex != -1) {
    return result.substring(0, lastDotIndex);
  } else {
    // If no dot is found, return the whole string
    return result;
  }
}