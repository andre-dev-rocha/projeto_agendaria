// lib/app/presentation/features/client/chatbot/chatbot_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/dialogflow/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();

  DialogflowApi? _dialogflowApi;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeDialogflow();
  }

  Future<void> _initializeDialogflow() async {
    final credentialsJson = await rootBundle.loadString('assets/dialogflow_credentials.json');
    var scopes = [DialogflowApi.cloudPlatformScope];
    var client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(credentialsJson),
      scopes,
    );

    setState(() {
      _dialogflowApi = DialogflowApi(client);
      _sessionId = FirebaseAuth.instance.currentUser?.uid ?? 'fallback-session-id';
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty || _dialogflowApi == null) return;
    _textController.clear();

    setState(() {
      _messages.insert(0, {"text": text, "isUser": true});
    });

    try {
      final textInput = GoogleCloudDialogflowV2TextInput(
        text: text,
        languageCode: "pt-BR", // Garante que o Dialogflow entenda português
      );

      final queryInput = GoogleCloudDialogflowV2QueryInput(text: textInput);

      final request = GoogleCloudDialogflowV2DetectIntentRequest(queryInput: queryInput);

      final sessionPath = 'projects/agendaria-aa948/agent/sessions/$_sessionId'; // Usando o projeto correto

      final response = await _dialogflowApi!.projects.agent.sessions.detectIntent(
        request,
        sessionPath,
      );
      
      final fulfillmentText = response.queryResult?.fulfillmentText;

      if (fulfillmentText != null && fulfillmentText.isNotEmpty) {
        setState(() {
          _messages.insert(0, {"text": fulfillmentText, "isUser": false});
        });
      }
    } catch (e) {
      print('Erro ao chamar a API do Dialogflow: $e');
      setState(() {
        _messages.insert(0, {
          "text": "Desculpe, estou com problemas para me conectar. Tente novamente mais tarde.",
          "isUser": false
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Atendimento')),
      body: _dialogflowApi == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ListTile(
                        title: Align(
                          alignment: msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: msg['isUser'] ? Colors.blue[300] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(msg['text'], style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor),
                  child: _buildTextComposer(),
                ),
              ],
            ),
    );
  }

  // Widget do campo de texto - sem filtros
  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                // O TextField está limpo, sem a propriedade 'inputFormatters'
                decoration: const InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}