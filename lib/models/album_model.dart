import 'dart:convert';
import 'dart:io';

class AlbumModel {
  // Step 1: Connection Details
  final String releaseTitle;
  final String releaseType;
  final String language;
  final String? songTitle;

  // Step 2: Records Details
  final List<Map<String, dynamic>>
  artists; // name, type, spotifyUrl, followers, imageUrl
  final String albumVersion;
  final bool hasCoverVersions;
  final bool isCompilationAlbum;

  final bool hasLyrics;
  final String primaryGenre;
  final String secondaryGenre;
  final String explicitContent;
  final String? recordLabel;
  final DateTime? originallyReleasedDate;
  final DateTime? preOrderDate;
  final DateTime? salesStartDate;
  final String? compositionCopyrightInfo;
  final String? soundRecordingCopyrightInfo;

  // Step 3: Files
  final String? coverImagePath; // local path or network URL
  final String? audioFilePath; // local path or network URL

  // Identifiers
  final String? upcEan;

  AlbumModel({
    required this.releaseTitle,
    this.songTitle,
    required this.releaseType,
    required this.language,
    required this.artists,
    required this.albumVersion,
    required this.hasCoverVersions,
    required this.isCompilationAlbum,

    required this.hasLyrics,
    required this.primaryGenre,
    required this.secondaryGenre,
    required this.explicitContent,
    this.recordLabel,
    this.originallyReleasedDate,
    this.preOrderDate,
    this.salesStartDate,
    this.compositionCopyrightInfo,
    this.soundRecordingCopyrightInfo,
    this.coverImagePath,
    this.audioFilePath,
    this.upcEan,
  });

  Map<String, dynamic> toJson() => {
    'releaseTitle': releaseTitle,
    'songTitle': songTitle,
    'releaseType': releaseType,
    'language': language,
    'artists': artists,
    'albumVersion': albumVersion,
    'hasCoverVersions': hasCoverVersions,
    'isCompilationAlbum': isCompilationAlbum,

    'hasLyrics': hasLyrics,
    'primaryGenre': primaryGenre,
    'secondaryGenre': secondaryGenre,
    'explicitContent': explicitContent,
    'recordLabel': recordLabel,
    'originallyReleasedDate': originallyReleasedDate?.toIso8601String(),
    'preOrderDate': preOrderDate?.toIso8601String(),
    'salesStartDate': salesStartDate?.toIso8601String(),
    'compositionCopyrightInfo': compositionCopyrightInfo,
    'soundRecordingCopyrightInfo': soundRecordingCopyrightInfo,
    'coverImagePath': coverImagePath,
    'audioFilePath': audioFilePath,
    'upcEan': upcEan,
    // Client MUST NOT set releasedPass or releasedDate; server controls these
  };

  factory AlbumModel.fromJson(Map<String, dynamic> json) => AlbumModel(
    releaseTitle: json['releaseTitle'],
    songTitle: json['songTitle'],
    releaseType: json['releaseType'],
    language: json['language'],
    artists: List<Map<String, dynamic>>.from(json['artists']),
    albumVersion: json['albumVersion'],
    hasCoverVersions: json['hasCoverVersions'],
    isCompilationAlbum: json['isCompilationAlbum'],

    hasLyrics: json['hasLyrics'],
    primaryGenre: json['primaryGenre'],
    secondaryGenre: json['secondaryGenre'],
    explicitContent: json['explicitContent'],
    recordLabel: json['recordLabel'],
    originallyReleasedDate: json['originallyReleasedDate'] != null
        ? DateTime.parse(json['originallyReleasedDate'])
        : null,
    preOrderDate: json['preOrderDate'] != null
        ? DateTime.parse(json['preOrderDate'])
        : null,
    salesStartDate: json['salesStartDate'] != null
        ? DateTime.parse(json['salesStartDate'])
        : null,
    compositionCopyrightInfo: json['compositionCopyrightInfo'],
    soundRecordingCopyrightInfo: json['soundRecordingCopyrightInfo'],
    coverImagePath: json['coverImagePath'],
    audioFilePath: json['audioFilePath'],
    upcEan: json['upcEan'],
  );

  // Static list to hold all submitted albums
  static List<AlbumModel> albumList = [];

  // Save the album list to album_data.json
  static Future<void> saveToJsonFile() async {
    final jsonString = jsonEncode(albumList.map((a) => a.toJson()).toList());
    final file = File('album_data.json');
    await file.writeAsString(jsonString);
  }

  // Load the album list from album_data.json
  static Future<void> loadFromJsonFile() async {
    final file = File('album_data.json');
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      albumList = jsonList.map((e) => AlbumModel.fromJson(e)).toList();
    }
  }
}
