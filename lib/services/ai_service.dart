import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AIService {
  // ==========================================================
  // ⚠️ API Key — run කරන්න:
  // flutter run --dart-define=GEMINI_API_KEY=AIzaSy...
  // ==========================================================
  static const String _apiKey =
  String.fromEnvironment('GEMINI_API_KEY');

  static const String _model = 'gemini-2.5-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ==========================================================
  // Generate Career Recommendation
  // ==========================================================

  Future<Map<String, dynamic>> getCareerRecommendation({
    required String interests,
    required String skills,
    required String education,
    required String careerGoal,
  }) async {
    final prompt = '''
You are an AI career advisor for a mobile application called CareerWise.

Analyze the user's education, skills, interests, and career goals.

USER INFORMATION

Education:
$education

Skills:
$skills

Interests:
$interests

Career Goal:
$careerGoal

Provide a personalized career analysis.

Return ONLY valid JSON.

Do not use markdown.
Do not use code fences.
Do not add any explanation outside the JSON.

Use exactly this structure:

{
  "careers": [
    {
      "title": "Career name",
      "whySuitable": "Why this career is suitable",
      "skillsToDevelop": ["Skill 1", "Skill 2", "Skill 3"],
      "learningAreas": ["Learning area 1", "Learning area 2"],
      "technologies": ["Technology 1", "Technology 2"]
    }
  ],
  "strengths": ["Strength 1", "Strength 2"],
  "actionPlan": ["Action 1", "Action 2", "Action 3"]
}

RULES:

- Provide exactly 3 career recommendations.
- Career titles must be short and searchable job titles.
- Base the recommendations on the user's actual education, skills, interests, and career goal.
- Do not give generic recommendations.
- Make the recommendations practical for a university student or early-career person.
- Give different career paths when appropriate.
- Keep explanations concise.
- skillsToDevelop must contain practical skills.
- learningAreas must contain useful learning topics.
- technologies must contain relevant technologies, tools, or platforms.
- strengths must be based on the user's provided information.
- actionPlan must contain realistic next steps.
''';

    // ✅ API Key check
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is missing. '
            'Run with --dart-define=GEMINI_API_KEY=AIzaSy...',
      );
    }

    final url = Uri.parse(
      '$_baseUrl/$_model:generateContent?key=$_apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.7,
      },
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // ========================================================
      // HTTP error handling
      // ========================================================

      if (response.statusCode == 429) {
        throw Exception(
          'AI quota has been reached. Please try again later.',
        );
      }

      if (response.statusCode != 200) {
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(response.body);
          errorMessage =
              errJson['error']?['message']?.toString() ?? errorMessage;
        } catch (_) {}
        throw Exception('Gemini API error: $errorMessage');
      }

      // ========================================================
      // Parse Gemini response
      // ========================================================

      final Map<String, dynamic> data = jsonDecode(response.body);

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini returned no candidates.');
      }

      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      final String? text = parts.first['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      // ========================================================
      // Clean markdown fences (safety)
      // ========================================================

      String cleanText = text.trim();

      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7).trim();
      }
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3).trim();
      }
      if (cleanText.endsWith('```')) {
        cleanText =
            cleanText.substring(0, cleanText.length - 3).trim();
      }

      // ========================================================
      // Decode + validate
      // ========================================================

      final decoded = jsonDecode(cleanText);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format from Gemini.');
      }

      if (!decoded.containsKey('careers')) {
        throw Exception(
          'AI response does not contain career recommendations.',
        );
      }
      if (!decoded.containsKey('strengths')) {
        throw Exception('AI response does not contain strengths.');
      }
      if (!decoded.containsKey('actionPlan')) {
        throw Exception('AI response does not contain an action plan.');
      }

      final careers = decoded['careers'];
      if (careers is! List || careers.length != 3) {
        throw Exception(
          'AI response must contain exactly 3 career recommendations.',
        );
      }

      return decoded;
    } on FormatException {
      throw Exception(
        'Gemini returned invalid JSON. Please try again.',
      );
    } catch (e) {
      throw Exception(
        'Failed to generate career recommendation: $e',
      );
    }
  }

  // ==========================================================
  // Save Career Recommendation
  // ==========================================================

  Future<void> saveCareerRecommendation({
    required String userId,
    required String education,
    required String skills,
    required String interests,
    required String careerGoal,
    required String recommendation,
  }) async {
    await FirebaseFirestore.instance
        .collection('career_recommendations')
        .add({
      'userId': userId,
      'education': education,
      'skills': skills,
      'interests': interests,
      'careerGoal': careerGoal,
      'recommendation': recommendation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}