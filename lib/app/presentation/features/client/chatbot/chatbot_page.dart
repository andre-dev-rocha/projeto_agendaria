// lib/app/presentation/features/client/chatbot/chatbot_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/dialogflow/v2.dart'; // Importa a API do Dialogflow v2
import 'package:googleapis_auth/auth_io.dart'; // Importa o auxiliar de autenticação
import 'package:firebase_auth/firebase_auth.dart'; // Para pegar o ID do usuário
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

  // A inicialização agora cria um cliente HTTP autenticado
  Future<void> _initializeDialogflow() async {
    // 1. Carrega o conteúdo do arquivo JSON de credenciais
    final credentialsJson = await rootBundle.loadString('assets/dialogflow_credentials.json');

    // 2. Define o escopo da API que queremos acessar
    var scopes = [DialogflowApi.cloudPlatformScope];

    // 3. Cria um cliente autenticado
    var client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(credentialsJson),
      scopes,
    );

    setState(() {
      // 4. Cria a instância da API do Dialogflow com o cliente autenticado
      _dialogflowApi = DialogflowApi(client);
      // 5. Cria uma session ID única para esta conversa, usando o ID do usuário logado
      _sessionId = FirebaseAuth.instance.currentUser?.uid ?? 'fallback-session-id';
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty || _dialogflowApi == null) return;
    _textController.clear();

    // Adiciona a mensagem do usuário à lista da UI
    setState(() {
      _messages.insert(0, {"text": text, "isUser": true});
    });
    
    // Constrói o corpo da requisição para a API
    var queryInput = GoogleCloudDialogflowV2QueryInput.fromJson({
      "text": {
        "text": text,
        "languageCode": "pt-BR",
      }
    });

    var request = GoogleCloudDialogflowV2DetectIntentRequest.fromJson({
      "queryInput": queryInput,
    });
    
    try {
      // Faz a chamada para a API
      // A estrutura é: projects/{project-id}/agent/sessions/{session-id}
      var response = await _dialogflowApi!.projects.agent.sessions.detectIntent(
        request,
        'projects/agendaria-aa948/agent/sessions/$_sessionId', // IMPORTANTE: Substitua 'agendaria-4d70b' pelo ID do seu projeto no Firebase/Google Cloud!
      );
      
      // Extrai o texto da resposta do bot
      String? fulfillmentText = response.queryResult?.fulfillmentText;

      if (fulfillmentText != null && fulfillmentText.isNotEmpty) {
        setState(() {
          _messages.insert(0, {"text": fulfillmentText, "isUser": false});
        });
      }
    } catch (e) {
      print('Erro ao chamar a API do Dialogflow: $e');
      setState(() {
        _messages.insert(0, {"text": "Desculpe, estou com problemas para me conectar. Tente novamente mais tarde.", "isUser": false});
      });
    }
  }

  // O resto da UI permanece o mesmo
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