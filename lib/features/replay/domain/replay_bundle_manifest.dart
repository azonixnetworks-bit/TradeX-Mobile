import 'dart:convert';

class ReplayBundleManifest {
  const ReplayBundleManifest({required this.built, required this.files});

  final bool built;
  final List<ReplayBundleFile> files;

  factory ReplayBundleManifest.parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['contract_version'] != 1) {
      throw const FormatException('Replay bundle manifest is invalid');
    }

    final built = decoded['built'] == true;
    if (!built) {
      return const ReplayBundleManifest(built: false, files: []);
    }

    final entries = decoded['files'];
    if (entries is! List || entries.length < 2 || entries.length > 12) {
      throw const FormatException('Replay bundle manifest is invalid');
    }

    final seen = <String>{};
    final files = <ReplayBundleFile>[];
    for (final entry in entries) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid bundle entry');
      }
      final name = entry['name'];
      final digest = entry['sha256'];
      if (name is! String ||
          !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$').hasMatch(name) ||
          name.contains('..') ||
          digest is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
          !seen.add(name)) {
        throw const FormatException('Unsafe replay bundle asset');
      }
      files.add(ReplayBundleFile(name: name, sha256: digest));
    }

    if (!seen.contains('index.html')) {
      throw const FormatException('Missing terminal entry page');
    }
    return ReplayBundleManifest(built: true, files: files);
  }
}

class ReplayBundleFile {
  const ReplayBundleFile({required this.name, required this.sha256});

  final String name;
  final String sha256;
}
