import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();
  GenerativeModel? _model;
  ChatSession? _chat;

  void _initModel() {
    if (_model != null) return;
    final apiKey = dotenv.env['ANVIL_API_KEY'] ?? '';
    final model_id = dotenv.env['ANVIL_MODEL'] ?? '';
    if (apiKey.isEmpty) {
      print('Error: ANVIL_API_KEY is missing in .env');
      return;
    }
    const systemPrompt =
        "You are StrayCare AI Vet Bot. My intelligence is powered by Anvil 1 Beta, a 7-billion parameter veterinary LLM. "
        "Your role is STRICTLY limited to animal care, rescue, veterinary triage, and pet health. "
        "Guardrails: 1. If a user asks about anything not related to animals/veterinary (e.g. coding, math, general chat, creative writing), politely refuse and say 'I can only assist with animal care and rescue queries.' "
        "2. Do NOT introduce yourself or your model name in every message. Only introduce yourself if the user explicitly asks 'Who are you?' or 'What are you?'. "
        "3. Be conversational but concise. "
        "4. Always advise safety first. If a situation seems life-threatening, tell them to go to a vet IMMEDIATELY.";
    final isGemma = model_id.toLowerCase().contains('gemma');

    _model = GenerativeModel(
      model: model_id,
      apiKey: apiKey,
      systemInstruction: isGemma ? null : Content.system(systemPrompt),
    );
  }

  Future<String> getAnvilResponse(String userMessage) async {
    try {
      _initModel();
      if (_model == null)
        return "I am having trouble connecting to the Anvil servers. Try again later.";

      if (_chat == null) {
        _chat = _model!.startChat();
        // For Gemma/Models without system instruction support, inject it as first message
        final model_id = dotenv.env['ANVIL_MODEL'] ?? '';
        if (model_id.toLowerCase().contains('gemma')) {
          const systemPrompt =
              "You are StrayCare AI Vet Bot. My intelligence is powered by Anvil 1 Beta, a 7-billion parameter veterinary LLM. "
              "Your role is STRICTLY limited to animal care, rescue, veterinary triage, and pet health. "
              "Guardrails: 1. If a user asks about anything not related to animals/veterinary (e.g. coding, math, general chat, creative writing), politely refuse and say 'I can only assist with animal care and rescue queries.' "
              "2. Do NOT introduce yourself or your model name in every message. Only introduce yourself if the user explicitly asks 'Who are you?' or 'What are you?'. "
              "3. Be conversational but concise. "
              "4. Always advise safety first. If a situation seems life-threatening, tell them to go to a vet IMMEDIATELY.";
          // We can't easily prepend silently in startChat without sending it.
          // Best workaround: Prepend to user's first message if history is empty.
          userMessage = systemPrompt + "\n\nUser: " + userMessage;
        }
      }

      final response = await _chat!.sendMessage(Content.text(userMessage));
      return response.text ?? "No response from AI.";
    } catch (e) {
      print('AI Service Error: ' + e.toString());
      return "Error: " + e.toString();
    }
  }

  Future<String> getRescuePostAdvice(String postContent) async {
    try {
      _initModel();
      if (_model == null) return "NO_RESPONSE";
      final prompt =
          """Analyze this pet rescue post content: "$postContent". Determine if this is a genuine request for help regarding a stray animal, injury, or medical situation. Rules: 1. If the post is irrelevant, spam, or just a cute photo without a problem, return exactly "NO_RESPONSE". 2. If it is a rescue/medical situation, provide CONCISE, actionable advice (e.g., first aid, keep warm, do not feed if X, go to vet). 3. Do NOT ask questions. The user might not reply. Give best-guess advice based on the text. 4. Keep it under 3 sentences. 5. Start with "AI Vet Bot Suggestion: "
Response: """;
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final text = response.text?.trim() ?? "NO_RESPONSE";
      if (text.contains("NO_RESPONSE")) return "NO_RESPONSE";
      return text;
    } catch (e) {
      print('AI Rescue Advice Error: ' + e.toString());
      return "NO_RESPONSE";
    }
  }
}
