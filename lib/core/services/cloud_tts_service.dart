import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cloud TTS Service - Supports multiple providers
/// Currently supports: Google Cloud TTS
class CloudTtsService {
  static const String _prefsKeyProvider = 'cloud_tts_provider';
  static const String _prefsKeyApiKey = 'cloud_tts_api_key';
  static const String _prefsKeyVoice = 'cloud_tts_voice';
  static const String _prefsKeyLanguage = 'cloud_tts_language';
  
  // Supported providers
  static const String providerGoogle = 'google';
  static const String providerAzure = 'azure';
  static const String providerPolly = 'polly';
  
  // Google Cloud TTS Voices (Neural2 - most natural)
  static const List<Map<String, String>> googleVoices = [
    {'name': 'en-US-Neural2-A', 'label': 'Neural2-A (Female, Natural)'},
    {'name': 'en-US-Neural2-C', 'label': 'Neural2-C (Female, Natural)'},
    {'name': 'en-US-Neural2-D', 'label': 'Neural2-D (Male, Natural)'},
    {'name': 'en-US-Neural2-F', 'label': 'Neural2-F (Female, Natural)'},
    {'name': 'en-US-Neural2-J', 'label': 'Neural2-J (Male, Natural)'},
    {'name': 'en-US-Wavenet-A', 'label': 'Wavenet-A (Female)'},
    {'name': 'en-US-Wavenet-B', 'label': 'Wavenet-B (Male)'},
    {'name': 'en-US-Wavenet-C', 'label': 'Wavenet-C (Female)'},
    {'name': 'en-US-Wavenet-D', 'label': 'Wavenet-D (Male)'},
    {'name': 'en-US-Wavenet-E', 'label': 'Wavenet-E (Female)'},
    {'name': 'en-US-Wavenet-F', 'label': 'Wavenet-F (Female)'},
  ];
  
  String _provider = providerGoogle;
  String? _apiKey;
  String _voice = 'en-US-Neural2-D'; // Default: Natural male voice
  String _languageCode = 'en-US';
  AudioPlayer? _audioPlayer;
  
  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    await _loadPreferences();
    _audioPlayer = AudioPlayer();
  }
  
  /// Set provider (google, azure, polly)
  Future<void> setProvider(String provider) async {
    _provider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyProvider, provider);
  }
  
  /// Get current provider
  String getProvider() => _provider;
  
  /// Set API key
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyApiKey, apiKey);
  }
  
  /// Get current API key
  String? getApiKey() => _apiKey;
  
  /// Set voice
  Future<void> setVoice(String voice) async {
    _voice = voice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyVoice, voice);
  }
  
  /// Get current voice
  String getVoice() => _voice;
  
  /// Set language code
  Future<void> setLanguageCode(String languageCode) async {
    _languageCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLanguage, languageCode);
  }
  
  /// Get current language code
  String getLanguageCode() => _languageCode;
  
  /// Check if API key is configured
  bool isConfigured() => _apiKey != null && _apiKey!.isNotEmpty;
  
  /// Generate speech from text using Google Cloud TTS
  Future<String> generateSpeech(String text, {
    String? voice,
    double speakingRate = 0.9, // 0.25 to 4.0, default 1.0
    double pitch = 0.0, // -20.0 to 20.0 semitones
    double volumeGainDb = 0.0, // -96.0 to 16.0 dB
  }) async {
    if (!isConfigured()) {
      throw Exception('Cloud TTS API key is not set. Please configure it first.');
    }
    
    if (text.isEmpty) {
      throw Exception('Text cannot be empty');
    }
    
    // Limit text length (Google Cloud TTS limit is 5000 characters)
    if (text.length > 5000) {
      text = text.substring(0, 5000);
      print('⚠️ Text truncated to 5000 characters');
    }
    
    final voiceToUse = voice ?? _voice;
    
    print('🔊 Cloud TTS: Generating speech...');
    print('🔊 Provider: $_provider, Voice: $voiceToUse, Text length: ${text.length}');
    
    try {
      String audioFilePath;
      
      switch (_provider) {
        case providerGoogle:
          audioFilePath = await _generateGoogleTts(
            text,
            voiceToUse,
            speakingRate: speakingRate,
            pitch: pitch,
            volumeGainDb: volumeGainDb,
          );
          break;
        default:
          throw Exception('Provider $_provider is not yet implemented');
      }
      
      print('✅ Cloud TTS: Audio generated successfully (${audioFilePath})');
      return audioFilePath;
    } catch (e) {
      print('❌ Cloud TTS Error: $e');
      rethrow;
    }
  }
  
  /// Generate speech using Google Cloud TTS API
  Future<String> _generateGoogleTts(
    String text,
    String voiceName, {
    double speakingRate = 0.9,
    double pitch = 0.0,
    double volumeGainDb = 0.0,
  }) async {
    final url = Uri.parse(
      'https://texttospeech.googleapis.com/v1/text:synthesize?key=$_apiKey',
    );
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': _languageCode,
          'name': voiceName,
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': speakingRate,
          'pitch': pitch,
          'volumeGainDb': volumeGainDb,
        },
      }),
    );
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final audioContent = responseData['audioContent'] as String;
      final bytes = base64Decode(audioContent);
      
      // Save audio file to temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioFile = File('${tempDir.path}/cloud_tts_$timestamp.mp3');
      await audioFile.writeAsBytes(bytes);
      
      return audioFile.path;
    } else {
      final errorBody = response.body;
      print('❌ Google Cloud TTS Error: ${response.statusCode} - $errorBody');
      throw Exception('Google Cloud TTS API error: ${response.statusCode} - $errorBody');
    }
  }
  
  /// Generate speech and play it directly
  Future<void> speak(String text, {
    String? voice,
    double volume = 1.0,
    double speed = 1.0,
    double speakingRate = 0.9,
    double pitch = 0.0,
  }) async {
    try {
      final audioPath = await generateSpeech(
        text,
        voice: voice,
        speakingRate: speakingRate * speed, // Adjust speaking rate based on speed
        pitch: pitch,
      );
      
      // Play audio
      await _audioPlayer?.setFilePath(audioPath);
      await _audioPlayer?.setVolume(volume);
      await _audioPlayer?.play();
      
      print('🔊 Cloud TTS: Playing audio...');
    } catch (e) {
      print('❌ Error playing Cloud TTS: $e');
      rethrow;
    }
  }
  
  /// Stop current playback
  Future<void> stop() async {
    await _audioPlayer?.stop();
    print('🔊 Cloud TTS: Stopped');
  }
  
  /// Pause current playback
  Future<void> pause() async {
    await _audioPlayer?.pause();
    print('🔊 Cloud TTS: Paused');
  }
  
  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer?.play();
    print('🔊 Cloud TTS: Resumed');
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
    _provider = prefs.getString(_prefsKeyProvider) ?? providerGoogle;
    _apiKey = prefs.getString(_prefsKeyApiKey);
    _voice = prefs.getString(_prefsKeyVoice) ?? 'en-US-Neural2-D';
    _languageCode = prefs.getString(_prefsKeyLanguage) ?? 'en-US';
  }
  
  /// Clear API key (for security)
  Future<void> clearApiKey() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyApiKey);
  }
}

