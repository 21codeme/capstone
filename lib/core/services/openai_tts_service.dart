import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for OpenAI Text-to-Speech API
/// Provides natural, human-like voices
class OpenAITtsService {
  static const String _apiUrl = 'https://api.openai.com/v1/audio/speech';
  static const String _prefsKeyApiKey = 'openai_api_key';
  static const String _prefsKeyVoice = 'openai_tts_voice';
  static const String _prefsKeyModel = 'openai_tts_model';
  
  // Available OpenAI TTS voices (natural-sounding)
  static const List<String> availableVoices = [
    'alloy',    // Neutral, balanced voice
    'ash',      // Calm, soothing voice
    'ballad',   // Warm, expressive voice
    'coral',    // Bright, energetic voice
    'echo',     // Clear, confident voice
    'fable',    // Storytelling voice
    'onyx',     // Deep, authoritative voice
    'nova',     // Young, vibrant voice
    'sage',     // Wise, thoughtful voice
    'shimmer',  // Soft, gentle voice
    'verse',    // Poetic, melodic voice
  ];
  
  // Available models
  static const List<String> availableModels = [
    'tts-1',           // Standard quality, faster
    'tts-1-hd',        // High quality, slower
    'gpt-4o-mini-tts', // Latest model with best quality
  ];
  
  String? _apiKey;
  String _selectedVoice = 'nova'; // Default: natural, vibrant voice
  String _selectedModel = 'gpt-4o-mini-tts'; // Default: best quality
  AudioPlayer? _audioPlayer;
  
  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    await _loadPreferences();
    _audioPlayer = AudioPlayer();
  }
  
  /// Set OpenAI API key
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyApiKey, apiKey);
  }
  
  /// Get current API key
  String? getApiKey() => _apiKey;
  
  /// Set voice preference
  Future<void> setVoice(String voice) async {
    if (availableVoices.contains(voice)) {
      _selectedVoice = voice;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyVoice, voice);
    }
  }
  
  /// Get current voice
  String getVoice() => _selectedVoice;
  
  /// Set model preference
  Future<void> setModel(String model) async {
    if (availableModels.contains(model)) {
      _selectedModel = model;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyModel, model);
    }
  }
  
  /// Get current model
  String getModel() => _selectedModel;
  
  /// Check if API key is set
  bool isConfigured() => _apiKey != null && _apiKey!.isNotEmpty;
  
  /// Generate speech from text and return audio file path
  Future<String> generateSpeech(String text, {
    String? voice,
    String? model,
    String format = 'mp3',
  }) async {
    if (!isConfigured()) {
      throw Exception('OpenAI API key is not set. Please configure it first.');
    }
    
    if (text.isEmpty) {
      throw Exception('Text cannot be empty');
    }
    
    // Limit text length (OpenAI limit is 4096 characters)
    if (text.length > 4096) {
      text = text.substring(0, 4096);
      print('⚠️ Text truncated to 4096 characters');
    }
    
    final voiceToUse = voice ?? _selectedVoice;
    final modelToUse = model ?? _selectedModel;
    
    print('🔊 OpenAI TTS: Generating speech...');
    print('🔊 Voice: $voiceToUse, Model: $modelToUse, Text length: ${text.length}');
    
    try {
      // Make API request
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': modelToUse,
          'input': text,
          'voice': voiceToUse,
          'response_format': format,
        }),
      );
      
      if (response.statusCode == 200) {
        // Save audio file to temporary directory
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final audioFile = File('${tempDir.path}/openai_tts_$timestamp.$format');
        await audioFile.writeAsBytes(response.bodyBytes);
        
        print('✅ OpenAI TTS: Audio generated successfully (${audioFile.path})');
        return audioFile.path;
      } else {
        final errorBody = response.body;
        print('❌ OpenAI TTS Error: ${response.statusCode} - $errorBody');
        throw Exception('OpenAI TTS API error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ OpenAI TTS Error: $e');
      rethrow;
    }
  }
  
  /// Generate speech and play it directly
  Future<void> speak(String text, {
    String? voice,
    String? model,
    double volume = 1.0,
    double speed = 1.0,
  }) async {
    try {
      final audioPath = await generateSpeech(text, voice: voice, model: model);
      
      // Play audio
      await _audioPlayer?.setFilePath(audioPath);
      await _audioPlayer?.setVolume(volume);
      await _audioPlayer?.setSpeed(speed);
      await _audioPlayer?.play();
      
      print('🔊 OpenAI TTS: Playing audio...');
    } catch (e) {
      print('❌ Error playing OpenAI TTS: $e');
      rethrow;
    }
  }
  
  /// Stop current playback
  Future<void> stop() async {
    await _audioPlayer?.stop();
    print('🔊 OpenAI TTS: Stopped');
  }
  
  /// Pause current playback
  Future<void> pause() async {
    await _audioPlayer?.pause();
    print('🔊 OpenAI TTS: Paused');
  }
  
  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer?.play();
    print('🔊 OpenAI TTS: Resumed');
  }
  
  /// Check if currently playing
  bool get isPlaying => _audioPlayer?.playing ?? false;
  
  /// Get current position
  Duration? get position => _audioPlayer?.position;
  
  /// Get total duration
  Duration? get duration => _audioPlayer?.duration;
  
  /// Dispose resources
  void dispose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
  
  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_prefsKeyApiKey);
    _selectedVoice = prefs.getString(_prefsKeyVoice) ?? 'nova';
    _selectedModel = prefs.getString(_prefsKeyModel) ?? 'gpt-4o-mini-tts';
  }
  
  /// Clear API key (for security)
  Future<void> clearApiKey() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyApiKey);
  }
}

