import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:osprecords/utils/constants.dart';

class ReleaseDetailsPage extends StatefulWidget {
  final Map<String, dynamic> releaseData;

  const ReleaseDetailsPage({super.key, required this.releaseData});

  @override
  State<ReleaseDetailsPage> createState() => _ReleaseDetailsPageState();
}

class _ReleaseDetailsPageState extends State<ReleaseDetailsPage> {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to audio duration changes
    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    // Listen to audio position changes
    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });

    // Listen to player state changes
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final audioPath = widget.releaseData['audioFilePath'] ?? '';
    if (audioPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No audio file available')));
      return;
    }

    // Use direct static path
    String audioUrl = '${Constants.staticUri}/$audioPath';

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading audio...'),
          duration: Duration(seconds: 2),
        ),
      );

      await audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      String errorMessage = 'Error playing audio';

      if (e.toString().contains('80070002')) {
        errorMessage = 'Audio file not found. Please check if the file exists.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('format')) {
        errorMessage = 'Unsupported audio format.';
      } else {
        errorMessage = 'Error playing audio: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Helper method to safely convert values to boolean
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  Future<void> _pauseAudio() async {
    await audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await audioPlayer.stop();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.releaseData;
    final imagePath = (data['coverImagePath'] ?? data['image'] ?? '')
        .toString();

    // Use direct static path
    String image = imagePath.isNotEmpty
        ? '${Constants.staticUri}/$imagePath'
        : '';
    final title = (data['releaseTitle'] ?? data['title'] ?? 'Untitled')
        .toString();
    final song = (data['songTitle'] ?? '').toString();
    final type = (data['releaseType'] ?? 'album').toString();
    final label = (data['recordLabel'] ?? 'Unknown Label').toString();
    final releasedPass = _parseBool(data['releasedPass']);
    final createdRaw = (data['createdAt'] ?? data['created'] ?? '').toString();
    final artists = data['artists'] ?? [];

    DateTime? created;
    try {
      if (createdRaw.isNotEmpty) created = DateTime.parse(createdRaw);
    } catch (_) {}
    final createdStr = created == null
        ? 'Unknown'
        : DateFormat('MMM d, yyyy').format(created!);

    final status = releasedPass ? 'Released' : 'Pending';
    final statusColor = releasedPass ? Colors.green : Colors.orange;
    final statusIcon = releasedPass ? Icons.check_circle : Icons.pending;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Release Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Cover image
                  image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            image,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey.shade600,
                          ),
                        ),
                  // Status badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Blue star for paid
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and basic info
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (song.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      song,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Audio player section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Audio Player',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            // Audio availability indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (widget.releaseData['audioFilePath'] ?? '')
                                        .isNotEmpty
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (widget.releaseData['audioFilePath'] ?? '')
                                        .isNotEmpty
                                    ? 'Available'
                                    : 'Not Available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      (widget.releaseData['audioFilePath'] ??
                                              '')
                                          .isNotEmpty
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress bar
                        Slider(
                          min: 0,
                          max: duration.inSeconds.toDouble(),
                          value: position.inSeconds.toDouble(),
                          onChanged: (value) async {
                            final position = Duration(seconds: value.toInt());
                            await audioPlayer.seek(position);
                          },
                        ),

                        // Time display
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(position)),
                              Text(_formatTime(duration)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed:
                                  (widget.releaseData['audioFilePath'] ?? '')
                                      .isNotEmpty
                                  ? _stopAudio
                                  : null,
                              icon: const Icon(Icons.stop, size: 32),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    (widget.releaseData['audioFilePath'] ?? '')
                                        .isNotEmpty
                                    ? Colors.red.shade100
                                    : Colors.grey.shade300,
                                foregroundColor:
                                    (widget.releaseData['audioFilePath'] ?? '')
                                        .isNotEmpty
                                    ? Colors.red.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed:
                                  (widget.releaseData['audioFilePath'] ?? '')
                                      .isNotEmpty
                                  ? (isPlaying ? _pauseAudio : _playAudio)
                                  : null,
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 48,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    (widget.releaseData['audioFilePath'] ?? '')
                                        .isNotEmpty
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade300,
                                foregroundColor:
                                    (widget.releaseData['audioFilePath'] ?? '')
                                        .isNotEmpty
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Release details
                  Text(
                    'Release Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _detailRow('Type', type),
                  _detailRow('Label', label),
                  _detailRow('Created', createdStr),
                  _detailRow('Status', status),

                  if (artists.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Artists',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...artists.map(
                      (artist) => _detailRow(
                        'Artist',
                        '${artist['name'] ?? ''} ${artist['lastName'] ?? ''}'
                            .trim(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Additional metadata
                  if (data['primaryGenre'] != null)
                    _detailRow(
                      'Primary Genre',
                      data['primaryGenre'].toString(),
                    ),
                  if (data['explicitContent'] != null)
                    _detailRow(
                      'Explicit Content',
                      _parseBool(data['explicitContent']) ? 'Yes' : 'No',
                    ),
                  if (data['hasCoverVersions'] != null)
                    _detailRow(
                      'Has Cover Versions',
                      _parseBool(data['hasCoverVersions']) ? 'Yes' : 'No',
                    ),
                  if (data['isCompilationAlbum'] != null)
                    _detailRow(
                      'Compilation Album',
                      _parseBool(data['isCompilationAlbum']) ? 'Yes' : 'No',
                    ),
                  if (data['hasLyrics'] != null)
                    _detailRow(
                      'Has Lyrics',
                      _parseBool(data['hasLyrics']) ? 'Yes' : 'No',
                    ),

                  // Debug: Show image and audio file paths
                  if (data['coverImagePath'] != null ||
                      data['audioFilePath'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'File Paths (Debug)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['coverImagePath'] != null) ...[
                            Text(
                              'Image Path: ${data['coverImagePath']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Image URL: ${Constants.staticUri}/${data['coverImagePath']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (data['audioFilePath'] != null) ...[
                            Text(
                              'Audio Path: ${data['audioFilePath']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Audio URL: ${Constants.staticUri}/${data['audioFilePath']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
