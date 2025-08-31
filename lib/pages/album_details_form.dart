import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:osprecords/models/album_model.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:searchfield/searchfield.dart';
import 'package:osprecords/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:osprecords/services/uploads.dart';

class Artist {
  String name;
  String type;
  String? spotifyUrl;
  int? followers;
  String? imageUrl;

  Artist({
    this.name = '',
    this.type = 'Primary',
    this.spotifyUrl,
    this.followers,
    this.imageUrl,
  });
}

class SpotifyArtist {
  final String name;
  final String? imageUrl;
  final String? url;
  final int? followers;

  SpotifyArtist({required this.name, this.imageUrl, this.url, this.followers});

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
      name: json['name'] as String,
      imageUrl: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['url'] as String?
          : null,
      url: json['external_urls'] != null
          ? json['external_urls']['spotify'] as String?
          : null,
      followers: json['followers'] != null
          ? json['followers']['total'] as int?
          : null,
    );
  }
}

class AlbumDetailsForm extends StatefulWidget {
  const AlbumDetailsForm({super.key});

  @override
  _AlbumDetailsFormState createState() => _AlbumDetailsFormState();
}

class _AlbumDetailsFormState extends State<AlbumDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Release type selection
  String _selectedReleaseType = 'Single Track';
  final List<String> _releaseTypes = ['Single Track', 'Album'];

  // Image and file pickers
  XFile? _coverImage;
  XFile? _mp3File;

  // Form controllers
  final _titleController = TextEditingController();
  final _songTitleController = TextEditingController();
  final _albumVersionController = TextEditingController();
  final _recordLabelController = TextEditingController();
  final _upcEanController = TextEditingController();

  // Form state variables
  String _selectedLanguage = 'English';
  bool _hasCoverVersions = false;
  bool _isCompilationAlbum = false;
  bool _hasLyrics = false;
  String _primaryGenre = 'Alternative';
  String _secondaryGenre = 'None';
  String _explicitContent = 'Select';
  DateTime? _originallyReleasedDate;
  DateTime? _preOrderDate;
  DateTime? _salesStartDate;

  List<Artist> _artists = [Artist(name: '', type: 'Primary')];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
  ];
  final List<String> _genres = [
    'Alternative',
    'Rock',
    'Pop',
    'Jazz',
    'Classical',
    'Hip Hop',
    'Electronic',
  ];
  final List<String> _explicitOptions = ['Select', 'Yes', 'No', 'Edited'];

  // Add controllers to state
  final TextEditingController _compositionCopyrightController =
      TextEditingController();
  final TextEditingController _soundRecordingCopyrightController =
      TextEditingController();

  final List<String> _artistTypes = [
    'Primary',
    'Featuring',
    'Producer',
    'with',
    'Performer',
    'DJ',
    'Remixer',
    'Conductor',
    'Arranger',
    'Orchestra',
    'Actor',
  ];

  // Spotify API credentials
  final String _spotifyClientId = 'cc4e77dc4afc45aba7ea5545905356bb';
  final String _spotifyClientSecret = '352989370d8e4a889effdf16f51c5d2e';
  String? _spotifyAccessToken;
  DateTime? _spotifyTokenExpiry;

  List<TextEditingController> _artistControllers = [];

  Uint8List? _coverImageBytes;

  bool _isSubmitting = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _artistControllers = List.generate(
      _artists.length,
      (i) => TextEditingController(text: _artists[i].name),
    );
    // Comment out the delay and set loading to false directly
    // Future.delayed(Duration(milliseconds: 200), () {
    //   if (mounted) setState(() => _loading = false);
    // });
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    // Check login status
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isLoggedIn = userProvider.user.token.isNotEmpty;

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Distribution'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.blue[700]),
              SizedBox(height: 24),
              Text(
                'You must be logged in to distribute music.',
                style: TextStyle(fontSize: 20, color: Colors.blue[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Distribution'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: SizedBox.expand(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Distribution'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              _showHelpDialog();
            },
            child: Text(
              'Need help? Please check our help page for helpful guides',
            ),
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 16,
          vertical: isMobile ? 4 : 8,
        ),
        child: Stepper(
          type: isMobile ? StepperType.vertical : StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (int tappedIndex) {
            // Preserve validation: do not allow advancing from step 0 without title
            if (_currentStep == 0 && tappedIndex > 0) {
              if (_titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a release title.'),
                  ),
                );
                return;
              }
            }
            setState(() {
              _currentStep = tappedIndex;
            });
          },
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('Connection'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildCoverImageStep(
                    isMobile: isMobile,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Records Details'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildAlbumDetailsStep(
                    isMobile: isMobile,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Files'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildFilesStep(isMobile: isMobile, screenWidth: screenWidth),
                ],
              ),
            ),
            Step(
              title: const Text('Finished Metadata'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: Column(
                children: [
                  _buildFinishedMetadataStep(
                    isMobile: isMobile,
                    screenWidth: screenWidth,
                    album: null, // Pass null for new forms
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageStep({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Release Data',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: isMobile ? 22 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _showHelpDialog,
              child: Text(
                'Need Help?',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: isMobile ? 14 : 18,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: isMobile ? screenWidth * 0.95 : 600,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 32,
                vertical: isMobile ? 16 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPC / EAN:',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: isMobile ? double.infinity : 350,
                    child: TextFormField(
                      controller: _upcEanController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you don\'t have a UPC / EAN please leave blank and we can generate one for you.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Release Title*:',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: isMobile ? double.infinity : 350,
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: 'Enter release title',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will be the title of your release.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate Release Title before moving to next step
                        if (_titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a release title.'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumDetailsStep({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard([
            _buildSectionTitle('Release Type'),
            SizedBox(height: 16),
            Row(
              children: _releaseTypes.map((type) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildReleaseTypeCard(
                      type,
                      isMobile: isMobile,
                      screenWidth: screenWidth,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            _buildSectionTitle('Release Details'),
            SizedBox(height: 16),
            _buildLanguageDropdown(
              isMobile: isMobile,
              screenWidth: screenWidth,
            ),
            SizedBox(height: 16),
            if (_selectedReleaseType == 'Single Track') ...[
              _buildSongTitleField(
                isMobile: isMobile,
                screenWidth: screenWidth,
              ),
              SizedBox(height: 16),
            ],
            if (_selectedReleaseType == 'Album')
              _buildAlbumVersion(isMobile: isMobile, screenWidth: screenWidth),
            if (_selectedReleaseType == 'Album') SizedBox(height: 16),
            _buildCoverVersionsCheckbox(
              isMobile: isMobile,
              screenWidth: screenWidth,
            ),
            SizedBox(height: 16),
            if (_selectedReleaseType == 'Album')
              _buildCompilationAlbumCheckbox(
                isMobile: isMobile,
                screenWidth: screenWidth,
              ),
            SizedBox(height: 16),
            _buildArtistSection(isMobile: isMobile, screenWidth: screenWidth),
          ]),
          SizedBox(height: 20),
          _buildCard([
            _buildExpandableSection('Publishing Information', [
              SizedBox(height: 16),
              _buildLyricsCheckbox(),
              SizedBox(height: 16),
              _buildGenreDropdowns(),
              SizedBox(height: 16),
              _buildCopyrightSection(),
              SizedBox(height: 16),
              _buildRecordLabelField(),
              SizedBox(height: 16),
              _buildDateFields(),
              SizedBox(height: 16),
              _buildExplicitContentDropdown(),
            ]),
          ]),
          SizedBox(height: 30),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildReleaseTypeCard(
    String type, {
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    final isSelected = _selectedReleaseType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReleaseType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              type == 'Album'
                  ? Icons.album
                  : type == 'Single Track'
                  ? Icons.music_note
                  : Icons.playlist_play,
              color: isSelected ? Colors.blue[700] : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue[700] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Release title field removed from Records Details step.

  Widget _buildSongTitleField({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Song Title*',
          isMobile: isMobile,
          screenWidth: screenWidth,
        ),
        TextFormField(
          controller: _songTitleController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter song title',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          validator: (value) {
            if (_selectedReleaseType == 'Single Track' &&
                (value == null || value.isEmpty)) {
              return 'Please enter the song title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image != null) {
      // Validate file type (JPG or PNG only)
      final allowedExtensions = ['jpg', 'jpeg', 'png'];
      final ext = image.name.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid image type. Please select a JPG or PNG file.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _coverImage = image;
          _coverImageBytes = bytes;
        });
      } else {
        setState(() {
          _coverImage = image;
          _coverImageBytes = null;
        });
      }
    }
  }

  Widget _buildFilesStep({bool isMobile = false, double screenWidth = 400}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artwork (Cover Image)',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recommended: square image (1:1 aspect ratio) with a minimum resolution of 1600 x 1600 pixels, but ideally 3000 x 3000 pixels or higher',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  (_coverImage != null)
                      ? (kIsWeb
                            ? Image.memory(
                                _coverImageBytes!,
                                width: isMobile ? screenWidth * 0.8 : 220,
                                height: isMobile ? screenWidth * 0.8 : 220,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_coverImage!.path),
                                width: isMobile ? screenWidth * 0.8 : 220,
                                height: isMobile ? screenWidth * 0.8 : 220,
                                fit: BoxFit.cover,
                              ))
                      : Container(
                          width: isMobile ? screenWidth * 0.8 : 220,
                          height: isMobile ? screenWidth * 0.8 : 220,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image,
                            size: isMobile ? screenWidth * 0.2 : 100,
                            color: Colors.grey[600],
                          ),
                        ),
                  if (_coverImage != null)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Remove image',
                      onPressed: () {
                        setState(() {
                          _coverImage = null;
                          _coverImageBytes = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickCoverImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Artwork Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Artwork must be JPG or PNG, at least 1000x1000 px, max 10MB.',
                    child: Icon(Icons.help_outline, color: Colors.blue[700]),
                  ),
                ],
              ),
              if (_coverImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'File: ${_coverImage!.name}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Divider(),
        const SizedBox(height: 16),
        Text(
          'Audio File',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We accept:\n• High quality MP3 - 320kbps - 44.1kHz\n• High quality FLAC - 44.1 kHz',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickMp3File,
              icon: const Icon(Icons.audiotrack),
              label: const Text('Select Audio'),
            ),
            const SizedBox(width: 12),
            if (_mp3File != null)
              Flexible(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _mp3File!.name,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Remove audio',
                      onPressed: () {
                        setState(() {
                          _mp3File = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              child: Text('◀ Back'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 3;
                });
              },
              child: Text('Save and Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickMp3File() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final allowedExtensions = ['mp3', 'flac'];
      final ext = file.name.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid audio type. Please select an MP3 or FLAC file.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (kIsWeb) {
        if (file.bytes != null && file.name.isNotEmpty) {
          setState(() {
            _mp3File = XFile.fromData(file.bytes!, name: file.name);
          });
        }
      } else {
        if (file.path != null) {
          setState(() {
            _mp3File = XFile(file.path!);
          });
        }
      }
    }
  }

  Widget _buildFinishedMetadataStep({
    bool isMobile = false,
    double screenWidth = 400,
    AlbumModel? album,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork image at the top
            Center(
              child:
                  ((album?.coverImagePath != null &&
                          album!.coverImagePath!.isNotEmpty) ||
                      _coverImage != null)
                  ? (kIsWeb
                        ? Image.memory(
                            _coverImageBytes!,
                            width: isMobile ? screenWidth * 0.8 : 220,
                            height: isMobile ? screenWidth * 0.8 : 220,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_coverImage?.path ?? album!.coverImagePath!),
                            width: isMobile ? screenWidth * 0.8 : 220,
                            height: isMobile ? screenWidth * 0.8 : 220,
                            fit: BoxFit.cover,
                          ))
                  : Container(
                      width: isMobile ? screenWidth * 0.8 : 220,
                      height: isMobile ? screenWidth * 0.8 : 220,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: isMobile ? screenWidth * 0.2 : 100,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            // Release Information
            _buildMetadataSection('Release Information', [
              Text(
                'Release Title: ${album?.releaseTitle ?? _titleController.text}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Song Title: ${(album?.songTitle ?? _songTitleController.text).isNotEmpty ? (album?.songTitle ?? _songTitleController.text) : 'N/A'}',
              ),
              Text(
                'Release Type: ${album?.releaseType ?? _selectedReleaseType}',
              ),
              Text('Language: ${album?.language ?? _selectedLanguage}'),
              Text(
                'UPC/EAN: ${(album?.upcEan ?? (_upcEanController.text.isEmpty ? 'N/A' : _upcEanController.text))}',
              ),
              if ((album?.releaseType ?? _selectedReleaseType) == 'Album') ...[
                Text(
                  'Record Version: ${album?.albumVersion ?? _albumVersionController.text}',
                ),
                Text(
                  'Is Compilation Album: ${(album?.isCompilationAlbum ?? _isCompilationAlbum) ? 'Yes' : 'No'}',
                ),
              ],
              Text(
                'Has Cover Versions: ${(album?.hasCoverVersions ?? _hasCoverVersions) ? 'Yes' : 'No'}',
              ),
            ]),

            const SizedBox(height: 16),

            // Artists
            _buildMetadataSection('Artists', [
              Text('Artists:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((album?.artists ??
                      _artists
                          .map((a) => {'type': a.type, 'name': a.name})
                          .toList())
                  .map((a) => Text('${a['type']}: ${a['name']}'))
                  .toList()),
            ]),

            const SizedBox(height: 16),

            // Genre and Content
            _buildMetadataSection('Genre & Content', [
              Text('Primary Genre: ${album?.primaryGenre ?? _primaryGenre}'),
              if ((album?.secondaryGenre ?? _secondaryGenre).isNotEmpty)
                Text(
                  'Secondary Genre: ${album?.secondaryGenre ?? _secondaryGenre}',
                ),
              Text(
                'Has Lyrics: ${(album?.hasLyrics ?? _hasLyrics) ? 'Yes' : 'No'}',
              ),
              Text(
                'Explicit Content: ${album?.explicitContent ?? _explicitContent}',
              ),
            ]),

            const SizedBox(height: 16),

            // Publishing and Copyright
            _buildMetadataSection('Publishing & Copyright', [
              if ((album?.compositionCopyrightInfo ??
                      _compositionCopyrightController.text)
                  .isNotEmpty)
                Text(
                  'Composition Copyright: ${album?.compositionCopyrightInfo ?? _compositionCopyrightController.text}',
                ),
              if ((album?.soundRecordingCopyrightInfo ??
                      _soundRecordingCopyrightController.text)
                  .isNotEmpty)
                Text(
                  'Sound Recording Copyright: ${album?.soundRecordingCopyrightInfo ?? _soundRecordingCopyrightController.text}',
                ),
              if ((album?.recordLabel ?? _recordLabelController.text)
                  .isNotEmpty)
                Text(
                  'Record Label: ${album?.recordLabel ?? _recordLabelController.text}',
                ),
            ]),

            const SizedBox(height: 16),

            // Release Dates
            _buildMetadataSection('Release Dates', [
              if ((album?.originallyReleasedDate ?? _originallyReleasedDate) !=
                  null)
                Text(
                  'Originally Released: ${(album?.originallyReleasedDate ?? _originallyReleasedDate)!.toLocal().toString().split(' ')[0]}',
                ),
              if ((album?.preOrderDate ?? _preOrderDate) != null)
                Text(
                  'Pre Order Date: ${(album?.preOrderDate ?? _preOrderDate)!.toLocal().toString().split(' ')[0]}',
                ),
              if ((album?.salesStartDate ?? _salesStartDate) != null)
                Text(
                  'Sales Start Date: ${(album?.salesStartDate ?? _salesStartDate)!.toLocal().toString().split(' ')[0]}',
                ),
            ]),
            const SizedBox(height: 24),
            Text('Audio File:', style: TextStyle(fontWeight: FontWeight.bold)),
            if ((album?.audioFilePath ?? _mp3File) != null)
              Text(album?.audioFilePath ?? _mp3File!.name),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAlbum,
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildLanguageDropdown({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Language',
          isMobile: isMobile,
          screenWidth: screenWidth,
        ),
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _languages.map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAlbumVersion({bool isMobile = false, double screenWidth = 400}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldLabel(
              'Record Version',
              isMobile: isMobile,
              screenWidth: screenWidth,
            ),
            SizedBox(width: 8),
            Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
          ],
        ),
        TextFormField(
          controller: _albumVersionController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Record Version',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverVersionsCheckbox({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Row(
      children: [
        _buildFieldLabel(
          'Does this release contain cover versions?',
          isMobile: isMobile,
          screenWidth: screenWidth,
        ),
        Spacer(),
        Row(
          children: [
            Checkbox(
              value: _hasCoverVersions,
              onChanged: (bool? value) {
                setState(() {
                  _hasCoverVersions = value ?? false;
                });
              },
            ),
            Text('Yes'),
            SizedBox(width: 20),
            Checkbox(
              value: !_hasCoverVersions,
              onChanged: (bool? value) {
                setState(() {
                  _hasCoverVersions = !(value ?? true);
                });
              },
            ),
            Text('No'),
          ],
        ),
      ],
    );
  }

  Widget _buildCompilationAlbumCheckbox({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Row(
      children: [
        _buildFieldLabel(
          'Compilation Album',
          isMobile: isMobile,
          screenWidth: screenWidth,
        ),
        Spacer(),
        Row(
          children: [
            Checkbox(
              value: _isCompilationAlbum,
              onChanged: (bool? value) {
                setState(() {
                  _isCompilationAlbum = value ?? false;
                });
              },
            ),
            Text('Yes'),
            SizedBox(width: 20),
            Checkbox(
              value: !_isCompilationAlbum,
              onChanged: (bool? value) {
                setState(() {
                  _isCompilationAlbum = !(value ?? true);
                });
              },
            ),
            Text('No'),
          ],
        ),
      ],
    );
  }

  Widget _buildArtistSection({
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(
          'Artist Name*',
          isMobile: isMobile,
          screenWidth: screenWidth,
        ),
        ..._artists.asMap().entries.map((entry) {
          int index = entry.key;
          final controller = _artistControllers[index];
          final artist = entry.value;
          if (index == 0 && artist.type != 'Primary') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                setState(() {
                  _artists[0].type = 'Primary';
                });
            });
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artist Name
                  Row(
                    children: [
                      // Profile image
                      if (artist.imageUrl != null &&
                          artist.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(artist.imageUrl!),
                            radius: 18,
                          ),
                        ),
                      // Name search/autocomplete
                      SizedBox(
                        width: isMobile ? 260 : 400,
                        child: ArtistSearchField(
                          controller: controller,
                          artist: artist,
                          allArtists: _artists,
                          onArtistSelected: (SpotifyArtist selected) {
                            setState(() {
                              artist.name = selected.name;
                              artist.spotifyUrl = selected.url;
                              artist.imageUrl = selected.imageUrl;
                              artist.followers = selected.followers;
                              controller.text = selected.name;
                            });
                          },
                          searchSpotifyArtists: _searchSpotifyArtists,
                        ),
                      ),
                      // (Removed follower count from right of box)
                    ],
                  ),
                  SizedBox(width: 8),
                  // Artist Type (improved layout)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueGrey.shade100),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blueGrey.shade50,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Type:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 6),
                        StatefulBuilder(
                          builder: (context, setLocalState) {
                            return DropdownButton<String>(
                              value: _artistTypes.contains(artist.type)
                                  ? artist.type
                                  : _artistTypes.first,
                              items: _artistTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newType) {
                                setState(() {
                                  artist.type = newType ?? _artistTypes.first;
                                });
                                setLocalState(() {});
                              },
                              underline: SizedBox(),
                              isDense: true,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey[900],
                              ),
                              dropdownColor: Colors.white,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // (Removed profile URL icon from left of category selection)
                  if (_artists.length > 1) ...[
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeArtist(index),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addArtist,
            icon: Icon(Icons.add, color: Colors.blue[700]),
            label: Text(
              'Add Artist',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue[700]!),
              foregroundColor: Colors.blue[700],
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsCheckbox() {
    return Row(
      children: [
        _buildFieldLabel('Does this release contain lyrics?'),
        Spacer(),
        Row(
          children: [
            Checkbox(
              value: _hasLyrics,
              onChanged: (bool? value) {
                setState(() {
                  _hasLyrics = value ?? false;
                });
              },
            ),
            Text('Yes'),
            SizedBox(width: 20),
            Checkbox(
              value: !_hasLyrics,
              onChanged: (bool? value) {
                setState(() {
                  _hasLyrics = !(value ?? true);
                });
              },
            ),
            Text('No'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenreDropdowns() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Primary Genre'),
                  DropdownButtonFormField<String>(
                    value: _primaryGenre,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _genres.map((String genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _primaryGenre = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Secondary Genre'),
                  DropdownButtonFormField<String>(
                    value: _secondaryGenre,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: ['None', ..._genres].map((String genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _secondaryGenre = newValue!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCopyrightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Where is the Composition Copyright?'),
        TextFormField(
          controller: _compositionCopyrightController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter where the composition copyright is held',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        SizedBox(height: 16),
        _buildFieldLabel('Where is the Sound Recording Copyright?'),
        TextFormField(
          controller: _soundRecordingCopyrightController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter where the sound recording copyright is held',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordLabelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldLabel('Record Label Name'),
            SizedBox(width: 8),
            Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
          ],
        ),
        TextFormField(
          controller: _recordLabelController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Record Label Name',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFields() {
    return Column(
      children: [
        _buildDateField('Originally Released*', _originallyReleasedDate, (
          date,
        ) {
          setState(() {
            _originallyReleasedDate = date;
          });
        }),
        SizedBox(height: 16),
        _buildDateField('Pre Order Date', _preOrderDate, (date) {
          setState(() {
            _preOrderDate = date;
          });
        }),
        SizedBox(height: 16),
        _buildDateField('Sales Start Date', _salesStartDate, (date) {
          setState(() {
            _salesStartDate = date;
          });
        }),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldLabel(label),
            if (label.contains('*')) SizedBox(width: 8),
            if (label.contains('*'))
              Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  onDateSelected(picked);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.blue[100]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.blue[800],
                    ),
                    SizedBox(width: 8),
                    Text(
                      selectedDate != null
                          ? '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
                          : 'Select Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: selectedDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            TextButton(
              onPressed: selectedDate != null
                  ? () => onDateSelected(null)
                  : null,
              child: Text('Clear Date'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[800]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplicitContentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Explicit Content*'),
        DropdownButtonFormField<String>(
          value: _explicitContent,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _explicitOptions.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _explicitContent = newValue!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, List<Widget> children) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
      initiallyExpanded: true,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(
    String label, {
    bool isMobile = false,
    double screenWidth = 400,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('◀ Back'),
        ),
        Spacer(),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text('Save and Continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _addArtist() {
    // Prevent adding if the last artist is empty
    if (_artists.isNotEmpty && _artists.last.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill the previous artist before adding a new one.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _artists.add(Artist(name: '', type: 'Primary'));
      _artistControllers.add(TextEditingController());
    });
  }

  void _showTimeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Time'),
          content: Text(
            'Time selection functionality would be implemented here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Need Help?'),
          content: Text(
            'Please check our help page for helpful guides and detailed instructions on filling out the records details form.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process the data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Records details saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Here you would typically save the data to a database or send it to an API
      print('Form submitted with data:');
      print('Title: ${_titleController.text}');
      print('Language: $_selectedLanguage');
      print(
        'Artists: ${_artists.map((a) => '${a.type}: ${a.name}').join(', ')}',
      );
      print('Genre: $_primaryGenre');
      // ... print other form data

      // After saving, advance to the Files step
      setState(() {
        _currentStep = 2; // 0: Connection, 1: Records Details, 2: Files
      });
    }
  }

  Future<List<SpotifyArtist>> _searchSpotifyArtists(String query) async {
    if (query.isEmpty) return [];
    await _fetchSpotifyToken();
    if (_spotifyAccessToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Spotify authentication failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=artist&limit=8',
        ),
        headers: {'Authorization': 'Bearer $_spotifyAccessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List artists = data['artists']['items'];
        return artists
            .map<SpotifyArtist>((artist) => SpotifyArtist.fromJson(artist))
            .toList();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Spotify search failed: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching Spotify: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> _fetchSpotifyToken() async {
    // Check if we already have a valid token
    if (_spotifyAccessToken != null &&
        _spotifyTokenExpiry != null &&
        DateTime.now().isBefore(_spotifyTokenExpiry!)) {
      return;
    }

    try {
      // Create the authorization header
      final credentials = '$_spotifyClientId:$_spotifyClientSecret';
      final encodedCredentials = base64Encode(utf8.encode(credentials));

      final response = await http
          .post(
            Uri.parse('https://accounts.spotify.com/api/token'),
            headers: {
              'Authorization': 'Basic $encodedCredentials',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'grant_type': 'client_credentials'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Spotify token request timed out',
                const Duration(seconds: 10),
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _spotifyAccessToken = data['access_token'];
        _spotifyTokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in']),
        );

        // Log successful token fetch (remove in production)
        print(
          'Spotify token fetched successfully. Expires in ${data['expires_in']} seconds.',
        );
      } else {
        // Handle different error status codes
        String errorMessage = 'Failed to fetch Spotify token';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['error_description'] ??
              errorData['error'] ??
              errorMessage;
        } catch (e) {
          errorMessage =
              'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        print('Spotify token fetch failed: $errorMessage');
        _spotifyAccessToken = null;
        _spotifyTokenExpiry = null;

        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to connect to Spotify. Please try again later.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on TimeoutException catch (e) {
      print('Spotify token request timed out: $e');
      _spotifyAccessToken = null;
      _spotifyTokenExpiry = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection to Spotify timed out. Please check your internet connection.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FormatException catch (e) {
      print('Invalid JSON response from Spotify: $e');
      _spotifyAccessToken = null;
      _spotifyTokenExpiry = null;
    } catch (e) {
      print('Unexpected error fetching Spotify token: $e');
      _spotifyAccessToken = null;
      _spotifyTokenExpiry = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeArtist(int index) {
    setState(() {
      _artists.removeAt(index);
      _artistControllers[index].dispose();
      _artistControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _songTitleController.dispose();
    _albumVersionController.dispose();
    _recordLabelController.dispose();
    _upcEanController.dispose();
    _compositionCopyrightController.dispose();
    _soundRecordingCopyrightController.dispose();
    for (final controller in _artistControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitAlbum() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // Validate required fields
      if (_titleController.text.trim().isEmpty) {
        throw Exception('Release title is required');
      }
      if (_artists.isEmpty || _artists.first.name.trim().isEmpty) {
        throw Exception('At least one artist is required');
      }
      if (_originallyReleasedDate == null) {
        throw Exception('Originally released date is required');
      }
      if (_explicitContent == 'Select') {
        throw Exception('Please select explicit content option');
      }

      // --- Debug: Print file info before upload ---
      print('Cover image: ${_coverImage?.name}, path: ${_coverImage?.path}');
      print('Audio file: ${_mp3File?.name}, path: ${_mp3File?.path}');
      if (_mp3File == null) {
        throw Exception('Audio file not selected.');
      }
      if (_coverImage == null) {
        throw Exception('Cover image not selected.');
      }
      if (kIsWeb) {
        final audioBytes = await _mp3File!.readAsBytes();
        print('Audio file bytes length: ${audioBytes.length}');
        if (audioBytes.isEmpty) {
          throw Exception('Audio file is empty.');
        }
      } else {
        final audioFile = File(_mp3File!.path);
        final exists = await audioFile.exists();
        print('Audio file exists: $exists');
        if (!exists) {
          throw Exception('Audio file does not exist on disk.');
        }
      }

      // --- Upload image and audio files together if present ---

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user.id;

      // Prepare all release metadata as a Map<String, String>
      final Map<String, String> releaseFields = {
        'releaseTitle': _titleController.text.trim(),
        'songTitle': _selectedReleaseType == 'Single Track'
            ? _songTitleController.text.trim()
            : '',
        'releaseType': _selectedReleaseType,
        'language': _selectedLanguage,
        'albumVersion': _albumVersionController.text.trim(),
        'hasCoverVersions': _hasCoverVersions.toString(),
        'isCompilationAlbum': _isCompilationAlbum.toString(),
        'hasLyrics': _hasLyrics.toString(),
        'primaryGenre': _primaryGenre,
        'secondaryGenre': _secondaryGenre,
        'explicitContent': _explicitContent,
        'recordLabel': _recordLabelController.text.trim(),
        'originallyReleasedDate':
            _originallyReleasedDate?.toIso8601String() ?? '',
        'preOrderDate': _preOrderDate?.toIso8601String() ?? '',
        'salesStartDate': _salesStartDate?.toIso8601String() ?? '',
        'compositionCopyrightInfo': _compositionCopyrightController.text.trim(),
        'soundRecordingCopyrightInfo': _soundRecordingCopyrightController.text
            .trim(),
        'upcEan': _upcEanController.text.trim(),
      };

      // Always include artists as JSON arrays
      releaseFields['artists'] = jsonEncode(
        _artists
            .map(
              (a) => {
                'name': a.name,
                'type': a.type,
                'spotifyUrl': a.spotifyUrl,
                'followers': a.followers,
                'imageUrl': a.imageUrl,
              },
            )
            .toList(),
      );

      // Remove only truly optional fields that are empty (but NOT artists)
      releaseFields.removeWhere(
        (k, v) => (k != 'artists') && (v == null || v.toString().isEmpty),
      );

      print('Release fields payload: $releaseFields');

      final uploadResult = await UploadService.uploadFilesWithFields(
        userId: userId,
        imageFile: _coverImage!,
        audioFile: _mp3File!,
        fields: releaseFields,
      );

      print(
        'Upload result: status=${uploadResult.statusCode}, error=${uploadResult.error}',
      );

      if (uploadResult.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Success'),
              content: Text('Release submitted successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Show the specific error message from the upload service
        String errorMsg = uploadResult.error ?? 'Unknown error occurred';
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error'),
              content: Text('Failed to submit album: $errorMsg'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to submit album: $errorMsg'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class ArtistSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Artist artist;
  final List<Artist> allArtists;
  final void Function(SpotifyArtist) onArtistSelected;
  final Future<List<SpotifyArtist>> Function(String) searchSpotifyArtists;

  const ArtistSearchField({
    Key? key,
    required this.controller,
    required this.artist,
    required this.allArtists,
    required this.onArtistSelected,
    required this.searchSpotifyArtists,
  }) : super(key: key);

  @override
  State<ArtistSearchField> createState() => _ArtistSearchFieldState();
}

class _ArtistSearchFieldState extends State<ArtistSearchField> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  List<SearchFieldListItem<SpotifyArtist>> _suggestions = [];
  Timer? _debounce;

  void _onTextChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      _isLoading.value = true;
      final results = await widget.searchSpotifyArtists(query);
      setState(() {
        _suggestions = results
            .map<SearchFieldListItem<SpotifyArtist>>(
              (artist) => SearchFieldListItem<SpotifyArtist>(
                artist.name,
                item: artist,
                child: Row(
                  children: [
                    if (artist.imageUrl != null && artist.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(artist.imageUrl!),
                          radius: 14,
                        ),
                      ),
                    Text(artist.name),
                  ],
                ),
              ),
            )
            .toList();
      });
      _isLoading.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show profile URL and followers above the name box if available
        if ((artist.spotifyUrl != null && artist.spotifyUrl!.isNotEmpty) ||
            (artist.followers != null))
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (artist.spotifyUrl != null && artist.spotifyUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final url = artist.spotifyUrl!;
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link, color: Colors.blue[700], size: 18),
                        SizedBox(width: 4),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.blue[700],
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ),
                if (artist.followers != null)
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.grey[700], size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${artist.followers} followers',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            SearchField<SpotifyArtist>(
              controller: widget.controller,
              suggestions: _suggestions,
              suggestionState: Suggestion.expand,
              textInputAction: TextInputAction.next,
              hint: 'Artist Name',
              searchInputDecoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSearchTextChanged: (query) {
                _onTextChanged(query);
                return _suggestions;
              },
              onSuggestionTap: (item) {
                final selected = item.item!;
                widget.controller.text = selected.name;
                widget.onArtistSelected(selected);
              },
              emptyWidget: ValueListenableBuilder<bool>(
                valueListenable: _isLoading,
                builder: (context, loading, child) {
                  if (loading) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, loading, child) {
                if (!loading) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                );
              },
            ),
            if (widget.controller.text.isNotEmpty)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onArtistSelected(
                      SpotifyArtist(
                        name: '',
                        imageUrl: null,
                        url: null,
                        followers: null,
                      ),
                    );
                  },
                  tooltip: 'Clear',
                ),
              ),
          ],
        ),
      ],
    );
  }
}
