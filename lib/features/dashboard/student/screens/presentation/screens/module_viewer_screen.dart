import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io';
import 'dart:async';
import 'dart:convert' show utf8;
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';
import '../../../../../../core/services/cloud_tts_service.dart';

// Helper classes for content block processing
enum _BlockType { paragraph, table }

class _ContentBlock {
  final _BlockType type;
  final List<String> content;
  
  _ContentBlock({required this.type, required this.content});
}

class ModuleViewerScreen extends StatefulWidget {
  final Map<dynamic, dynamic> module;

  const ModuleViewerScreen({
    super.key,
    required this.module,
  });

  @override
  State<ModuleViewerScreen> createState() => _ModuleViewerScreenState();
}

class _ModuleViewerScreenState extends State<ModuleViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  PDFViewController? _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  
  // Text-to-Speech variables
  FlutterTts? _flutterTts;
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String _extractedText = '';
  bool _isExtractingText = false;
  int _currentSpeakingPage = 0;
  double _ttsVolume = 1.0; // Volume from 0.0 to 1.0
  bool _showVolumeControl = false;
  double _ttsSpeechRate = 0.4; // Speech rate from 0.3 to 1.0 (0.4 = slower, natural)
  bool _showSpeechRateControl = false;
  bool _isTtsBusy = false; // Track if TTS is busy
  
  // Cloud TTS variables
  CloudTtsService? _cloudTts;
  bool _useCloudTts = false; // Toggle between FlutterTts and Cloud TTS
  
  // Topic-based TTS variables
  List<String> _topics = []; // List of topics/sections
  int _currentTopicIndex = 0; // Current topic being read
  bool _isReadingByTopic = false; // Whether reading by topic mode
  
  // Text selection variables
  String _selectedText = '';
  bool _hasSelectedText = false;
  
  // TTS highlighting variables
  String? _currentSpeakingSentence; // Current sentence being spoken
  Map<String, int> _sentencePositions = {}; // Map of sentence to its position in full text
  
  // Voice selection variables
  List<Map<String, String>> _availableVoices = []; // List of available voices
  Map<String, String>? _selectedVoice; // Currently selected voice {name, locale}
  
  // Video player variables
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  // YouTube links detected in PDF
  Map<int, List<String>> _youtubeLinksByPage = {}; // Page number -> List of YouTube URLs
  bool _isExtractingLinks = false;
  bool _showVideoPanel = true;
  
  // Inline YouTube player controllers (for embedded videos in content)
  Map<String, YoutubePlayerController> _inlineYoutubeControllers = {};
  
  // Cache for DOCX text extraction future
  Future<String>? _docxTextFuture;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeCloudTts();
    _loadModule();
    _initializeVideo();
  }
  
  Future<void> _initializeCloudTts() async {
    try {
      _cloudTts = CloudTtsService();
      await _cloudTts!.initialize();
      print('✅ Cloud TTS initialized');
    } catch (e) {
      print('⚠️ Error initializing Cloud TTS: $e');
    }
  }
  
  @override
  void _initializeVideo() {
    final videoUrl = widget.module['videoUrl']?.toString().trim();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      // Check if it's a YouTube URL
      if (_isYouTubeUrl(videoUrl)) {
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
            ),
          );
          setState(() {
            _isVideoInitialized = true;
          });
        } else {
          print('Could not extract YouTube video ID from URL: $videoUrl');
        }
      } else {
        // For other video URLs, use video_player
        try {
          _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          _videoController!.initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
            }
          }).catchError((error) {
            print('Error initializing video player: $error');
            if (mounted) {
              setState(() {
                _isVideoInitialized = false;
              });
            }
          });
        } catch (e) {
          print('Error creating video player controller: $e');
        }
      }
    }
  }
  
  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<void> _initializeTts() async {
    print('🔊 Initializing TTS...');
    try {
      _flutterTts = FlutterTts();
      
      // Check if TTS is available
      final languages = await _flutterTts!.getLanguages;
      print('🔊 Available TTS languages: ${languages.length}');
      
      // Set TTS parameters for natural, human-like voice
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setSpeechRate(_ttsSpeechRate); // Use current speech rate setting
      await _flutterTts!.setVolume(_ttsVolume);
      await _flutterTts!.setPitch(1.0); // Normal pitch for more natural, human-like voice (0.5-2.0)
      
      // Try to get available voices and select a more natural one if available
      try {
        final voices = await _flutterTts!.getVoices;
        if (voices != null && voices.isNotEmpty) {
          print('🔊 Available voices: ${voices.length}');
          
          // Store available voices for selection
          _availableVoices = [];
          for (var voice in voices) {
            final name = voice['name']?.toString() ?? 'Unknown';
            final locale = voice['locale']?.toString() ?? 'Unknown';
            _availableVoices.add({
              'name': name,
              'locale': locale,
            });
            print('🔊 Voice: $name | Locale: $locale');
          }
          
          // Priority list for natural voices (most natural first)
          // Android: Neural voices (en-us-neural-*), Enhanced voices
          // iOS: Enhanced voices (Samantha, Alex, Karen, Daniel, etc.)
          final priorityKeywords = [
            // Highest priority - Neural voices (Android Google TTS)
            'neural',
            // Enhanced voices (iOS and Android)
            'enhanced', 'premium', 'wave', 'natural',
            // iOS specific natural voices
            'samantha', 'susan', 'karen', 'daniel', 'alex', 'siri', 'victoria', 'aaron',
            'nick', 'sarah', 'tom', 'ava', 'salli', 'joanna', 'ivy', 'kendra', 'kimberly',
            'joey', 'justin', 'kevin', 'matthew', 'emily', 'brian', 'amy', 'russell',
            // Android specific natural voices
            'en-us-news', 'en-us-story', 'en-us-narrative',
            // Generic natural indicators
            'female', 'male'
          ];
          
          String? selectedVoiceName;
          String? selectedVoiceLocale;
          int bestMatch = -1;
          
          // First pass: look for highest priority voice
          for (final voice in voices) {
            final voiceName = voice['name']?.toString().toLowerCase() ?? '';
            final locale = voice['locale']?.toString().toLowerCase() ?? '';
            
            // Check for English voices (en-us, en-gb, etc.)
            if (locale.contains('en')) {
              // Check priority keywords
              for (int i = 0; i < priorityKeywords.length; i++) {
                if (voiceName.contains(priorityKeywords[i])) {
                  if (bestMatch == -1 || i < bestMatch) {
                    bestMatch = i;
                    selectedVoiceName = voice['name']?.toString();
                    selectedVoiceLocale = voice['locale']?.toString();
                    print('🔊 ✅ Found natural voice: ${voice['name']} (priority: ${priorityKeywords[i]})');
                  }
                  break;
                }
              }
            }
          }
          
          // If found a priority voice, use it
          if (selectedVoiceName != null && selectedVoiceLocale != null) {
            _selectedVoice = {
              'name': selectedVoiceName,
              'locale': selectedVoiceLocale,
            };
            await _flutterTts!.setVoice({
              'name': selectedVoiceName,
              'locale': selectedVoiceLocale,
            });
            print('🔊 ✅ Using natural voice: $selectedVoiceName ($selectedVoiceLocale)');
          } else {
            // Fallback: use first English voice
            for (final voice in voices) {
              final locale = voice['locale']?.toString().toLowerCase() ?? '';
              if (locale.contains('en')) {
                _selectedVoice = {
                  'name': voice['name']?.toString() ?? 'Default',
                  'locale': voice['locale']?.toString() ?? 'en-US',
                };
                await _flutterTts!.setVoice({
                  'name': voice['name'],
                  'locale': voice['locale'],
                });
                print('🔊 Using fallback voice: ${voice['name']} (${voice['locale']})');
                break;
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Could not set voice: $e (using default)');
      }
      
      // Set shared instance (Android) - helps with TTS engine stability
      try {
        await _flutterTts!.setSharedInstance(true);
        print('🔊 TTS shared instance set');
      } catch (e) {
        print('⚠️ Could not set shared instance: $e');
      }
      
      // Set queue mode to avoid conflicts (0 = flush, 1 = queue)
      try {
        await _flutterTts!.setQueueMode(0); // Use flush mode instead of queue
        print('🔊 TTS queue mode set to flush');
      } catch (e) {
        print('⚠️ Could not set queue mode: $e');
      }
      
      print('🔊 TTS parameters set');
      
      // Set up completion handler
      _flutterTts!.setCompletionHandler(() {
        print('🔊 TTS completed');
        if (mounted) {
          if (_isReadingByTopic && _currentTopicIndex < _topics.length - 1) {
            // Auto-advance to next topic
            setState(() {
              _isSpeaking = false;
              _isPaused = false;
            });
            // Wait a bit before reading next topic
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _readNextTopic();
              }
            });
          } else {
            // All topics completed
            setState(() {
              _isSpeaking = false;
              _isPaused = false;
              _isReadingByTopic = false;
              _currentTopicIndex = 0;
            });
          }
        }
      });
      
      // Set up error handler
      _flutterTts!.setErrorHandler((msg) {
        print('❌ TTS Error: $msg');
        String errorMessage = 'Text-to-speech error occurred.';
        
        // Handle specific error codes
        if (msg.contains('-8')) {
          errorMessage = 'TTS engine is busy. Please wait a moment and try again.';
        } else if (msg.contains('-1')) {
          errorMessage = 'TTS service error. Please check your device settings.';
        }
        
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      
      setState(() {
        _isTtsInitialized = true;
      });
      print('✅ TTS initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing TTS: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isTtsInitialized = false;
      });
    }
  }

  Future<void> _loadModule() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get download URL from module
      String? downloadURL = widget.module['downloadURL']?.toString();
      
      if (downloadURL == null || downloadURL.isEmpty) {
        // Try to get from filePath
        final String? filePath = widget.module['filePath']?.toString();
        if (filePath != null && filePath.isNotEmpty) {
          final ref = FirebaseStorage.instance.ref().child(filePath);
          downloadURL = await ref.getDownloadURL();
        } else {
          throw Exception('No download URL or file path available');
        }
      }

      if (downloadURL == null || downloadURL.isEmpty) {
        throw Exception('Could not get download URL for module');
      }

      // Download the file to local storage
      final fileName = widget.module['fileName'] ?? 'module.pdf';
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/$fileName');

      // Download file from URL
      final response = await http.get(Uri.parse(downloadURL));
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      setState(() {
        _localPath = localFile.path;
        _isLoading = false;
      });
      
      print('✅ Module loaded successfully: $_localPath');
      print('📄 File size: ${await localFile.length()} bytes');
      
      // Pre-extract text for DOCX files to display immediately
      final fileExtension = widget.module['fileExtension']?.toString().toLowerCase() ?? '';
      if (fileExtension == 'docx' || fileExtension == 'doc' || 
          localFile.path.endsWith('.docx') || localFile.path.endsWith('.doc')) {
        print('📄 Starting text extraction for DOCX file...');
        // Start extraction immediately - FutureBuilder will use this cached future
        _docxTextFuture = _extractTextFromDOCX();
      }
    } catch (e) {
      print('❌ Error loading module: $e');
      setState(() {
        _error = 'Failed to load module: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.textBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.module['title'] ?? 'Module',
          style: const TextStyle(color: AppColors.textWhite),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (_isReady && _totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: const TextStyle(color: AppColors.textWhite),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _loadModule();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) {
      return const Center(
        child: Text(
          'No file path available',
          style: TextStyle(color: AppColors.textWhite),
        ),
      );
    }

    // Check if there's a video URL
    final videoUrl = widget.module['videoUrl']?.toString().trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    
    // Check file extension
    final fileExtension = widget.module['fileExtension']?.toString().toLowerCase() ?? '';
    
    // Build content with video if available
    if (hasVideo) {
      if (_isVideoInitialized) {
        return _buildVideoViewer(fileExtension);
      } else {
        // Show loading or fallback if video is not initialized yet
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading video...',
                style: TextStyle(color: AppColors.textWhite),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (videoUrl != null && await canLaunchUrl(Uri.parse(videoUrl))) {
                    await launchUrl(Uri.parse(videoUrl), mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text('Open Video in Browser'),
              ),
            ],
          ),
        );
      }
    } else if (fileExtension == 'pdf' || _localPath!.endsWith('.pdf')) {
      return _buildPDFViewer();
    } else if (fileExtension == 'docx' || fileExtension == 'doc' || _localPath!.endsWith('.docx') || _localPath!.endsWith('.doc')) {
      if (_localPath == null) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
          ),
        );
      }
      return _buildDOCXViewer();
    } else {
      // For other non-PDF files, show a message
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_drive_file,
              size: 64,
              color: AppColors.textWhite,
            ),
            const SizedBox(height: 16),
            Text(
              'File type: ${fileExtension.toUpperCase()}',
              style: const TextStyle(color: AppColors.textWhite, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Please download the file to view it',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPDFViewer() {
    final hasVideosOnCurrentPage = _showVideoPanel && 
        _youtubeLinksByPage.isNotEmpty && 
        _youtubeLinksByPage.containsKey(_currentPage);
    
    return GestureDetector(
      onLongPressStart: (details) {
        // Start text selection mode
        _showTextSelectionDialog();
      },
      child: Stack(
        children: [
          // PDF Viewer - adjust width if video panel is shown
          Positioned(
            left: 0,
            right: hasVideosOnCurrentPage ? 366 : 0, // 350 (panel width) + 16 (margin)
            top: 0,
            bottom: 0,
            child: PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
            // Extract YouTube links after PDF is rendered
            if (pages != null && pages > 0) {
              _extractYouTubeLinksFromPDF();
            }
          },
            onError: (error) {
              setState(() {
                _error = 'Error rendering PDF: ${error.toString()}';
              });
            },
            onPageError: (page, error) {
              print('Error on page $page: $error');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfViewController = pdfViewController;
            },
            onLinkHandler: (String? uri) {
              print('Link pressed: $uri');
            },
          onPageChanged: (int? page, int? total) {
            setState(() {
              _currentPage = page ?? 0;
              _totalPages = total ?? 0;
              // Clear selected text when page changes
              if (_hasSelectedText) {
                _selectedText = '';
                _hasSelectedText = false;
              }
              // Show video panel if current page has videos
              if (_youtubeLinksByPage.containsKey(_currentPage)) {
                _showVideoPanel = true;
              }
            });
          },
            ),
          ),
        // TTS Controls overlay - with safe area padding
        if (_isTtsInitialized) ...[
          _buildVolumeControl(),
          _buildSpeechRateControl(),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 10,
            left: 10,
            right: 10,
            child: _buildTtsControls(),
          ),
        ],
        // Selected text indicator
        if (_hasSelectedText)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildSelectedTextIndicator(),
          ),
        // YouTube Links Panel
        if (_showVideoPanel && _youtubeLinksByPage.isNotEmpty && _youtubeLinksByPage.containsKey(_currentPage))
          _buildYouTubeLinksPanel(),
      ],
      ),
    );
  }

  Widget _buildFormattedContent(String text) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // Split text into paragraphs
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    // First pass: Group consecutive table rows together
    final processedBlocks = <_ContentBlock>[];
    List<String>? currentTableRows;
    
    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      if (paragraph.isEmpty) continue;
      
      final isTableRow = _isTableRow(paragraph);
      
      if (isTableRow) {
        // Start or continue table grouping
        if (currentTableRows == null) {
          currentTableRows = [];
          print('📊 Starting new table group');
        }
        currentTableRows.add(paragraph);
        print('📊 Added table row: ${paragraph.length > 50 ? paragraph.substring(0, 50) + "..." : paragraph}');
      } else {
        // End table grouping if exists
        if (currentTableRows != null && currentTableRows.isNotEmpty) {
          print('📊 Ending table group with ${currentTableRows.length} rows');
          processedBlocks.add(_ContentBlock(type: _BlockType.table, content: currentTableRows));
          currentTableRows = null;
        }
        // Add regular paragraph
        processedBlocks.add(_ContentBlock(type: _BlockType.paragraph, content: [paragraph]));
      }
    }
    
    // Add any remaining table rows
    if (currentTableRows != null && currentTableRows.isNotEmpty) {
      print('📊 Adding final table group with ${currentTableRows.length} rows');
      processedBlocks.add(_ContentBlock(type: _BlockType.table, content: currentTableRows));
    }
    
    print('📊 Total blocks processed: ${processedBlocks.length} (${processedBlocks.where((b) => b.type == _BlockType.table).length} tables)');
    
    // Second pass: Build widgets from processed blocks
    final widgets = <Widget>[];
    
    for (int i = 0; i < processedBlocks.length; i++) {
      final block = processedBlocks[i];
      
      if (block.type == _BlockType.table) {
        // Render grouped table rows as a proper table
        widgets.add(_buildTable(block.content, i == 0));
        continue;
      }
      
      // Process regular paragraphs
      for (int j = 0; j < block.content.length; j++) {
        final paragraph = block.content[j].trim();
        if (paragraph.isEmpty) continue;

        // Check if paragraph contains YouTube links
        final youtubeLinks = _extractYouTubeLinksFromText(paragraph);
        
        if (youtubeLinks.isNotEmpty) {
          print('🎥 Paragraph contains ${youtubeLinks.length} YouTube link(s)');
        }
        
        // If paragraph is ONLY a YouTube link (standalone), embed it directly
        final trimmedParagraph = paragraph.trim();
        if (youtubeLinks.isNotEmpty && _isOnlyYouTubeLink(trimmedParagraph, youtubeLinks)) {
          for (final link in youtubeLinks) {
            widgets.add(_buildInlineYouTubePlayer(link));
          }
          continue;
        }
        
        // If paragraph contains YouTube links mixed with text, split and embed videos inline
        if (youtubeLinks.isNotEmpty) {
          widgets.addAll(_buildParagraphWithInlineVideos(paragraph, youtubeLinks, i == 0 && j == 0));
          continue;
        }

        // Detect content type
        final isHeading = _isHeading(paragraph, i == 0 && j == 0);
        final isSubHeading = _isSubHeading(paragraph);
        final isListItem = _isListItem(paragraph);
        final isImportant = _isImportant(paragraph);
        final isDefinition = _isDefinition(paragraph);
        
        if (isHeading) {
          // Main Heading with gradient and icon
          widgets.add(
          Container(
            margin: EdgeInsets.only(
              top: i > 0 ? 40 : 0,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                final padding = isSmallScreen ? 12.0 : 20.0;
                final iconSize = isSmallScreen ? 20.0 : 28.0;
                final fontSize = isSmallScreen ? 18.0 : 22.0;
                final spacing = isSmallScreen ? 12.0 : 16.0;
                
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: isSmallScreen ? 14 : 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textBlack.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book,
                          color: AppColors.textWhite,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: SelectableText(
                          paragraph,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            height: 1.3,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          );
        } else if (isSubHeading) {
          // Sub-heading with icon
          widgets.add(
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 360;
              final padding = isSmallScreen ? 12.0 : 18.0;
              final iconSize = isSmallScreen ? 20.0 : 24.0;
              final fontSize = isSmallScreen ? 16.0 : 19.0;
              final spacing = isSmallScreen ? 10.0 : 14.0;
              
              return Container(
                margin: EdgeInsets.only(top: isSmallScreen ? 20 : 28, bottom: isSmallScreen ? 12 : 16),
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: isSmallScreen ? 12 : 14),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.blue400,
                      width: 5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.topic,
                        color: AppColors.blue700,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: SelectableText(
                        paragraph,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          );
        } else if (isImportant) {
          // Important note with warning icon
          widgets.add(
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 360;
              final padding = isSmallScreen ? 12.0 : 18.0;
              final iconSize = isSmallScreen ? 22.0 : 26.0;
              final fontSize = isSmallScreen ? 14.0 : 16.0;
              final spacing = isSmallScreen ? 10.0 : 14.0;
              
              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: AppColors.orange50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.orange300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warningOrange.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.orange800,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildHighlightableText(
                        paragraph.replaceFirst(RegExp(r'^(IMPORTANT|NOTE|TIP|WARNING):?\s*', caseSensitive: false), ''),
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.orange900,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        } else if (isDefinition) {
          // Definition/Key term with info icon
          widgets.add(
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 360;
              final padding = isSmallScreen ? 12.0 : 16.0;
              final iconSize = isSmallScreen ? 20.0 : 24.0;
              final fontSize = isSmallScreen ? 14.0 : 16.0;
              final spacing = isSmallScreen ? 10.0 : 14.0;
              
              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 14 : 18),
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: AppColors.purple50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.purple200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.purple100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        color: AppColors.purple700,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _buildHighlightableText(
                        paragraph,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: AppColors.purple900,
                          height: 1.7,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        } else if (isListItem) {
          // List item with custom bullet
          widgets.add(
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                final padding = isSmallScreen ? 12.0 : 16.0;
                final iconSize = isSmallScreen ? 18.0 : 20.0;
                final fontSize = isSmallScreen ? 14.0 : 16.0;
                final spacing = isSmallScreen ? 10.0 : 14.0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 14),
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: isSmallScreen ? 12 : 14),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.grey200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 4, right: spacing),
                        padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: iconSize,
                          color: AppColors.textWhite,
                        ),
                      ),
                      Expanded(
                        child: _buildHighlightableText(
                          paragraph.replaceFirst(RegExp(r'^[\d\.\-\•]\s*'), ''),
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: AppColors.textBlack87,
                            height: 1.7,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          // Regular paragraph with reading icon and justified text
          widgets.add(
            Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                final padding = isSmallScreen ? 12.0 : 16.0;
                final iconSize = isSmallScreen ? 18.0 : 20.0;
                final fontSize = isSmallScreen ? 14.0 : 16.0;
                final spacing = isSmallScreen ? 10.0 : 14.0;
                
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 16 : 20),
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.grey200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textSecondary.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.article,
                          size: iconSize,
                          color: AppColors.blue700,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: _buildHighlightableText(
                          paragraph,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: AppColors.textBlack87,
                            height: 1.8,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
        
        // Add decorative divider after major sections
        if (isHeading && i < processedBlocks.length - 1) {
          widgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.grey300,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.grey300,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isOnlyYouTubeLink(String text, List<String> youtubeLinks) {
    // Check if the paragraph contains only YouTube links (maybe with whitespace)
    String cleanedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Also check for original link formats in the text
    final youtubeRegex = RegExp(
      r'(?:https?://)?(?:www\.)?(?:m\.)?(?:youtube\.com/(?:watch\?v=|embed/|v/)|youtu\.be/)([a-zA-Z0-9_-]{11})(?:[?&][^\s]*)?',
      caseSensitive: false,
    );
    
    final originalMatches = youtubeRegex.allMatches(text);
    final originalLinks = originalMatches.map((m) => m.group(0)!).toList();
    
    // Remove all normalized links
    for (final link in youtubeLinks) {
      cleanedText = cleanedText.replaceAll(link, '').trim();
    }
    
    // Remove all original format links
    for (final originalLink in originalLinks) {
      cleanedText = cleanedText.replaceAll(originalLink, '').trim();
    }
    
    // If only whitespace or very short text remains, it's likely just a YouTube link
    final isOnlyLink = cleanedText.isEmpty || cleanedText.length < 10;
    
    if (isOnlyLink) {
      print('✅ Paragraph is only YouTube link(s). Remaining text: "$cleanedText"');
    }
    
    return isOnlyLink;
  }

  List<Widget> _buildParagraphWithInlineVideos(String paragraph, List<String> youtubeLinks, bool isFirst) {
    final widgets = <Widget>[];
    String remainingText = paragraph;
    
    // Extract original link formats from the paragraph to match them in text
    final youtubeRegex = RegExp(
      r'(?:https?://)?(?:www\.)?(?:m\.)?(?:youtube\.com/(?:watch\?v=|embed/|v/)|youtu\.be/)([a-zA-Z0-9_-]{11})(?:[?&][^\s]*)?',
      caseSensitive: false,
    );
    
    final originalMatches = youtubeRegex.allMatches(paragraph);
    final linkMap = <String, String>{}; // original format -> normalized format
    
    for (final match in originalMatches) {
      final originalLink = match.group(0)!;
      final videoId = match.group(1)!;
      final normalizedLink = 'https://www.youtube.com/watch?v=$videoId';
      
      // Find the corresponding normalized link from youtubeLinks
      final normalized = youtubeLinks.firstWhere(
        (link) => link.contains(videoId),
        orElse: () => normalizedLink,
      );
      
      linkMap[originalLink] = normalized;
    }
    
    // Process each original link format found in the text
    for (final entry in linkMap.entries) {
      final originalLink = entry.key;
      final normalizedLink = entry.value;
      
      // Find the position of the original link in the text
      final linkIndex = remainingText.indexOf(originalLink);
      
      if (linkIndex == -1) {
        // Try case-insensitive search
        final lowerText = remainingText.toLowerCase();
        final lowerLink = originalLink.toLowerCase();
        final lowerIndex = lowerText.indexOf(lowerLink);
        if (lowerIndex != -1) {
          // Found it, use the normalized link for player
          final textBefore = remainingText.substring(0, lowerIndex).trim();
          
          if (textBefore.isNotEmpty) {
            widgets.add(
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: _buildHighlightableText(
                  textBefore,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textBlack87,
                    height: 1.8,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            );
          }
          
          widgets.add(_buildInlineYouTubePlayer(normalizedLink));
          remainingText = remainingText.substring(lowerIndex + originalLink.length).trim();
        }
        continue;
      }
      
      // Text before the link
      final textBefore = remainingText.substring(0, linkIndex).trim();
      
      // Add text before link if it exists
      if (textBefore.isNotEmpty) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey200,
                width: 1,
              ),
            ),
            child: SelectableText(
              textBefore,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textBlack87,
                height: 1.8,
                letterSpacing: 0.1,
              ),
            ),
          ),
        );
      }
      
      // Add embedded YouTube video using normalized link
      widgets.add(
        _buildInlineYouTubePlayer(normalizedLink),
      );
      
      // Update remaining text (text after the link)
      remainingText = remainingText.substring(linkIndex + originalLink.length).trim();
    }
    
    // Add any remaining text after all links
    if (remainingText.isNotEmpty) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16, top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: _buildHighlightableText(
            remainingText,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.8,
              letterSpacing: 0.1,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  Widget _buildInlineYouTubePlayer(String youtubeUrl) {
    // Extract video ID from YouTube URL
    String? videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
    
    if (videoId == null) {
      // If URL conversion fails, try manual extraction
      final regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      final match = regExp.firstMatch(youtubeUrl);
      videoId = match?.group(1);
    }
    
    if (videoId == null) {
      // Fallback: show link as text
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.red50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red300),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: SelectableText(
                youtubeUrl,
                style: const TextStyle(
                  color: AppColors.red900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Reuse existing controller if available, otherwise create new one
    YoutubePlayerController controller;
    if (_inlineYoutubeControllers.containsKey(videoId)) {
      controller = _inlineYoutubeControllers[videoId]!;
    } else {
      controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          loop: false,
          isLive: false,
        ),
      );
      _inlineYoutubeControllers[videoId] = controller;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textBlack.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video player
            YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.primaryBlue,
              progressColors: ProgressBarColors(
                playedColor: AppColors.primaryBlue,
                handleColor: AppColors.primaryBlue,
                bufferedColor: AppColors.grey300,
                backgroundColor: AppColors.grey200,
              ),
              onReady: () {
                print('✅ YouTube player ready for video: $videoId');
              },
              onEnded: (metadata) {
                print('✅ Video ended: ${metadata.title}');
              },
            ),
            // Video info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                border: const Border(
                  top: BorderSide(color: AppColors.grey200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.red100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.play_circle_filled,
                      color: AppColors.red700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: const Text(
                      'Video Content',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
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

  bool _isHeading(String text, bool isFirst) {
    // Check if text is likely a heading
    if (text.length > 100) return false;
    
    // All caps (likely heading)
    if (text == text.toUpperCase() && text.length > 3 && text.length < 50) {
      return true;
    }
    
    // Ends with colon and is short
    if (text.endsWith(':') && text.length < 80) {
      return true;
    }
    
    // Starts with numbers followed by period (e.g., "1. Introduction")
    if (RegExp(r'^\d+\.\s+[A-Z]').hasMatch(text) && text.length < 100) {
      return true;
    }
    
    // Roman numerals (e.g., "I. Introduction", "II. Chapter")
    if (RegExp(r'^[IVX]+\.\s+[A-Z]').hasMatch(text) && text.length < 100) {
      return true;
    }
    
    return false;
  }

  bool _isListItem(String text) {
    // Check if text starts with list markers
    return RegExp(r'^[\d\.\-\•\*]\s+').hasMatch(text) ||
           RegExp(r'^[a-z]\)\s+').hasMatch(text) ||
           RegExp(r'^[A-Z]\)\s+').hasMatch(text);
  }

  bool _isTableRow(String text) {
    if (text.trim().isEmpty) return false;
    
    // Check for pipe separators (common in markdown tables)
    if (text.contains('|') && text.split('|').length > 2) {
      return true;
    }
    
    // Check for tab characters (common in copied tables)
    if (text.contains('\t')) {
      return true;
    }
    
    // Check for multiple columns with consistent spacing (2+ spaces or more)
    final parts = text.split(RegExp(r'\s{2,}'));
    if (parts.length >= 2 && text.length < 300) {
      // Additional check: if it looks like table data (not a sentence)
      final hasMultipleWords = parts.where((p) => p.trim().isNotEmpty).length >= 2;
      final isNotLongSentence = text.length < 150 || parts.length >= 3;
      return hasMultipleWords && isNotLongSentence;
    }
    
    return false;
  }

  /// Split a detected table row into individual cell values.
  /// - Prefer tab characters as delimiters if present.
  /// - Fallback to 3+ spaces as column separators.
  /// This helps render DOCX/PDF tables as aligned columns instead of plain text.
  List<String> _splitTableCells(String text) {
    if (text.trim().isEmpty) return [text];

    // Check for pipe separators (markdown table format: | col1 | col2 |)
    if (text.contains('|')) {
      final parts = text.split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty && !RegExp(r'^[-:]+$').hasMatch(c)) // Remove separator rows like |---|---|
          .toList();
      if (parts.length > 1) return parts;
    }

    // If there are tab characters, use them as primary delimiters
    if (text.contains('\t')) {
      final parts = text.split('\t').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      if (parts.length > 1) return parts;
    }

    // Split on 2 or more spaces (more lenient for tables)
    final spaceParts = text.split(RegExp(r'\s{2,}')).map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    if (spaceParts.length > 1) {
      return spaceParts;
    }

    // As a last resort, return the whole line as a single cell
    return [text.trim()];
  }

  /// Builds a proper table widget from grouped table rows
  Widget _buildTable(List<String> tableRows, bool isFirst) {
    if (tableRows.isEmpty) return const SizedBox.shrink();
    
    // Parse all rows into cells
    final List<List<String>> rows = [];
    int maxColumns = 0;
    
    for (final row in tableRows) {
      final cells = _splitTableCells(row);
      if (cells.isNotEmpty) {
        rows.add(cells);
        if (cells.length > maxColumns) {
          maxColumns = cells.length;
        }
      }
    }
    
    if (rows.isEmpty) return const SizedBox.shrink();
    
    // Normalize all rows to have the same number of columns
    for (final row in rows) {
      while (row.length < maxColumns) {
        row.add('');
      }
    }
    
    // Determine if first row is header (usually all caps or bold pattern)
    final firstRow = rows[0];
    final isFirstRowHeader = firstRow.any((cell) => 
      cell.toUpperCase() == cell && cell.length > 3 && 
      !RegExp(r'^\d+$').hasMatch(cell.trim())
    ) || firstRow.length <= 3;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final cellPadding = isSmallScreen ? 8.0 : 12.0;
        final fontSize = isSmallScreen ? 12.0 : 14.0;
        final headerFontSize = isSmallScreen ? 13.0 : 15.0;
        
        // For tables with many columns or wide content, make horizontally scrollable
        final needsHorizontalScroll = maxColumns > 3 || screenWidth < 400;
        
        // Calculate minimum table width based on columns
        final minTableWidth = maxColumns * (isSmallScreen ? 100.0 : 120.0);
        final tableWidth = needsHorizontalScroll ? minTableWidth : (screenWidth.isFinite ? screenWidth - 8 : minTableWidth);
        
        Widget tableContent = ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: tableWidth,
            maxWidth: tableWidth, // Always use bounded width
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Table header (if first row is header)
            if (isFirstRowHeader && rows.length > 1)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.grey300,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: rows[0].asMap().entries.map((entry) {
                    final index = entry.key;
                    final cell = entry.value;
                    return Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: cellPadding, vertical: isSmallScreen ? 10 : 14),
                        decoration: BoxDecoration(
                          border: Border(
                            right: index < rows[0].length - 1
                                ? BorderSide(color: AppColors.primaryBlue.withOpacity(0.2), width: 1.5)
                                : BorderSide.none,
                          ),
                        ),
                        child: SelectableText(
                          cell.isEmpty ? ' ' : cell,
                          style: TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Table body
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isHeaderRow = isFirstRowHeader && index == 0;
              final isDataRow = !isFirstRowHeader || index > 0;
              
              if (isHeaderRow) return const SizedBox.shrink();
              
              return Container(
                decoration: BoxDecoration(
                  color: isDataRow && index % 2 == (isFirstRowHeader ? 1 : 0)
                      ? AppColors.grey50
                      : AppColors.surfaceWhite,
                  border: Border(
                    bottom: index < rows.length - 1
                        ? BorderSide(color: AppColors.grey200, width: 1)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: row.asMap().entries.map((cellEntry) {
                    final cellIndex = cellEntry.key;
                    final cell = cellEntry.value;
                    return Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: cellPadding, vertical: isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right: cellIndex < row.length - 1
                                ? BorderSide(color: AppColors.grey300.withOpacity(0.5), width: 1)
                                : BorderSide.none,
                          ),
                        ),
                        child: _buildHighlightableText(
                          cell.isEmpty ? ' ' : cell,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: AppColors.textPrimary,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
            ],
          ),
        );
        
        return Container(
          margin: EdgeInsets.only(
            top: isFirst ? 0 : 24,
            bottom: 24,
            left: 4,
            right: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textBlack.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: needsHorizontalScroll
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: screenWidth.isFinite ? screenWidth - 8 : minTableWidth,
                    ),
                    child: tableContent,
                  ),
                )
              : tableContent,
        );
      },
    );
  }

  bool _isSubHeading(String text) {
    // Sub-headings are shorter than main headings, may have specific patterns
    if (text.length > 80 || text.length < 5) return false;
    
    // Starts with lowercase but has important keywords
    if (RegExp(r'^(overview|introduction|summary|conclusion|key points|objectives|goals):?', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    
    // Short text that ends with colon (but not a main heading)
    if (text.endsWith(':') && text.length < 60 && !text.startsWith(RegExp(r'^[A-Z]{2,}'))) {
      return true;
    }
    
    // Text with specific formatting patterns
    if (RegExp(r'^[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*:?$').hasMatch(text) && text.length < 60) {
      return true;
    }
    
    return false;
  }

  bool _isImportant(String text) {
    // Check for important notes, tips, warnings
    final upperText = text.toUpperCase();
    return upperText.startsWith('IMPORTANT') ||
           upperText.startsWith('NOTE:') ||
           upperText.startsWith('TIP:') ||
           upperText.startsWith('WARNING:') ||
           upperText.startsWith('REMEMBER:') ||
           upperText.startsWith('KEY POINT:') ||
           upperText.startsWith('ATTENTION:');
  }

  bool _isDefinition(String text) {
    // Check if text is a definition or key term
    // Usually starts with a term followed by colon or dash
    if (text.length < 20 || text.length > 150) return false;
    
    // Pattern: "Term: definition" or "Term - definition"
    if (RegExp(r'^[A-Z][a-zA-Z\s]+[:–-]\s+').hasMatch(text)) {
      return true;
    }
    
    // Pattern: "Definition: ..." or "Key Term: ..."
    if (RegExp(r'^(definition|key term|term|concept):\s+', caseSensitive: false).hasMatch(text)) {
      return true;
    }
    
    return false;
  }

  Widget _buildDOCXViewer() {
    print('🔵 _buildDOCXViewer called');
    print('🔵 _localPath: $_localPath');
    print('🔵 _youtubeLinksByPage: $_youtubeLinksByPage');
    print('🔵 _isExtractingLinks: $_isExtractingLinks');
    
    // Extract YouTube links when DOCX is loaded (only once)
    if (_youtubeLinksByPage.isEmpty && !_isExtractingLinks && _localPath != null) {
      print('🔵 Scheduling YouTube link extraction...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔵 Executing YouTube link extraction...');
        _extractYouTubeLinksFromDOCX();
      });
    }
    
    // For DOCX with inline videos, don't show side panel
    // For DOCX files, always hide side panel - videos are embedded inline
    final isDocxFile = widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
                      widget.module['fileExtension']?.toString().toLowerCase() == 'doc' ||
                      _localPath?.endsWith('.docx') == true ||
                      _localPath?.endsWith('.doc') == true;
    final hasInlineVideos = _youtubeLinksByPage.isNotEmpty && 
        _youtubeLinksByPage.containsKey(0);
    // For DOCX, NEVER show side panel (videos are inline). For PDF, show side panel if enabled.
    final hasVideos = !isDocxFile && _showVideoPanel && hasInlineVideos;
    
    // Force hide video panel for DOCX files
    if (isDocxFile && _showVideoPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showVideoPanel = false;
          });
        }
      });
    }
    
    // Use cached future if available, otherwise create new one
    _docxTextFuture ??= _extractTextFromDOCX().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('⏱️ Text extraction timed out after 30 seconds');
        return 'Error: Text extraction timed out. Please try again.';
      },
    );
    
    return FutureBuilder<String>(
      future: _docxTextFuture,
      builder: (context, snapshot) {
        print('🔵 FutureBuilder state: ${snapshot.connectionState}');
        print('🔵 FutureBuilder hasError: ${snapshot.hasError}');
        print('🔵 FutureBuilder hasData: ${snapshot.hasData}');
        if (snapshot.hasData) {
          print('🔵 FutureBuilder data length: ${snapshot.data?.length ?? 0}');
        }
        if (snapshot.hasError) {
          print('❌ FutureBuilder error: ${snapshot.error}');
          print('❌ Stack trace: ${snapshot.stackTrace}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔵 Showing loading indicator...');
          return Container(
            color: AppColors.grey900,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading document...',
                    style: TextStyle(color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          print('❌ Error in FutureBuilder: ${snapshot.error}');
          print('❌ Stack trace: ${snapshot.stackTrace}');
          return Container(
            color: AppColors.grey900,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.errorRed),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading document:\n${snapshot.error}',
                      style: const TextStyle(color: AppColors.textWhite),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Retry loading
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Check if we have data
        if (!snapshot.hasData) {
          print('⚠️ FutureBuilder has no data');
          return Container(
            color: AppColors.grey900,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading document content...',
                    style: TextStyle(color: AppColors.textWhite),
                  ),
                ],
              ),
            ),
          );
        }
        
        final text = snapshot.data ?? '';
        print('✅ DOCX text extracted: ${text.length} characters');
        if (text.isNotEmpty) {
          print('🔵 Text preview (first 200 chars): ${text.length > 200 ? text.substring(0, 200) : text}');
        } else {
          print('⚠️ Text is empty!');
        }
        
        if (text.isEmpty || text.startsWith('Error')) {
          print('⚠️ Text is empty or has error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber, size: 64, color: AppColors.warningOrange),
                const SizedBox(height: 16),
                const Text(
                  'No content found in document',
                  style: TextStyle(color: AppColors.textWhite, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  text.isEmpty ? 'The document appears to be empty.' : text,
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
        
        return Container(
          color: AppColors.surfaceWhite,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document title with gradient background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.textWhite.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: AppColors.textWhite,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.module['title'] ?? 'Document',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textWhite,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.module['description'] != null && 
                              widget.module['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.textWhite.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.module['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textWhite.withOpacity(0.9),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Formatted document content
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildFormattedContent(text),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              // TTS Controls overlay
              if (_isTtsInitialized) ...[
                _buildVolumeControl(),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildTtsControls(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<String> _extractTextFromDOCX() async {
    if (_localPath == null) {
      print('❌ _localPath is null');
      return 'Error: File path is not available';
    }
    
    try {
      final file = File(_localPath!);
      
      if (!await file.exists()) {
        print('❌ File does not exist: $_localPath');
        return 'Error: File does not exist';
      }
      
      print('📄 Reading DOCX file: $_localPath');
      final bytes = await file.readAsBytes();
      print('📄 File size: ${bytes.length} bytes');
      
      if (bytes.isEmpty) {
        print('❌ File is empty');
        return 'Error: File is empty';
      }
      
      // Extract text from DOCX file
      print('🔄 Extracting text from DOCX...');
      String text;
      try {
        // DOCX is a ZIP archive containing XML files
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Find and read the main document XML (word/document.xml)
        ArchiveFile? documentXml;
        for (final file in archive) {
          if (file.name == 'word/document.xml') {
            documentXml = file;
            break;
          }
        }
        
        if (documentXml == null) {
          throw Exception('Could not find word/document.xml in DOCX file');
        }
        
        // Decompress and parse the XML
        final xmlContent = utf8.decode(documentXml.content as List<int>);
        final document = xml.XmlDocument.parse(xmlContent);
        
        // Extract hyperlinks from relationships file first
        ArchiveFile? relsFile;
        Map<String, String> hyperlinkTargets = {};
        for (final file in archive) {
          if (file.name == 'word/_rels/document.xml.rels') {
            relsFile = file;
            break;
          }
        }
        
        if (relsFile != null) {
          try {
            final relsContent = utf8.decode(relsFile.content as List<int>);
            final relsDoc = xml.XmlDocument.parse(relsContent);
            final relationships = relsDoc.findAllElements('Relationship');
            for (final rel in relationships) {
              final id = rel.getAttribute('Id');
              final target = rel.getAttribute('Target');
              if (id != null && target != null) {
                hyperlinkTargets[id] = target;
              }
            }
            print('🔗 Found ${hyperlinkTargets.length} hyperlink(s) in document');
          } catch (e) {
            print('⚠️ Could not parse relationships file: $e');
          }
        }
        
        // Extract text from paragraphs AND tables to preserve structure AND ORDER
        final body = document.findAllElements('w:body').first;
        final textBuffer = StringBuffer();
        
        // Process body children in order to maintain sequence of paragraphs and tables
        int tableCount = 0;
        for (final child in body.children) {
          // Check if it's a table element
          if (child is xml.XmlElement && child.localName == 'tbl') {
            tableCount++;
            final table = child;
            final tableRows = table.findAllElements('w:tr');
            print('📊 Processing table #$tableCount with ${tableRows.length} rows');
            
            for (final row in tableRows) {
              final cells = row.findAllElements('w:tc');
              final cellTexts = <String>[];
              
              for (final cell in cells) {
                final cellTextNodes = cell.findAllElements('w:t');
                final cellBuffer = StringBuffer();
                for (final node in cellTextNodes) {
                  final nodeText = node.text;
                  if (nodeText.isNotEmpty) {
                    cellBuffer.write(nodeText);
                  }
                }
                cellTexts.add(cellBuffer.toString().trim());
              }
              
              // Join cells with tab character to preserve table structure
              if (cellTexts.isNotEmpty) {
                textBuffer.write(cellTexts.join('\t'));
                textBuffer.write('\n\n'); // Double newline to separate table rows
                print('📊 Table row: ${cellTexts.join(' | ')}');
              }
            }
            // Add extra newline after table to separate from next content
            textBuffer.write('\n');
          } 
          // Check if it's a paragraph element
          else if (child is xml.XmlElement && child.localName == 'p') {
            final paragraph = child;
            final paraTextNodes = paragraph.findAllElements('w:t');
            final paraBuffer = StringBuffer();
            
            // Check for hyperlinks in this paragraph and add URLs to text
            final hyperlinks = paragraph.findAllElements('w:hyperlink');
            for (final hyperlink in hyperlinks) {
              final relId = hyperlink.getAttribute('r:id');
              if (relId != null && hyperlinkTargets.containsKey(relId)) {
                final hyperlinkUrl = hyperlinkTargets[relId];
                // If it's a YouTube link, add the URL directly to the text
                if (hyperlinkUrl != null && 
                    (hyperlinkUrl.contains('youtube.com') || hyperlinkUrl.contains('youtu.be'))) {
                  paraBuffer.write(' $hyperlinkUrl ');
                  print('🎥 Found YouTube hyperlink: $hyperlinkUrl');
                }
              }
            }
            
            for (final node in paraTextNodes) {
              final nodeText = node.text;
              if (nodeText.isNotEmpty) {
                paraBuffer.write(nodeText);
              }
            }
            
            final paraText = paraBuffer.toString().trim();
            if (paraText.isNotEmpty) {
              textBuffer.write(paraText);
              textBuffer.write('\n\n'); // Add double newline between paragraphs
            }
          }
        }
        
        print('📊 Total tables extracted: $tableCount');
        
        text = textBuffer.toString().trim();
        
        // Clean up extra whitespace but PRESERVE tabs in table rows
        // Only clean up multiple spaces (not tabs) in regular text
        // Split by lines first to preserve table structure
        final lines = text.split('\n');
        final cleanedLines = <String>[];
        for (final line in lines) {
          if (line.contains('\t')) {
            // This is a table row - preserve tabs, only clean up multiple spaces within cells
            final cells = line.split('\t');
            final cleanedCells = cells.map((cell) => 
              cell.replaceAll(RegExp(r'[ ]{2,}'), ' ').trim()
            ).toList();
            cleanedLines.add(cleanedCells.join('\t'));
          } else {
            // Regular text - clean up spaces and tabs
            cleanedLines.add(line.replaceAll(RegExp(r'[ \t]+'), ' ').trim());
          }
        }
        text = cleanedLines.join('\n');
        text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // More than 2 newlines to double newline
        
        // Remove XML artifacts if any
        text = text.replaceAll(RegExp(r'<[^>]+>'), ''); // Remove any remaining XML tags
        
        // Final cleanup
        text = text.trim();
        
        print('✅ Text extracted: ${text.length} characters');
        if (text.length > 0) {
          print('📝 First 200 chars: ${text.substring(0, text.length > 200 ? 200 : text.length)}');
        } else {
          print('⚠️ Extracted text is empty after processing');
        }
      } catch (e, stackTrace) {
        print('❌ Error extracting text from DOCX: $e');
        print('Stack trace: $stackTrace');
        // Try alternative: check if file is actually a DOCX
        if (bytes.length < 4) {
          throw Exception('File too small to be a valid DOCX');
        }
        // DOCX files start with PK (ZIP signature)
        final signature = String.fromCharCodes(bytes.take(2));
        if (signature != 'PK') {
          throw Exception('File does not appear to be a valid DOCX (missing ZIP signature)');
        }
        throw Exception('Failed to extract text: $e');
      }
      
      if (text.isEmpty) {
        print('⚠️ Extracted text is empty');
        return 'The document appears to be empty or could not be read.';
      }
      
      return text;
    } catch (e, stackTrace) {
      print('❌ Error extracting text from DOCX: $e');
      print('Stack trace: $stackTrace');
      return 'Error loading document: ${e.toString()}';
    }
  }

  Widget _buildYouTubeLinksPanel() {
    // Don't show side panel for DOCX files - videos are embedded inline
    final isDocxFile = widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
                      widget.module['fileExtension']?.toString().toLowerCase() == 'doc';
    if (isDocxFile) {
      return const SizedBox.shrink();
    }
    
    // For PDF files, use current page
    final pageIndex = _currentPage;
    final currentPageLinks = _youtubeLinksByPage[pageIndex] ?? [];
    
    if (currentPageLinks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 350,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textBlack87,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textBlack.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_library, color: AppColors.textWhite),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
                      widget.module['fileExtension']?.toString().toLowerCase() == 'doc'
                          ? 'Videos in Document'
                          : 'Videos on Page ${_currentPage + 1}',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textWhite, size: 20),
                    onPressed: () {
                      setState(() {
                        _showVideoPanel = false;
                      });
                    },
                    tooltip: 'Hide videos',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isExtractingLinks
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: currentPageLinks.length,
                      itemBuilder: (context, index) {
                        final videoUrl = currentPageLinks[index];
                        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
                        
                        if (videoId == null) return const SizedBox.shrink();
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: YoutubePlayerBuilder(
                            onExitFullScreen: () {
                              // Handle fullscreen exit if needed
                            },
                            player: YoutubePlayer(
                              controller: YoutubePlayerController(
                                initialVideoId: videoId,
                                flags: const YoutubePlayerFlags(
                                  autoPlay: false,
                                  mute: false,
                                  hideControls: false,
                                  controlsVisibleAtStart: false,
                                ),
                              ),
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: AppColors.primaryBlue,
                              progressColors: ProgressBarColors(
                                playedColor: AppColors.primaryBlue,
                                handleColor: AppColors.primaryBlue,
                                bufferedColor: AppColors.textSecondary,
                                backgroundColor: AppColors.textBlack.withOpacity(0.26),
                              ),
                            ),
                            builder: (context, player) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                    child: player,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Video ${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViewer(String fileExtension) {
    final videoUrl = widget.module['videoUrl']?.toString().trim() ?? '';
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video Player Section
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textBlack.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isYouTubeUrl(videoUrl) && _youtubeController != null
                  ? YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: AppColors.primaryBlue,
                    )
                  : _videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                    playedColor: AppColors.primaryBlue,
                                    bufferedColor: AppColors.textSecondary,
                                    backgroundColor: AppColors.textBlack.withOpacity(0.26),
                                  ),
                                ),
                              ),
                              // Play/Pause button overlay
                              if (!_videoController!.value.isPlaying)
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_circle_filled,
                                    size: 64,
                                    color: AppColors.textWhite,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _videoController!.play();
                                    });
                                  },
                                ),
                            ],
                          ),
                        )
                      : Container(
                          height: 200,
                          color: AppColors.textBlack,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          ),
                        ),
            ),
          ),
          
          // Video Controls for non-YouTube videos
          if (!_isYouTubeUrl(videoUrl) && _videoController != null && _videoController!.value.isInitialized)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // PDF or File Section (if available)
          if (fileExtension == 'pdf' && _localPath != null) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Module Document',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: _buildPDFViewer(),
                  ),
                ],
              ),
            ),
          ] else if (_localPath != null) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.insert_drive_file, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'File type: ${fileExtension.toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = widget.module['downloadURL']?.toString();
                      if (url != null && await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildSelectedTextIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.text_fields, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedText.length > 50 
                ? '${_selectedText.substring(0, 50)}...' 
                : _selectedText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () {
              setState(() {
                _selectedText = '';
                _hasSelectedText = false;
              });
            },
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  void _showTextSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Text to Read'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
              widget.module['fileExtension']?.toString().toLowerCase() == 'doc'
                  ? 'Enter the text you want to read aloud, or leave empty to read the entire document.'
                  : 'Enter the text you want to read aloud, or leave empty to read the entire page.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste or type text here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedText = value;
                  _hasSelectedText = value.isNotEmpty;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Extract text from current page or document
              _extractAndSelectPageText();
              Navigator.pop(context);
            },
            child: Text(widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
                       widget.module['fileExtension']?.toString().toLowerCase() == 'doc'
                ? 'Use Document Text'
                : 'Use Page Text'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_hasSelectedText) {
                _startTtsWithText(_selectedText);
              }
            },
            child: const Text('Read Selected'),
          ),
        ],
      ),
    );
  }

  Future<void> _extractAndSelectPageText() async {
    setState(() {
      _isExtractingText = true;
    });

    try {
      String text;
      final fileExtension = widget.module['fileExtension']?.toString().toLowerCase() ?? '';
      
      // Check if it's a DOCX file
      if (fileExtension == 'docx' || fileExtension == 'doc' || 
          _localPath?.endsWith('.docx') == true || _localPath?.endsWith('.doc') == true) {
        text = await _extractTextFromDOCX();
      } else {
        // For PDF files
        text = await _extractTextFromPage(_currentPage);
      }
      
      if (mounted) {
        setState(() {
          _selectedText = text;
          _hasSelectedText = text.isNotEmpty;
          _isExtractingText = false;
        });
        
        if (text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fileExtension == 'docx' || fileExtension == 'doc' 
                  ? 'No text found in document' 
                  : 'No text found on this page'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(fileExtension == 'docx' || fileExtension == 'doc'
                  ? 'Extracted ${text.length} characters from document'
                  : 'Extracted ${text.length} characters from page ${_currentPage + 1}'),
              backgroundColor: AppColors.primaryBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExtractingText = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTtsControls() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 360 ? 12 : 16,
        vertical: MediaQuery.of(context).size.width < 360 ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Topic navigation (if reading by topic)
          if (_isReadingByTopic && _topics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous topic button
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 20),
                    color: _currentTopicIndex > 0 ? Colors.white : Colors.grey,
                    onPressed: _currentTopicIndex > 0 ? _readPreviousTopic : null,
                    tooltip: 'Previous topic',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Topic progress text
                  Text(
                    'Topic ${_currentTopicIndex + 1}/${_topics.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Next topic button
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 20),
                    color: _currentTopicIndex < _topics.length - 1 ? Colors.white : Colors.grey,
                    onPressed: _currentTopicIndex < _topics.length - 1 ? _readNextTopic : null,
                    tooltip: 'Next topic',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Main controls - responsive layout to prevent overflow
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              final isVerySmallScreen = constraints.maxWidth < 320;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play/Pause/Start button
                  if (_isExtractingText)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (_isSpeaking)
                    IconButton(
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      color: Colors.white,
                      iconSize: isSmallScreen ? 20 : 24,
                      padding: isSmallScreen ? const EdgeInsets.all(8) : null,
                      constraints: isSmallScreen ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
                      onPressed: _isPaused ? _resumeTts : _pauseTts,
                      tooltip: _isPaused ? 'Resume' : 'Pause',
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      color: Colors.white,
                      iconSize: isSmallScreen ? 20 : 24,
                      padding: isSmallScreen ? const EdgeInsets.all(8) : null,
                      constraints: isSmallScreen ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
                      onPressed: _startTts,
                      tooltip: 'Read aloud',
                    ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  // Status text - flexible to prevent overflow
                  Flexible(
                    child: Text(
                      _isExtractingText
                          ? 'Extracting...'
                          : _isSpeaking
                              ? (_isPaused 
                                  ? 'Paused' 
                                  : _isReadingByTopic 
                                      ? 'Topic ${_currentTopicIndex + 1}/${_topics.length}'
                                      : _hasSelectedText 
                                          ? 'Reading selected...' 
                                          : 'Reading...')
                              : _hasSelectedText 
                                  ? 'Tap to read'
                                  : 'Tap to read',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Stop button (only when speaking)
                  if (_isSpeaking) ...[
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      color: Colors.white,
                      iconSize: isSmallScreen ? 20 : 24,
                      padding: isSmallScreen ? const EdgeInsets.all(8) : null,
                      constraints: isSmallScreen ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
                      onPressed: () {
                        _stopTts();
                        setState(() {
                          _isReadingByTopic = false;
                          _currentTopicIndex = 0;
                        });
                      },
                      tooltip: 'Stop',
                    ),
                  ],
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  // Volume button
                  IconButton(
                    icon: Icon(
                      _ttsVolume == 0.0 
                        ? Icons.volume_off 
                        : _ttsVolume < 0.5 
                          ? Icons.volume_down 
                          : Icons.volume_up,
                      size: isSmallScreen ? 18 : 22,
                    ),
                    color: Colors.white,
                    iconSize: isSmallScreen ? 18 : 22,
                    padding: isSmallScreen ? const EdgeInsets.all(8) : null,
                    constraints: isSmallScreen ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
                    onPressed: () {
                      setState(() {
                        _showVolumeControl = !_showVolumeControl;
                        if (_showVolumeControl) {
                          _showSpeechRateControl = false;
                        }
                      });
                    },
                    tooltip: 'Volume: ${(_ttsVolume * 100).toInt()}%',
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  // Speed button - compact on small screens
                  if (!isVerySmallScreen)
                    Material(
                      color: _showSpeechRateControl ? Colors.orange.withOpacity(0.5) : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          print('🔊 Speech rate button pressed. Current state: $_showSpeechRateControl');
                          setState(() {
                            _showSpeechRateControl = !_showSpeechRateControl;
                            if (_showSpeechRateControl) {
                              _showVolumeControl = false;
                            }
                          });
                          print('🔊 Speech rate control state after toggle: $_showSpeechRateControl');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_showSpeechRateControl 
                                ? 'Speed: Drag slider (${(_ttsSpeechRate * 100).toInt()}%)'
                                : 'Speed: ${(_ttsSpeechRate * 100).toInt()}%'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 4 : 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _ttsSpeechRate < 0.3
                                  ? Icons.speed
                                  : _ttsSpeechRate < 0.5
                                    ? Icons.slow_motion_video
                                    : Icons.speed_outlined,
                                color: Colors.white,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              if (!isSmallScreen) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${(_ttsSpeechRate * 100).toInt()}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 10 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        _ttsSpeechRate < 0.3
                          ? Icons.speed
                          : _ttsSpeechRate < 0.5
                            ? Icons.slow_motion_video
                            : Icons.speed_outlined,
                      ),
                      color: Colors.white,
                      iconSize: 18,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () {
                        setState(() {
                          _showSpeechRateControl = !_showSpeechRateControl;
                          if (_showSpeechRateControl) {
                            _showVolumeControl = false;
                          }
                        });
                      },
                      tooltip: 'Speed: ${(_ttsSpeechRate * 100).toInt()}%',
                    ),
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  // Voice selection button
                  IconButton(
                    icon: const Icon(Icons.record_voice_over),
                    color: Colors.white,
                    iconSize: isSmallScreen ? 18 : 22,
                    padding: isSmallScreen ? const EdgeInsets.all(8) : null,
                    constraints: isSmallScreen ? const BoxConstraints(minWidth: 36, minHeight: 36) : null,
                    onPressed: _showVoiceSelectionDialog,
                    tooltip: 'Select Voice',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    if (!_showVolumeControl) return const SizedBox.shrink();
    
    // Calculate bottom position based on safe area and TTS controls height
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final ttsControlsHeight = 60.0; // Approximate height of TTS controls
    final bottomPosition = bottomPadding + ttsControlsHeight + 20;
    
    return Positioned(
      bottom: bottomPosition,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _ttsVolume == 0.0 
                ? Icons.volume_off 
                : _ttsVolume < 0.5 
                  ? Icons.volume_down 
                  : Icons.volume_up,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _ttsVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: AppColors.primaryBlue,
                inactiveColor: Colors.white30,
                label: '${(_ttsVolume * 100).toInt()}%',
                onChanged: (value) async {
                  setState(() {
                    _ttsVolume = value;
                  });
                  if (_flutterTts != null) {
                    await _flutterTts!.setVolume(_ttsVolume);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(_ttsVolume * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSpeechRateControl() {
    if (!_showSpeechRateControl) {
      print('🔊 Speech rate control is hidden');
      return const SizedBox.shrink();
    }
    
    // Calculate bottom position based on safe area, TTS controls, and volume control
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final ttsControlsHeight = 60.0; // Approximate height of TTS controls
    final volumeControlHeight = _showVolumeControl ? 70.0 : 0.0;
    final bottomPosition = bottomPadding + ttsControlsHeight + volumeControlHeight + 20;
    
    print('🔊 Showing speech rate control at bottom: $bottomPosition, rate: $_ttsSpeechRate');
    
    return Positioned(
      bottom: bottomPosition,
      left: 10,
      right: 10,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _ttsSpeechRate < 0.3
                  ? Icons.speed
                  : _ttsSpeechRate < 0.5
                    ? Icons.slow_motion_video
                    : Icons.speed_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _ttsSpeechRate,
                  min: 0.3, // Minimum 30% speed
                  max: 1.0,
                  divisions: 14, // 0.3 to 1.0 in 0.05 increments (14 divisions)
                  activeColor: Colors.orange,
                  inactiveColor: Colors.white30,
                  label: '${(_ttsSpeechRate * 100).toInt()}%',
                  onChanged: (value) async {
                    setState(() {
                      _ttsSpeechRate = value;
                    });
                    if (_flutterTts != null) {
                      try {
                        await _flutterTts!.setSpeechRate(_ttsSpeechRate);
                        print('🔊 Speech rate changed to: $_ttsSpeechRate (${(_ttsSpeechRate * 100).toInt()}%)');
                        // If TTS is currently speaking, the rate will be applied on next sentence
                        // For immediate effect, we could stop and restart, but that's disruptive
                        // The rate will apply to the next sentence automatically
                      } catch (e) {
                        print('❌ Error setting speech rate: $e');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_ttsSpeechRate * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper function to convert technical voice name to user-friendly name
  String _getFriendlyVoiceName(String voiceName, int index) {
    final name = voiceName.toLowerCase();
    
    // Detect gender based on common TTS voice patterns
    // More accurate mapping based on actual TTS voice naming conventions
    bool isFemale = false;
    
    // Check for explicit gender indicators first
    if (name.contains('female') || name.contains('woman') || name.contains('girl') ||
        name.contains('samantha') || name.contains('susan') || name.contains('karen') ||
        name.contains('sarah') || name.contains('ava') || name.contains('salli') ||
        name.contains('joanna') || name.contains('ivy') || name.contains('kendra') ||
        name.contains('kimberly') || name.contains('emily') || name.contains('amy') ||
        name.contains('victoria') || name.contains('zira') || name.contains('helen')) {
      isFemale = true;
    } else if (name.contains('male') || name.contains('man') || name.contains('boy') ||
               name.contains('daniel') || name.contains('alex') || name.contains('aaron') ||
               name.contains('nick') || name.contains('tom') || name.contains('joey') ||
               name.contains('justin') || name.contains('kevin') || name.contains('matthew') ||
               name.contains('brian') || name.contains('russell') || name.contains('david') ||
               name.contains('mark') || name.contains('richard')) {
      isFemale = false;
    } else {
      // Check for common TTS voice patterns
      // Pattern: en-US-Neural2-A, en-US-Wavenet-C, etc.
      // Neural2: A, C, F = Female; D, J = Male
      // Wavenet: A, C, E, F = Female; B, D = Male
      // Standard: A, C, E, F, G = Female; B, D, H = Male
      
      // Check for Neural2 pattern
      if (name.contains('neural2')) {
        final neuralMatch = RegExp(r'neural2-([a-z])', caseSensitive: false).firstMatch(name);
        if (neuralMatch != null) {
          final letter = neuralMatch.group(1) ?? '';
          // Neural2: A, C, F are female; D, J are male
          isFemale = ['a', 'c', 'f'].contains(letter);
        }
      }
      // Check for Wavenet pattern
      else if (name.contains('wavenet')) {
        final waveMatch = RegExp(r'wavenet-([a-z])', caseSensitive: false).firstMatch(name);
        if (waveMatch != null) {
          final letter = waveMatch.group(1) ?? '';
          // Wavenet: A, C, E, F are female; B, D are male
          isFemale = ['a', 'c', 'e', 'f'].contains(letter);
        }
      }
      // Check for Standard pattern
      else if (name.contains('standard')) {
        final stdMatch = RegExp(r'standard-([a-z])', caseSensitive: false).firstMatch(name);
        if (stdMatch != null) {
          final letter = stdMatch.group(1) ?? '';
          // Standard: A, C, E, F, G are female; B, D, H are male
          isFemale = ['a', 'c', 'e', 'f', 'g'].contains(letter);
        }
      }
      // Check for pattern like -A, -C, etc. (general pattern)
      else {
        final dashMatch = RegExp(r'-([a-z])$', caseSensitive: false).firstMatch(name);
        if (dashMatch != null) {
          final letter = dashMatch.group(1) ?? '';
          // General rule: A, C, E, F, G, I are typically female; B, D, H, J are typically male
          if (['a', 'c', 'e', 'f', 'g', 'i'].contains(letter)) {
            isFemale = true;
          } else if (['b', 'd', 'h', 'j'].contains(letter)) {
            isFemale = false;
          } else {
            // For other letters, check last character
            final lastChar = name.isNotEmpty ? name[name.length - 1] : '';
            isFemale = ['a', 'c', 'e', 'f', 'g', 'i'].contains(lastChar);
          }
        } else {
          // Fallback: check last character
          final lastChar = name.isNotEmpty ? name[name.length - 1] : '';
          isFemale = ['a', 'c', 'e', 'f', 'g', 'i'].contains(lastChar);
        }
      }
    }
    
    // Use index + 1 for voice number (more reliable than parsing)
    final voiceNumber = index + 1;
    
    return isFemale ? 'Female Voice $voiceNumber' : 'Male Voice $voiceNumber';
  }
  
  Future<void> _showVoiceSelectionDialog() async {
    if (_availableVoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No voices available. Please wait for TTS to initialize.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Filter English voices only
    final englishVoices = _availableVoices.where((voice) {
      final locale = voice['locale']?.toLowerCase() ?? '';
      return locale.contains('en');
    }).toList();
    
    if (englishVoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No English voices available.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Map<String, String>? selectedVoice = _selectedVoice;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Voice'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: englishVoices.length,
              itemBuilder: (context, index) {
                final voice = englishVoices[index];
                final voiceName = voice['name'] ?? 'Unknown';
                final locale = voice['locale'] ?? 'Unknown';
                final friendlyName = _getFriendlyVoiceName(voiceName, index);
                final isSelected = selectedVoice != null &&
                    (selectedVoice!['name'] ?? '') == voiceName &&
                    (selectedVoice!['locale'] ?? '') == locale;
                
                // Debug: Log voice info for troubleshooting
                print('🔊 Voice $index: "$voiceName" -> "$friendlyName"');
                
                return ListTile(
                  title: Text(friendlyName),
                  subtitle: Text(locale),
                  selected: isSelected,
                  selectedTileColor: Colors.blue[50],
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  onTap: () {
                    setDialogState(() {
                      selectedVoice = voice;
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedVoice != null && _flutterTts != null) {
                  try {
                    final voiceName = selectedVoice!['name'] ?? 'Unknown';
                    final voiceLocale = selectedVoice!['locale'] ?? 'en-US';
                    
                    await _flutterTts!.setVoice({
                      'name': voiceName,
                      'locale': voiceLocale,
                    });
                    
                    setState(() {
                      _selectedVoice = selectedVoice;
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Voice changed to: $voiceName'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    print('🔊 ✅ Voice changed to: $voiceName ($voiceLocale)');
                  } catch (e) {
                    print('❌ Error setting voice: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error changing voice: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
                
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Select'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _extractTextFromPage(int pageNumber) async {
    if (_localPath == null) return '';
    
    try {
      final file = File(_localPath!);
      final bytes = await file.readAsBytes();
      
      // Load PDF document using Syncfusion
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      if (pageNumber >= document.pages.count) {
        document.dispose();
        return '';
      }
      
      // Extract text from the page using PdfTextExtractor
      final textExtractor = PdfTextExtractor(document);
      final extractedText = textExtractor.extractText(startPageIndex: pageNumber, endPageIndex: pageNumber);
      
      document.dispose();
      return extractedText;
    } catch (e) {
      print('Error extracting text from page $pageNumber: $e');
      return '';
    }
  }

  Future<void> _extractYouTubeLinksFromPDF() async {
    if (_localPath == null || _totalPages == 0) return;
    
    setState(() {
      _isExtractingLinks = true;
    });
    
    try {
      final file = File(_localPath!);
      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final textExtractor = PdfTextExtractor(document);
      
      Map<int, List<String>> linksByPage = {};
      
      // Extract text from all pages and find YouTube links
      for (int i = 0; i < _totalPages; i++) {
        try {
          final text = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
          
          // Extract YouTube links from text
          final links = _extractYouTubeLinksFromText(text);
          
          if (links.isNotEmpty) {
            linksByPage[i] = links;
            print('Found ${links.length} YouTube link(s) on page ${i + 1}');
          }
        } catch (e) {
          print('Error extracting links from page $i: $e');
        }
      }
      
      document.dispose();
      
      if (mounted) {
        setState(() {
          _youtubeLinksByPage = linksByPage;
          _isExtractingLinks = false;
        });
        
        if (linksByPage.isNotEmpty) {
          final totalLinks = linksByPage.values.fold<int>(0, (sum, list) => sum + list.length);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found $totalLinks YouTube video(s) in this module'),
              backgroundColor: AppColors.primaryBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error extracting YouTube links: $e');
      if (mounted) {
        setState(() {
          _isExtractingLinks = false;
        });
      }
    }
  }

  List<String> _extractYouTubeLinksFromText(String text) {
    if (text.isEmpty) return [];
    
    // More comprehensive regex to find YouTube URLs (various formats)
    // This pattern matches:
    // - https://www.youtube.com/watch?v=VIDEO_ID
    // - https://youtube.com/watch?v=VIDEO_ID
    // - http://www.youtube.com/watch?v=VIDEO_ID
    // - https://youtu.be/VIDEO_ID
    // - www.youtube.com/watch?v=VIDEO_ID
    // - youtube.com/watch?v=VIDEO_ID
    final youtubeRegex = RegExp(
      r'(?:https?://)?(?:www\.)?(?:m\.)?(?:youtube\.com/(?:watch\?v=|embed/|v/)|youtu\.be/)([a-zA-Z0-9_-]{11})(?:[?&][^\s]*)?',
      caseSensitive: false,
    );
    
    final matches = youtubeRegex.allMatches(text);
    final Set<String> uniqueLinks = {};
    
    print('🔍 Searching for YouTube links in text (length: ${text.length})');
    print('🔍 Found ${matches.length} potential match(es)');
    
    for (final match in matches) {
      String videoUrl;
      final fullMatch = match.group(0)!;
      final videoId = match.group(1)!;
      
      print('🔍 Processing match: $fullMatch (videoId: $videoId)');
      
      if (fullMatch.contains('youtu.be')) {
        videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      } else if (fullMatch.contains('youtube.com/embed/')) {
        videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      } else if (fullMatch.startsWith('http')) {
        // Keep the full URL but normalize it
        videoUrl = fullMatch.split('&').first;
        // Ensure it has the proper format
        if (!videoUrl.contains('watch?v=')) {
          videoUrl = 'https://www.youtube.com/watch?v=$videoId';
        }
      } else {
        videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      }
      
      uniqueLinks.add(videoUrl);
      print('✅ Added YouTube link: $videoUrl');
    }
    
    if (uniqueLinks.isEmpty && text.contains('youtube') || text.contains('youtu.be')) {
      print('⚠️ Text contains "youtube" but no links were extracted. Text sample: ${text.length > 100 ? text.substring(0, 100) : text}');
    }
    
    return uniqueLinks.toList();
  }

  Future<void> _extractYouTubeLinksFromDOCX() async {
    if (_localPath == null) {
      print('❌ Cannot extract links: _localPath is null');
      return;
    }
    
    print('🔍 Starting YouTube link extraction from DOCX...');
    setState(() {
      _isExtractingLinks = true;
    });
    
    try {
      final file = File(_localPath!);
      
      if (!await file.exists()) {
        print('❌ File does not exist: $_localPath');
        if (mounted) {
          setState(() {
            _isExtractingLinks = false;
          });
        }
        return;
      }
      
      final bytes = await file.readAsBytes();
      print('📄 DOCX file size: ${bytes.length} bytes');
      
      // Extract text from DOCX file
      String text;
      try {
        // DOCX is a ZIP archive containing XML files
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Find and read the main document XML (word/document.xml)
        ArchiveFile? documentXml;
        for (final file in archive) {
          if (file.name == 'word/document.xml') {
            documentXml = file;
            break;
          }
        }
        
        if (documentXml == null) {
          print('❌ Could not find word/document.xml in DOCX file');
          if (mounted) {
            setState(() {
              _isExtractingLinks = false;
            });
          }
          return;
        }
        
        // Decompress and parse the XML
        final xmlContent = utf8.decode(documentXml.content as List<int>);
        final document = xml.XmlDocument.parse(xmlContent);
        
        // Extract text from paragraphs to preserve structure
        final paragraphs = document.findAllElements('w:p');
        final textBuffer = StringBuffer();
        
        for (final paragraph in paragraphs) {
          final paraTextNodes = paragraph.findAllElements('w:t');
          final paraBuffer = StringBuffer();
          
          for (final node in paraTextNodes) {
            final nodeText = node.text;
            if (nodeText.isNotEmpty) {
              paraBuffer.write(nodeText);
            }
          }
          
          final paraText = paraBuffer.toString().trim();
          if (paraText.isNotEmpty) {
            textBuffer.write(paraText);
            textBuffer.write('\n\n'); // Add double newline between paragraphs
          }
        }
        
        text = textBuffer.toString().trim();
        
        // Clean up extra whitespace but preserve paragraph breaks
        text = text.replaceAll(RegExp(r'[ \t]+'), ' '); // Multiple spaces/tabs to single space
        text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n'); // More than 2 newlines to double newline
        
        // Remove XML artifacts if any
        text = text.replaceAll(RegExp(r'<[^>]+>'), ''); // Remove any remaining XML tags
        
        // Final cleanup
        text = text.trim();
        
        print('📝 Extracted text length: ${text.length} characters');
        if (text.isNotEmpty && text.length > 50) {
          print('📝 Sample text (first 200 chars): ${text.substring(0, text.length > 200 ? 200 : text.length)}');
        }
      } catch (e, stackTrace) {
        print('❌ Error extracting text during link extraction: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          setState(() {
            _isExtractingLinks = false;
          });
        }
        return;
      }
      
      if (text.isEmpty) {
        print('⚠️ No text found in DOCX');
        if (mounted) {
          setState(() {
            _isExtractingLinks = false;
          });
        }
        return;
      }
      
      // Extract YouTube links from text
      final links = _extractYouTubeLinksFromText(text);
      print('🎥 Found ${links.length} YouTube link(s)');
      
      if (links.isNotEmpty) {
        print('✅ YouTube links found: $links');
      }
      
      if (mounted) {
        setState(() {
          // For DOCX, we treat it as a single "page" (page 0)
          // Videos will be embedded inline, so don't show side panel
          if (links.isNotEmpty) {
            _youtubeLinksByPage[0] = links;
            _totalPages = 1; // DOCX is treated as single page
            // Don't auto-show panel for DOCX - videos are embedded inline
            // _showVideoPanel remains false for DOCX files
          }
          _isExtractingLinks = false;
        });
        
        if (links.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${links.length} YouTube video(s) in this document'),
              backgroundColor: AppColors.primaryBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          print('ℹ️ No YouTube links found in document');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error extracting YouTube links from DOCX: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isExtractingLinks = false;
        });
      }
    }
  }

  List<String> _splitIntoTopics(String text) {
    // Split text into topics based on headings and major sections
    List<String> topics = [];
    
    // Split by double newlines (paragraph breaks)
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    
    String currentTopic = '';
    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      
      // Check if this paragraph is a heading (short, all caps, or ends with colon)
      final isHeading = _isHeading(trimmed, currentTopic.isEmpty);
      
      if (isHeading && currentTopic.isNotEmpty) {
        // Save current topic and start new one
        topics.add(currentTopic.trim());
        currentTopic = trimmed + '\n\n';
      } else {
        // Add to current topic
        if (currentTopic.isNotEmpty) {
          currentTopic += '\n\n';
        }
        currentTopic += trimmed;
      }
    }
    
    // Add the last topic
    if (currentTopic.trim().isNotEmpty) {
      topics.add(currentTopic.trim());
    }
    
    // If no topics found (no headings), split by large chunks (max 2000 chars)
    if (topics.isEmpty) {
      const maxChunkSize = 2000;
      for (int i = 0; i < text.length; i += maxChunkSize) {
        final end = (i + maxChunkSize < text.length) ? i + maxChunkSize : text.length;
        topics.add(text.substring(i, end).trim());
      }
    }
    
    print('📚 Split text into ${topics.length} topics');
    return topics;
  }

  Future<void> _startTts() async {
    print('🔊 _startTts called');
    print('🔊 _localPath: $_localPath');
    print('🔊 _flutterTts: ${_flutterTts != null}');
    print('🔊 _isTtsInitialized: $_isTtsInitialized');
    print('🔊 _isSpeaking: $_isSpeaking');
    
    // If already speaking, stop first
    if (_isSpeaking) {
      print('🔊 Already speaking, stopping first...');
      await _stopTts();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (_localPath == null) {
      print('❌ _localPath is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Module file is not loaded yet. Please wait.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_flutterTts == null || !_isTtsInitialized) {
      print('❌ TTS is not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text-to-speech is not ready. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // If there's selected text, use it; otherwise extract from document
    if (_hasSelectedText && _selectedText.isNotEmpty) {
      print('🔊 Using selected text (length: ${_selectedText.length})');
      _startTtsWithText(_selectedText);
      return;
    }
    
    setState(() {
      _isExtractingText = true;
      _currentSpeakingPage = _currentPage;
    });

    try {
      String text;
      final fileExtension = widget.module['fileExtension']?.toString().toLowerCase() ?? '';
      print('🔊 File extension: $fileExtension');
      print('🔊 _localPath ends with .docx: ${_localPath?.endsWith('.docx')}');
      
      // Check if it's a DOCX file
      if (fileExtension == 'docx' || fileExtension == 'doc' || 
          _localPath?.endsWith('.docx') == true || _localPath?.endsWith('.doc') == true) {
        print('🔊 Extracting text from DOCX file...');
        // Extract text from DOCX file
        text = await _extractTextFromDOCX();
        print('🔊 DOCX text extracted: ${text.length} characters');
      } else {
        print('🔊 Extracting text from PDF page $_currentPage...');
        // For PDF files, extract from current page
        text = await _extractTextFromPage(_currentPage);
        print('🔊 PDF text extracted: ${text.length} characters');
      }
      
      if (text.isEmpty) {
        print('❌ Extracted text is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fileExtension == 'docx' || fileExtension == 'doc'
                ? 'No text found in document. Long press to select text manually.'
                : 'No text found on this page. Long press to select text manually.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isExtractingText = false;
        });
        return;
      }

      // Split text into topics
      _topics = _splitIntoTopics(text);
      _currentTopicIndex = 0;
      _isReadingByTopic = true;
      
      print('🔊 Starting TTS with ${_topics.length} topics');
      _readCurrentTopic();
    } catch (e, stackTrace) {
      print('❌ Error starting TTS: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading text: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isExtractingText = false;
        _isSpeaking = false;
      });
    }
  }

  Future<void> _readCurrentTopic() async {
    if (_currentTopicIndex >= _topics.length) {
      print('✅ All topics completed');
      setState(() {
        _isReadingByTopic = false;
        _currentTopicIndex = 0;
        _isSpeaking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finished reading all topics.'),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final topic = _topics[_currentTopicIndex];
    print('🔊 Reading topic ${_currentTopicIndex + 1}/${_topics.length} (${topic.length} chars)');
    _startTtsWithText(topic, isTopic: true);
  }

  void _readNextTopic() async {
    if (_currentTopicIndex < _topics.length - 1) {
      // Clear current highlighting
      if (mounted) {
        setState(() {
          _currentSpeakingSentence = null;
        });
      }
      
      // Add longer pause before reading next topic (natural pause)
      print('🔊 Pausing for 4 seconds before reading next topic...');
      await Future.delayed(const Duration(seconds: 4));
      
      if (mounted && _isSpeaking) {
        setState(() {
          _currentTopicIndex++;
        });
        _readCurrentTopic();
      }
    }
  }

  void _readPreviousTopic() {
    if (_currentTopicIndex > 0) {
      setState(() {
        _currentTopicIndex--;
      });
      _readCurrentTopic();
    }
  }

  String _addPausesAtPeriods(String text) {
    // Split text into sentences and add longer pauses at periods
    // Use regex to split by sentence-ending punctuation followed by space
    final sentencePattern = RegExp(r'([.!?]+)\s+');
    final parts = text.split(sentencePattern);
    final result = StringBuffer();
    
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      
      result.write(part);
      
      // If this part is punctuation (period, exclamation, question mark)
      if (sentencePattern.hasMatch(part) || part.endsWith('.') || part.endsWith('!') || part.endsWith('?')) {
        // Add multiple spaces and newlines to create a longer pause
        // TTS engines pause longer with more whitespace
        result.write('\n\n   '); // Newline + spaces for noticeable pause
      } else if (i < parts.length - 1 && !parts[i + 1].isEmpty) {
        // Check if next part starts with punctuation
        final nextPart = parts[i + 1];
        if (!nextPart.startsWith('.') && !nextPart.startsWith('!') && !nextPart.startsWith('?')) {
          result.write(' ');
        }
      }
    }
    
    return result.toString();
  }

  /// Read content boxes sequentially with 2-second pause between each box
  Future<void> _readContentBoxesSequentially(List<String> contentBoxes) async {
    if (contentBoxes.isEmpty) {
      print('❌ No content boxes to read');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
      return;
    }
    
    print('🔊 Starting to read ${contentBoxes.length} content box(es)');
    
    // Set up completion handler
    Completer<void>? boxCompleter;
    _flutterTts!.setCompletionHandler(() {
      print('🔊 Box TTS completed');
      if (boxCompleter != null && !boxCompleter!.isCompleted) {
        boxCompleter!.complete();
      }
    });
    
    // Read each box sequentially
    for (int i = 0; i < contentBoxes.length; i++) {
      if (!mounted || !_isSpeaking) {
        print('🔊 Stopping box reading (mounted: $mounted, speaking: $_isSpeaking)');
        break;
      }
      
      final boxText = contentBoxes[i].trim();
      if (boxText.isEmpty) continue;
      
      print('🔊 Reading box ${i + 1}/${contentBoxes.length} (${boxText.length} chars)');
      
      // Clean the box text
      String cleanBoxText = boxText
          .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
          .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Multiple newlines to double newline
          .trim();
      
      // Limit box text length
      const maxBoxLength = 4000;
      if (cleanBoxText.length > maxBoxLength) {
        print('⚠️ Box ${i + 1} is too long, truncating');
        cleanBoxText = cleanBoxText.substring(0, maxBoxLength) + '...';
      }
      
      // Update extracted text for display
      if (mounted) {
        setState(() {
          _extractedText = cleanBoxText;
        });
      }
      
      // Stop any existing speech
      try {
        await _flutterTts!.stop();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        print('⚠️ Error stopping TTS: $e');
      }
      
      // Apply current speech rate
      try {
        await _flutterTts!.setSpeechRate(_ttsSpeechRate);
      } catch (e) {
        print('⚠️ Error setting speech rate: $e');
      }
      
      // Create completer for this box
      boxCompleter = Completer<void>();
      
      // Speak the box
      final result = await _flutterTts!.speak(cleanBoxText);
      
      if (result != 1) {
        print('⚠️ Error speaking box: $result');
        if (result == -8) {
          // TTS busy, wait and retry
          await Future.delayed(const Duration(seconds: 1));
          final retryResult = await _flutterTts!.speak(cleanBoxText);
          if (retryResult != 1) {
            print('❌ Failed to speak box after retry');
            break;
          }
        } else {
          break;
        }
      }
      
      // Wait for box to complete
      try {
        await boxCompleter.future.timeout(
          const Duration(seconds: 30), // Max 30 seconds per box
          onTimeout: () {
            print('⚠️ Box ${i + 1} timeout (30s), moving to next');
          },
        );
        print('🔊 Box ${i + 1} completed successfully');
      } catch (e) {
        print('⚠️ Error waiting for box completion: $e');
      }
      
      // 2-second pause before next box (except for the last box)
      if (i < contentBoxes.length - 1 && mounted && _isSpeaking) {
        print('🔊 Pausing for 2 seconds before next box...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    // Clear when done
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _extractedText = '';
      });
    }
    
    // Restore original completion handler
    _flutterTts!.setCompletionHandler(() {
      print('🔊 TTS completed');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
      }
    });
    
    print('🔊 Finished reading all content boxes');
  }

  Future<void> _readTextBySentences(String text) async {
    // Split text into sentences and speak them one by one with pauses
    // Use regex to properly split sentences
    final sentenceEndings = RegExp(r'([.!?]+)\s*');
    final sentences = <String>[];
    
    // Split by sentence endings but keep the punctuation
    int lastIndex = 0;
    for (final match in sentenceEndings.allMatches(text)) {
      final sentence = text.substring(lastIndex, match.end).trim();
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
      lastIndex = match.end;
    }
    
    // Add remaining text if any
    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        sentences.add(remaining);
      }
    }
    
    // If no sentences found, use original text
    if (sentences.isEmpty) {
      sentences.add(text);
    }
    
    print('🔊 Split text into ${sentences.length} sentence(s) for natural reading');
    
    // Create a completer to wait for each sentence to complete
    Completer<void>? sentenceCompleter;
    
    // Set up a temporary completion handler for sentence-by-sentence reading
    _flutterTts!.setCompletionHandler(() {
      print('🔊 Sentence TTS completed');
      if (sentenceCompleter != null && !sentenceCompleter!.isCompleted) {
        sentenceCompleter!.complete();
      }
    });
    
    // Speak each sentence with a pause between them
    for (int i = 0; i < sentences.length; i++) {
      if (!mounted || !_isSpeaking) {
        print('🔊 Stopping sentence reading (mounted: $mounted, speaking: $_isSpeaking)');
        break;
      }
      
      final sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;
      
      print('🔊 Speaking sentence ${i + 1}/${sentences.length}: ${sentence.length > 60 ? sentence.substring(0, 60) + "..." : sentence}');
      
      // Update current speaking sentence for highlighting (force rebuild)
      if (mounted) {
        setState(() {
          _currentSpeakingSentence = sentence.trim();
        });
        // Force another setState to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _currentSpeakingSentence = sentence.trim();
          });
        }
      }
      
      // Stop any existing speech first
      try {
        await _flutterTts!.stop();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('⚠️ Error stopping TTS: $e');
      }
      
      // Apply current speech rate before each sentence (so changes take effect immediately)
      try {
        await _flutterTts!.setSpeechRate(_ttsSpeechRate);
        print('🔊 Applied speech rate: $_ttsSpeechRate (${(_ttsSpeechRate * 100).toInt()}%)');
      } catch (e) {
        print('⚠️ Error setting speech rate: $e');
      }
      
      // Create new completer for this sentence
      sentenceCompleter = Completer<void>();
      
      // Speak the sentence
      final result = await _flutterTts!.speak(sentence);
      
      if (result != 1) {
        print('⚠️ Error speaking sentence: $result');
        if (result == -8) {
          // TTS busy, wait and retry
          await Future.delayed(const Duration(seconds: 1));
          final retryResult = await _flutterTts!.speak(sentence);
          if (retryResult != 1) {
            print('❌ Failed to speak sentence after retry');
            break;
          }
        } else {
          break;
        }
      }
      
      // Wait for sentence to complete using completer
      // Set a timeout of 15 seconds per sentence (for long sentences)
      try {
        await sentenceCompleter.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⚠️ Sentence ${i + 1} timeout (15s), moving to next');
          },
        );
        print('🔊 Sentence ${i + 1} completed successfully');
      } catch (e) {
        print('⚠️ Error waiting for sentence completion: $e');
      }
      
      // Clear highlighting during pause
      if (i < sentences.length - 1 && mounted && _isSpeaking) {
        setState(() {
          _currentSpeakingSentence = null;
        });
        print('🔊 Pausing for 2 seconds after sentence ${i + 1}...');
        await Future.delayed(const Duration(seconds: 2)); // 2 second pause at each period
      }
    }
    
    // Clear highlighting when done
    if (mounted) {
      setState(() {
        _currentSpeakingSentence = null;
      });
    }
    
    // Restore original completion handler
    _flutterTts!.setCompletionHandler(() {
      print('🔊 TTS completed');
      if (mounted) {
        if (_isReadingByTopic && _currentTopicIndex < _topics.length - 1) {
          setState(() {
            _isPaused = false;
            _currentSpeakingSentence = null; // Clear highlight before pause
          });
          // Wait longer before reading next topic (pause is already in _readNextTopic)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _isSpeaking) {
              _readNextTopic();
            }
          });
        } else {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
            _isReadingByTopic = false;
            _currentTopicIndex = 0;
            _currentSpeakingSentence = null;
          });
        }
      }
    });
    
    print('🔊 Finished reading all sentences');
  }
  
  // Build text widget with highlighting support
  Widget _buildHighlightableText(String text, {
    TextStyle? style,
    TextAlign textAlign = TextAlign.justify,
  }) {
    // If no sentence is being spoken, use regular SelectableText
    if (_currentSpeakingSentence == null || !_isSpeaking) {
      return SelectableText(
        text,
        style: style,
        textAlign: textAlign,
      );
    }
    
    // Check if this text contains the current speaking sentence
    final sentence = _currentSpeakingSentence!.trim();
    if (sentence.isEmpty) {
      return SelectableText(
        text,
        style: style,
        textAlign: textAlign,
      );
    }
    
    // Try exact match first
    int sentenceIndex = text.indexOf(sentence);
    
    // If not found, try case-insensitive match
    if (sentenceIndex == -1) {
      final lowerText = text.toLowerCase();
      final lowerSentence = sentence.toLowerCase();
      final lowerIndex = lowerText.indexOf(lowerSentence);
      if (lowerIndex != -1) {
        sentenceIndex = lowerIndex;
      }
    }
    
    // If still not found, try matching without extra whitespace
    if (sentenceIndex == -1) {
      final normalizedSentence = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
      final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      sentenceIndex = normalizedText.indexOf(normalizedSentence);
      if (sentenceIndex != -1) {
        // Find the actual position in original text
        int charCount = 0;
        for (int i = 0; i < text.length; i++) {
          if (text[i].trim().isNotEmpty || normalizedText.contains(text[i])) {
            if (charCount == sentenceIndex) {
              sentenceIndex = i;
              break;
            }
            charCount++;
          }
        }
      }
    }
    
    if (sentenceIndex == -1) {
      // Sentence not in this text, return regular text
      return SelectableText(
        text,
        style: style,
        textAlign: textAlign,
      );
    }
    
    // Build RichText with highlighting
    final beforeText = text.substring(0, sentenceIndex);
    final highlightedText = text.substring(sentenceIndex, sentenceIndex + sentence.length);
    final afterText = text.substring(sentenceIndex + sentence.length);
    
    return SelectableText.rich(
      TextSpan(
        children: [
          if (beforeText.isNotEmpty)
            TextSpan(
              text: beforeText,
              style: style,
            ),
          TextSpan(
            text: highlightedText,
            style: (style ?? const TextStyle()).copyWith(
              backgroundColor: Colors.yellow[300],
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          if (afterText.isNotEmpty)
            TextSpan(
              text: afterText,
              style: style,
            ),
        ],
      ),
      textAlign: textAlign,
    );
  }

  Future<void> _startTtsWithText(String text, {bool isTopic = false}) async {
    print('🔊 _startTtsWithText called');
    print('🔊 Use Cloud TTS: $_useCloudTts');
    print('🔊 _flutterTts is null: ${_flutterTts == null}');
    print('🔊 _cloudTts is null: ${_cloudTts == null}');
    print('🔊 text.isEmpty: ${text.isEmpty}');
    print('🔊 text length: ${text.length}');
    print('🔊 _isSpeaking: $_isSpeaking');
    print('🔊 text preview: ${text.length > 100 ? text.substring(0, 100) : text}');
    
    // Use Cloud TTS if enabled and configured
    if (_useCloudTts && _cloudTts != null && _cloudTts!.isConfigured()) {
      await _startCloudTts(text, isTopic: isTopic);
      return;
    }
    
    // Fallback to FlutterTts
    if (_flutterTts == null) {
      print('❌ TTS is not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text-to-speech is not initialized. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isExtractingText = false;
        _isSpeaking = false;
      });
      return;
    }
    
    if (text.isEmpty) {
      print('❌ Text is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No text to read. Please select text or ensure document has content.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isExtractingText = false;
        _isSpeaking = false;
      });
      return;
    }
    
    try {
      // Stop any existing TTS before starting new one
      if (_isSpeaking) {
        print('🔊 Stopping existing TTS before starting new one');
        await _flutterTts!.stop();
        await Future.delayed(const Duration(milliseconds: 300)); // Wait a bit for TTS to stop
      }
      
      // Split text into content boxes/blocks (by double newlines - paragraphs)
      final contentBoxes = text.split('\n\n').where((box) => box.trim().isNotEmpty).toList();
      print('🔊 Split text into ${contentBoxes.length} content box(es)');
      
      setState(() {
        _isExtractingText = false;
        _isSpeaking = true;
        _isPaused = false;
      });
      
      // Read each box with 7-second pause between them
      await _readContentBoxesSequentially(contentBoxes);
    } catch (e, stackTrace) {
      print('❌ Error in _startTtsWithText: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isExtractingText = false;
          _isSpeaking = false;
          _isPaused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading text: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseTts() async {
    if (_flutterTts != null) {
      await _flutterTts!.pause();
      if (mounted) {
        setState(() {
          _isPaused = true;
        });
      }
    }
  }

  Future<void> _resumeTts() async {
    if (_flutterTts != null) {
      await _flutterTts!.speak(_extractedText);
      if (mounted) {
        setState(() {
          _isPaused = false;
        });
      }
    }
  }

  Future<void> _stopTts() async {
    print('🔊 _stopTts called');
    
    // Stop Cloud TTS if using it
    if (_useCloudTts && _cloudTts != null) {
      try {
        await _cloudTts!.stop();
        print('🔊 Cloud TTS stopped');
      } catch (e) {
        print('⚠️ Error stopping Cloud TTS: $e');
      }
    }
    
    // Stop FlutterTts
    if (_flutterTts != null) {
      try {
        // Stop multiple times to ensure it's fully stopped
        for (int i = 0; i < 3; i++) {
          try {
            await _flutterTts!.stop();
            await Future.delayed(const Duration(milliseconds: 150));
          } catch (e) {
            print('⚠️ Error stopping TTS (attempt ${i + 1}): $e');
          }
        }
        print('🔊 TTS stopped successfully');
      } catch (e) {
        print('❌ Error stopping TTS: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _isTtsBusy = false;
        _extractedText = '';
        _currentSpeakingSentence = null; // Clear highlighting
      });
    }
  }
  
  Future<void> _startCloudTts(String text, {bool isTopic = false}) async {
    print('🔊 Starting Cloud TTS...');
    
    if (_cloudTts == null || !_cloudTts!.isConfigured()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud TTS is not configured. Please set your API key in settings.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _isExtractingText = false;
        _isSpeaking = false;
      });
      return;
    }
    
    setState(() {
      _isSpeaking = true;
      _isPaused = false;
      _isExtractingText = false;
    });
    
    try {
      // Clean text
      String cleanText = text
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      
      // Split into sentences for natural pauses
      final sentenceEndings = RegExp(r'([.!?]+)\s*');
      final sentences = <String>[];
      int lastIndex = 0;
      
      for (final match in sentenceEndings.allMatches(cleanText)) {
        final sentence = cleanText.substring(lastIndex, match.end).trim();
        if (sentence.isNotEmpty) {
          sentences.add(sentence);
        }
        lastIndex = match.end;
      }
      
      if (lastIndex < cleanText.length) {
        final remaining = cleanText.substring(lastIndex).trim();
        if (remaining.isNotEmpty) {
          sentences.add(remaining);
        }
      }
      
      if (sentences.isEmpty) {
        sentences.add(cleanText);
      }
      
      print('🔊 Cloud TTS: Split into ${sentences.length} sentence(s)');
      
      // Speak each sentence with pauses
      for (int i = 0; i < sentences.length; i++) {
        if (!mounted || !_isSpeaking) break;
        
        final sentence = sentences[i].trim();
        if (sentence.isEmpty) continue;
        
        print('🔊 Cloud TTS: Speaking sentence ${i + 1}/${sentences.length}');
        
        // Update current speaking sentence for highlighting (force rebuild)
        if (mounted) {
          setState(() {
            _currentSpeakingSentence = sentence.trim();
          });
          // Force another setState to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) {
            setState(() {
              _currentSpeakingSentence = sentence.trim();
            });
          }
        }
        
        await _cloudTts!.speak(
          sentence,
          volume: _ttsVolume,
          speed: 0.8, // Slower speed for natural reading
          speakingRate: 0.8, // Slower speaking rate
          pitch: 0.0,
        );
        
        // Wait for audio to finish
        while (_cloudTts!.isPlaying && _isSpeaking && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Clear highlighting during pause
        if (i < sentences.length - 1 && _isSpeaking && mounted) {
          setState(() {
            _currentSpeakingSentence = null;
          });
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _currentSpeakingSentence = null; // Clear highlighting
        });
      }
    } catch (e) {
      print('❌ Cloud TTS Error: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _currentSpeakingSentence = null; // Clear highlighting
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error with Cloud TTS: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showCloudTtsSettingsDialog() async {
    final apiKeyController = TextEditingController(
      text: _cloudTts?.getApiKey() ?? '',
    );
    String selectedVoice = _cloudTts?.getVoice() ?? 'en-US-Neural2-D';
    bool useCloudTts = _useCloudTts;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('TTS Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TTS Provider Selection
                const Text(
                  'TTS Provider:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RadioListTile<bool>(
                  title: const Text('Device TTS (FlutterTts)'),
                  subtitle: const Text('Free, works offline'),
                  value: false,
                  groupValue: useCloudTts,
                  onChanged: (value) {
                    setDialogState(() {
                      useCloudTts = value ?? false;
                    });
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Cloud TTS (Google)'),
                  subtitle: const Text('Natural, human-like voices (requires API key)'),
                  value: true,
                  groupValue: useCloudTts,
                  onChanged: (value) {
                    setDialogState(() {
                      useCloudTts = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Cloud TTS Settings (only show if Cloud TTS is selected)
                if (useCloudTts) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Google Cloud TTS API Key:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: apiKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'AIza...',
                      border: OutlineInputBorder(),
                      helperText: 'Get your API key from console.cloud.google.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Voice Selection
                  const Text(
                    'Voice:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedVoice,
                    items: CloudTtsService.googleVoices.map((voice) {
                      return DropdownMenuItem(
                        value: voice['name'],
                        child: Text(voice['label'] ?? voice['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedVoice = value ?? 'en-US-Neural2-D';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save settings
                setState(() {
                  _useCloudTts = useCloudTts;
                });
                
                if (useCloudTts && _cloudTts != null) {
                  // Set API key
                  if (apiKeyController.text.isNotEmpty) {
                    await _cloudTts!.setApiKey(apiKeyController.text.trim());
                  }
                  
                  // Set voice
                  await _cloudTts!.setVoice(selectedVoice);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _cloudTts!.isConfigured()
                              ? 'Cloud TTS configured successfully!'
                              : 'Warning: API key not set. Cloud TTS will not work.',
                        ),
                        backgroundColor: _cloudTts!.isConfigured()
                            ? Colors.green
                            : Colors.orange,
                      ),
                    );
                  }
                }
                
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop TTS if speaking (without setState)
    if (_flutterTts != null) {
      _flutterTts!.stop();
      _flutterTts = null;
    }
    
    // Stop Cloud TTS
    _cloudTts?.stop();
    _cloudTts?.dispose();
    
    // Dispose video controllers
    _youtubeController?.dispose();
    _videoController?.dispose();
    
    // Dispose inline YouTube controllers
    for (final controller in _inlineYoutubeControllers.values) {
      controller.dispose();
    }
    _inlineYoutubeControllers.clear();
    
    // Clean up temporary file
    if (_localPath != null) {
      try {
        final file = File(_localPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print('Error deleting temp file: $e');
      }
    }
    super.dispose();
  }
}

