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
import 'dart:convert' show utf8;
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/text_styles.dart';

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
  bool _isTtsBusy = false; // Track if TTS is busy
  
  // Topic-based TTS variables
  List<String> _topics = []; // List of topics/sections
  int _currentTopicIndex = 0; // Current topic being read
  bool _isReadingByTopic = false; // Whether reading by topic mode
  
  // Text selection variables
  String _selectedText = '';
  bool _hasSelectedText = false;
  
  // Video player variables
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  // YouTube links detected in PDF
  Map<int, List<String>> _youtubeLinksByPage = {}; // Page number -> List of YouTube URLs
  bool _isExtractingLinks = false;
  bool _showVideoPanel = true;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadModule();
    _initializeVideo();
  }
  
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
      
      // Set TTS parameters
      await _flutterTts!.setLanguage("en-US");
      await _flutterTts!.setSpeechRate(0.5); // Normal speed
      await _flutterTts!.setVolume(_ttsVolume);
      await _flutterTts!.setPitch(1.0);
      
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
              backgroundColor: Colors.red,
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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.module['title'] ?? 'Module',
          style: const TextStyle(color: Colors.white),
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
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          // TTS control button
          if (_isTtsInitialized && _localPath != null)
            IconButton(
              icon: Icon(
                _isSpeaking ? Icons.stop : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: _isSpeaking ? _stopTts : _startTts,
              tooltip: _isSpeaking ? 'Stop reading' : (_hasSelectedText ? 'Read selected text' : 'Read aloud'),
            ),
          // Text selection button
          if (_isTtsInitialized && _localPath != null)
            IconButton(
              icon: Icon(
                _hasSelectedText ? Icons.text_fields : Icons.text_fields_outlined,
                color: Colors.white,
              ),
              onPressed: _showTextSelectionDialog,
              tooltip: _hasSelectedText ? 'Change selected text' : 'Select text to read',
            ),
          // Video panel toggle button
          if (_youtubeLinksByPage.isNotEmpty)
            IconButton(
              icon: Icon(
                _showVideoPanel ? Icons.video_library : Icons.video_library_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showVideoPanel = !_showVideoPanel;
                });
              },
              tooltip: _showVideoPanel ? 'Hide videos' : 'Show videos',
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
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
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
          style: TextStyle(color: Colors.white),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading video...',
                style: TextStyle(color: Colors.white),
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'File type: ${fileExtension.toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please download the file to view it',
              style: TextStyle(color: Colors.grey),
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
    final widgets = <Widget>[];

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      
      if (paragraph.isEmpty) continue;

      // Detect headings (short lines, all caps, or lines ending with colon)
      final isHeading = _isHeading(paragraph, i == 0);
      
      if (isHeading) {
        // Heading style
        widgets.add(
          Container(
            margin: EdgeInsets.only(
              top: i > 0 ? 32 : 0,
              bottom: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: AppColors.primaryBlue,
                  width: 4,
                ),
              ),
            ),
            child: SelectableText(
              paragraph,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (_isListItem(paragraph)) {
        // List item style
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    paragraph.replaceFirst(RegExp(r'^[\d\.\-\•]\s*'), ''),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (_isTableRow(paragraph)) {
        // Table row style
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              paragraph,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      } else {
        // Regular paragraph style
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: SelectableText(
              paragraph,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      }

      // Add divider after major sections
      if (isHeading && i < paragraphs.length - 1) {
        widgets.add(
          Divider(
            height: 32,
            thickness: 1,
            color: Colors.grey[300],
            indent: 0,
            endIndent: 0,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
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
    // Check if text contains multiple tabs or multiple spaces (likely table)
    return text.contains('\t') || 
           (text.split(RegExp(r'\s{3,}')).length > 2 && text.length < 200);
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
    
    final hasVideos = _showVideoPanel && 
        _youtubeLinksByPage.isNotEmpty && 
        _youtubeLinksByPage.containsKey(0);
    
    return FutureBuilder<String>(
      future: _extractTextFromDOCX(),
      builder: (context, snapshot) {
        print('🔵 FutureBuilder state: ${snapshot.connectionState}');
        print('🔵 FutureBuilder hasError: ${snapshot.hasError}');
        print('🔵 FutureBuilder hasData: ${snapshot.hasData}');
        if (snapshot.hasData) {
          print('🔵 FutureBuilder data length: ${snapshot.data?.length ?? 0}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔵 Showing loading indicator...');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading document...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          print('❌ Error in FutureBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading document:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
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
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
        
        // Check if we have data
        if (!snapshot.hasData) {
          print('⚠️ FutureBuilder has no data');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading document content...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }
        
        final text = snapshot.data ?? '';
        print('✅ DOCX text extracted: ${text.length} characters');
        print('🔵 Text preview (first 100 chars): ${text.length > 100 ? text.substring(0, 100) : text}');
        
        if (text.isEmpty || text.startsWith('Error')) {
          print('⚠️ Text is empty or has error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'No content found in document',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  text.isEmpty ? 'The document appears to be empty.' : text,
                  style: const TextStyle(color: Colors.grey),
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
        
        print('🔵 Rendering document with text length: ${text.length}');
        print('🔵 hasVideos: $hasVideos');
        print('🔵 _showVideoPanel: $_showVideoPanel');
        print('🔵 _youtubeLinksByPage: $_youtubeLinksByPage');
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Document content - adjust width if video panel is shown
            Positioned(
              left: 0,
              right: hasVideos ? 366 : 0,
              top: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: Colors.white,
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
                                      color: Colors.white,
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
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.module['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
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
                      _buildFormattedContent(text),
                      const SizedBox(height: 40), // Extra space at bottom
                    ],
                  ),
                ),
              ),
            ),
            // YouTube Links Panel
            if (hasVideos)
              _buildYouTubeLinksPanel(),
            // TTS Controls overlay
            if (_isTtsInitialized) ...[
              _buildVolumeControl(),
              Positioned(
                bottom: 20,
                left: 20,
                right: hasVideos ? 386 : 20,
                child: _buildTtsControls(),
              ),
            ],
          ],
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
    // For DOCX files, use page 0; for PDF, use current page
    final pageIndex = widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
                      widget.module['fileExtension']?.toString().toLowerCase() == 'doc'
        ? 0
        : _currentPage;
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
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
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
                  const Icon(Icons.video_library, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.module['fileExtension']?.toString().toLowerCase() == 'docx' || 
                      widget.module['fileExtension']?.toString().toLowerCase() == 'doc'
                          ? 'Videos in Document'
                          : 'Videos on Page ${_currentPage + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.black26,
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
                  color: Colors.black.withOpacity(0.3),
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
                                    bufferedColor: Colors.grey,
                                    backgroundColor: Colors.black26,
                                  ),
                                ),
                              ),
                              // Play/Pause button overlay
                              if (!_videoController!.value.isPlaying)
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_circle_filled,
                                    size: 64,
                                    color: Colors.white,
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
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  onPressed: _isPaused ? _resumeTts : _pauseTts,
                  tooltip: _isPaused ? 'Resume' : 'Pause',
                )
              else
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  color: Colors.white,
                  onPressed: _startTts,
                  tooltip: 'Read aloud',
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _isExtractingText
                      ? 'Extracting text...'
                      : _isSpeaking
                          ? (_isPaused 
                              ? 'Paused' 
                              : _isReadingByTopic 
                                  ? 'Reading topic ${_currentTopicIndex + 1}/${_topics.length}...'
                                  : _hasSelectedText 
                                      ? 'Reading selected text...' 
                                      : 'Reading page ${_currentSpeakingPage + 1}...')
                          : _hasSelectedText 
                              ? 'Tap to read selected text'
                              : 'Tap to read aloud (Long press to select text)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isSpeaking) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.stop),
                  color: Colors.white,
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
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _ttsVolume == 0.0 
                    ? Icons.volume_off 
                    : _ttsVolume < 0.5 
                      ? Icons.volume_down 
                      : Icons.volume_up,
                ),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    _showVolumeControl = !_showVolumeControl;
                  });
                },
                tooltip: 'Volume: ${(_ttsVolume * 100).toInt()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    if (!_showVolumeControl) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 90,
      left: 20,
      right: 20,
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
    // Regex to find YouTube URLs (various formats)
    final youtubeRegex = RegExp(
      r'(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    
    final matches = youtubeRegex.allMatches(text);
    final Set<String> uniqueLinks = {};
    
    for (final match in matches) {
      String videoUrl;
      if (match.group(0)!.contains('youtu.be')) {
        videoUrl = 'https://www.youtube.com/watch?v=${match.group(1)}';
      } else if (match.group(0)!.contains('youtube.com/embed/')) {
        videoUrl = 'https://www.youtube.com/watch?v=${match.group(1)}';
      } else if (match.group(0)!.startsWith('http')) {
        videoUrl = match.group(0)!;
      } else {
        videoUrl = 'https://www.youtube.com/watch?v=${match.group(1)}';
      }
      uniqueLinks.add(videoUrl);
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
          if (links.isNotEmpty) {
            _youtubeLinksByPage[0] = links;
            _totalPages = 1; // DOCX is treated as single page
            _showVideoPanel = true; // Auto-show panel if videos found
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

  void _readNextTopic() {
    if (_currentTopicIndex < _topics.length - 1) {
      setState(() {
        _currentTopicIndex++;
      });
      _readCurrentTopic();
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

  Future<void> _startTtsWithText(String text, {bool isTopic = false}) async {
    print('🔊 _startTtsWithText called');
    print('🔊 _flutterTts is null: ${_flutterTts == null}');
    print('🔊 text.isEmpty: ${text.isEmpty}');
    print('🔊 text length: ${text.length}');
    print('🔊 _isSpeaking: $_isSpeaking');
    print('🔊 text preview: ${text.length > 100 ? text.substring(0, 100) : text}');
    
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
      
      // Clean the text - remove excessive whitespace and special characters that might cause issues
      String cleanText = text
          .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
          .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Multiple newlines to double newline
          .trim();
      
      // Limit text length to avoid TTS errors (some TTS engines have limits)
      const maxTextLength = 4000; // Safe limit for most TTS engines
      if (cleanText.length > maxTextLength) {
        print('⚠️ Text is too long (${cleanText.length} chars), truncating to $maxTextLength');
        cleanText = cleanText.substring(0, maxTextLength) + '... [Text truncated]';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text is too long. Reading first 4000 characters.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      setState(() {
        _extractedText = cleanText;
        _isExtractingText = false;
        _isSpeaking = true;
        _isPaused = false;
      });

      print('🔊 Starting TTS with text length: ${cleanText.length}');
      
      // Check if TTS is already busy
      if (_isTtsBusy) {
        print('⚠️ TTS is already busy, waiting...');
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      // Ensure TTS is ready before speaking - with retry mechanism
      int retryCount = 0;
      const maxRetries = 5; // Increased retries
      bool success = false;
      
      setState(() {
        _isTtsBusy = true;
      });
      
      while (retryCount < maxRetries && !success) {
        try {
          print('🔊 TTS attempt ${retryCount + 1}/$maxRetries');
          
          // Stop any existing TTS multiple times to ensure it's stopped
          for (int i = 0; i < 3; i++) {
            try {
              await _flutterTts!.stop();
              await Future.delayed(const Duration(milliseconds: 200));
            } catch (e) {
              print('⚠️ Error stopping TTS (attempt ${i + 1}): $e');
            }
          }
          
          // Wait longer for TTS to fully stop (increasing delay with retries)
          final waitTime = 800 + (retryCount * 300);
          print('🔊 Waiting ${waitTime}ms for TTS to be ready...');
          await Future.delayed(Duration(milliseconds: waitTime));
          
          // Reset TTS state completely
          try {
            await _flutterTts!.setLanguage("en-US");
            await _flutterTts!.setVolume(_ttsVolume);
            await _flutterTts!.setSpeechRate(0.5);
            await _flutterTts!.setPitch(1.0);
            await Future.delayed(const Duration(milliseconds: 200));
          } catch (e) {
            print('⚠️ Error resetting TTS parameters: $e');
          }
          
          // Start speaking
          print('🔊 Attempting to speak...');
          final result = await _flutterTts!.speak(cleanText);
          print('🔊 TTS speak result: $result (attempt ${retryCount + 1})');
          
          if (result == 1) {
            success = true;
            print('✅ TTS started successfully');
            setState(() {
              _isTtsBusy = false;
            });
          } else if (result == -8) {
            // TTS engine is busy - retry with longer delay
            retryCount++;
            print('⚠️ TTS engine busy (error -8), retrying... (${retryCount}/$maxRetries)');
            if (retryCount < maxRetries) {
              // Exponential backoff: 1s, 2s, 3s, 4s, 5s
              final backoffDelay = 1000 * retryCount;
              print('🔊 Waiting ${backoffDelay}ms before retry...');
              await Future.delayed(Duration(milliseconds: backoffDelay));
              continue;
            } else {
              // Max retries reached
              print('❌ Max retries reached, giving up');
              setState(() {
                _isTtsBusy = false;
                _isSpeaking = false;
                _isPaused = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TTS engine is busy. Please wait a few seconds and try again.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
              success = true; // Exit loop
            }
          } else {
            // Other error
            String errorMessage = 'Failed to start text-to-speech.';
            if (result == -1) {
              errorMessage = 'TTS error occurred. Please check your device settings.';
            }
            
            setState(() {
              _isTtsBusy = false;
              _isSpeaking = false;
              _isPaused = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$errorMessage (Error code: $result)'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            success = true; // Exit loop even on error
          }
        } catch (e) {
          print('❌ Error in TTS retry attempt ${retryCount + 1}: $e');
          retryCount++;
          if (retryCount >= maxRetries) {
            setState(() {
              _isTtsBusy = false;
              _isSpeaking = false;
              _isPaused = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error starting text-to-speech: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            success = true; // Exit loop
          } else {
            await Future.delayed(Duration(milliseconds: 1000 * retryCount));
          }
        }
      }
      
      // Ensure busy flag is cleared
      if (mounted && _isTtsBusy) {
        setState(() {
          _isTtsBusy = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
          _isTtsBusy = false;
          _extractedText = '';
        });
      }
    }
  }

  @override
  void dispose() {
    // Stop TTS if speaking (without setState)
    if (_flutterTts != null) {
      _flutterTts!.stop();
      _flutterTts = null;
    }
    
    // Dispose video controllers
    _youtubeController?.dispose();
    _videoController?.dispose();
    
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

