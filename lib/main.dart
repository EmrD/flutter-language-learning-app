// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unused_local_variable

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

const apiKey = ""; //TODO: Put Your API Key Here

final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: apiKey,
  generationConfig: GenerationConfig(
    temperature: 1.85,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 8192,
    responseMimeType: 'text/plain',
  ),
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String first_lang = "";
  String second_lang = "";
  String responseText = "";
  String difficulty = "";
  bool isLoading = false;
  List<Content> historyList = [
    //list of responses with requests
  ];

  late ChatSession chat;

  Future<void> sendGemini() async {
    if (first_lang.isEmpty || second_lang.isEmpty || difficulty.isEmpty) {
      responseText = "Please fill in all fields.";
      showQuestion(context, responseText, "Please fill in all fields.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    final message =
        "Bana $first_lang dilinde $difficulty zorluğunda bir kelime ver ve bunun $second_lang dilindeki karşılığını bir json formatında ver. Json yanıtın her zaman first_lang ve second_lang objeleri olarak olsun. Ancak yalnızca JSON verisini döndür. başka hiçbir şey döndürme. yani { ile başlasın yanıtın her seferinde, json formatında da her zaman first_lang objesinin içinde word kısmında ver; aynı şekilde second_lang içinde de word kısmında ver. ayrıca her zaman farklı kelimeler seçmeye özen göster. bir kelime verdikten sonra bir süre gözükmesin daha değişik kelimeler gelsin. daha önceden verdiğin kelimeleri sana gönderiyorum.";
    final content = Content.text(message);
    chat = model.startChat(history: historyList);

    try {
      final response = await chat.sendMessage(content);
      if (response.text != null) {
        responseText = response.text!;
        showQuestion(context, responseText, message);
      } else {
        responseText = "Response is null.";
        showQuestion(context, responseText, "Response is null.");
      }
    } catch (e) {
      responseText = "Error: $e";
      showQuestion(context, responseText, "Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showQuestion(BuildContext context, String response, String message) {
    if (response.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content:
                const Text("The response is not a valid. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
      return;
    }

    String json_val = response.replaceAll("```", "").replaceAll("json", "");

    try {
      historyList.add(Content.multi([TextPart(message)]));

      historyList.add(Content.model([
        TextPart(response),
      ]));

      Map<String, dynamic> jsonResponse = json.decode(json_val);

      String question_word = jsonResponse['first_lang']['word'].toString();
      String answer_word = jsonResponse['second_lang']['word'].toString();
      String user_answer = "";

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Question"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  question_word[0].toUpperCase() + question_word.substring(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Translate to ${second_lang[0].toUpperCase()}${second_lang.substring(1)}',
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      user_answer = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
              TextButton(
                onPressed: () async {
                  final translate_result = await chat.sendMessage(Content.text(
                      "Senden bir çeviriyi değerlendirmeni istiyorum. $answer_word olması gereken çeviri $user_answer olarak yapılmış. Buna 10 üzerinden bir puan verir misin? Ancak yalnızca ama yalnızca yanıtında sonucu döndür. Örnek olarak 10 üzerinden bir çeviriyi 8 verdiysen bunu yalnızca 8 yazarak ver. Ancak lütfen puan verirken dile dikkat et. yani olması gereken dil almanca ise ve cevap ingilizce gelmiş ise bundan da puanlar kır. birden farklı parametrelere bak ve buna göre adaletli ol. ayrıca almanca gibi dillerde de artikel gibi konulara da dikkat et."));

                  String translate_response =
                      translate_result.text ?? "No response received";

                  Navigator.of(context).pop();

                  showDialog(
                    useSafeArea: true,
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Translate Evaluation"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                translate_response,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            LinearProgressIndicator(
                              value: translate_response.isNotEmpty
                                  ? int.tryParse(translate_response) != null
                                      ? int.tryParse(translate_response)! / 10.0
                                      : 0.0
                                  : 0.0,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.green,
                              backgroundColor: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            const Text("The correct answer was "),
                            Text(answer_word.toUpperCase() , style: const TextStyle(fontWeight: FontWeight.bold),),
                            if (translate_response.isNotEmpty &&
                                int.tryParse(translate_response) != null)
                              const SizedBox(height: 20),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                Colors.red,
                              ),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("Send Answer"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to parse JSON: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Language Learn App" , style: TextStyle(fontWeight: FontWeight.bold),),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                Colors.white,
                Colors.white,
                Colors.blueAccent,
              ])),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Your Main Language',
                      ),
                      onChanged: (value) {
                        setState(() {
                          first_lang = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Language That You Want To Learn',
                      ),
                      onChanged: (value) {
                        setState(() {
                          second_lang = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Difficulty Level (A1, B1...)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          difficulty = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: isLoading ? null : sendGemini,
                    style: ButtonStyle(
                        backgroundColor: isLoading
                            ? MaterialStateProperty.all<Color>(Colors.blueGrey)
                            : MaterialStateProperty.all<Color>(
                                Colors.blueAccent),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)))),
                    child: isLoading
                        ? const Text("Loading...",
                            style: TextStyle(color: Colors.white))
                        : const Text("Submit",
                            style: TextStyle(color: Colors.white)),
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
