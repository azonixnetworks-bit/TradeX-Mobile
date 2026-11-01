class SriLankaBankReference {
  const SriLankaBankReference({
    required this.name,
    this.aliases = const <String>[],
    this.branches = const <String>[],
  });

  final String name;
  final List<String> aliases;
  final List<String> branches;
}

/// Non-exhaustive offline assistance data. Bank names follow the Central Bank
/// of Sri Lanka licensed-bank list. Branch names come from published bank
/// location/contact material; manual entry remains authoritative for the form.
abstract final class SriLankaBankDirectory {
  static const banks = <SriLankaBankReference>[
    SriLankaBankReference(name: 'Amana Bank PLC', aliases: ['Amana']),
    SriLankaBankReference(
      name: 'Bank of Ceylon',
      aliases: ['BOC'],
      branches: [
        'Kandy 2nd City Branch',
        'Gampola Branch',
        'Hatton Branch',
        'Wellawatta Branch',
        'Gampaha Branch',
        'Ja Ela Branch',
        'Negombo Branch',
        'Negombo City Branch',
        'Aluthgama Branch',
        'Beruwala Branch',
      ],
    ),
    SriLankaBankReference(
      name: 'Bank of China Limited',
      aliases: ['BOC China'],
    ),
    SriLankaBankReference(name: 'Cargills Bank PLC', aliases: ['Cargills']),
    SriLankaBankReference(
      name: 'Citibank, N.A.',
      aliases: ['Citi', 'Citibank'],
    ),
    SriLankaBankReference(
      name: 'Commercial Bank of Ceylon PLC',
      aliases: ['Commercial Bank', 'ComBank', 'CBC'],
      branches: ['Galle City Branch'],
    ),
    SriLankaBankReference(name: 'Deutsche Bank AG', aliases: ['Deutsche']),
    SriLankaBankReference(
      name: 'DFCC Bank PLC',
      aliases: ['DFCC'],
      branches: [
        'Kandy Branch',
        'Badulla Branch',
        'Gampaha Branch',
        'Anuradhapura Branch',
        'Kurunegala Branch',
        'Matara Branch',
        'Kalutara Branch',
        'Polonnaruwa Branch',
      ],
    ),
    SriLankaBankReference(name: 'Habib Bank Limited', aliases: ['HBL']),
    SriLankaBankReference(
      name: 'Hatton National Bank PLC',
      aliases: ['HNB', 'Hatton National Bank'],
    ),
    SriLankaBankReference(name: 'Indian Bank'),
    SriLankaBankReference(name: 'Indian Overseas Bank', aliases: ['IOB']),
    SriLankaBankReference(name: 'MCB Bank Limited', aliases: ['MCB']),
    SriLankaBankReference(
      name: 'National Development Bank PLC',
      aliases: ['NDB', 'NDB Bank'],
      branches: [
        'Borella Branch',
        'Narahenpita Branch',
        'Matara Branch',
        'Ja Ela Branch',
        'Kurunegala Branch',
        'Kandy Branch',
        'Ratnapura Branch',
        'Jaffna Branch',
      ],
    ),
    SriLankaBankReference(
      name: 'Nations Trust Bank PLC',
      aliases: ['NTB', 'Nations Trust Bank'],
    ),
    SriLankaBankReference(
      name: 'Pan Asia Banking Corporation PLC',
      aliases: ['Pan Asia Bank', 'PABC'],
    ),
    SriLankaBankReference(
      name: "People's Bank",
      aliases: ['Peoples Bank', 'PB'],
      branches: [
        'Nugegoda Main Branch',
        'Gampaha Branch',
        'Kandy Super Grade Branch',
        'Kiribathgoda Branch',
      ],
    ),
    SriLankaBankReference(name: 'Public Bank Berhad', aliases: ['Public Bank']),
    SriLankaBankReference(name: 'Sampath Bank PLC', aliases: ['Sampath']),
    SriLankaBankReference(name: 'Seylan Bank PLC', aliases: ['Seylan']),
    SriLankaBankReference(
      name: 'Standard Chartered Bank',
      aliases: ['SCB', 'Standard Chartered'],
    ),
    SriLankaBankReference(name: 'State Bank of India', aliases: ['SBI']),
    SriLankaBankReference(
      name: 'The Hongkong and Shanghai Banking Corporation Limited',
      aliases: ['HSBC'],
    ),
    SriLankaBankReference(
      name: 'Union Bank of Colombo PLC',
      aliases: ['Union Bank', 'UBC'],
    ),
    SriLankaBankReference(name: 'National Savings Bank', aliases: ['NSB']),
    SriLankaBankReference(
      name: 'SANASA Development Bank PLC',
      aliases: ['SDB', 'SANASA Bank'],
    ),
    SriLankaBankReference(
      name: 'Regional Development Bank',
      aliases: ['RDB', 'Pradeshiya Sanwardhana Bank'],
    ),
  ];

  static Iterable<String> bankSuggestions(String query) {
    final needle = _normalize(query);
    if (needle.isEmpty) return const <String>[];
    final matches =
        banks.where((bank) {
          return _normalize(bank.name).contains(needle) ||
              bank.aliases.any((alias) => _normalize(alias).contains(needle));
        }).toList()..sort((left, right) {
          final leftScore = _bankScore(left, needle);
          final rightScore = _bankScore(right, needle);
          return leftScore != rightScore
              ? leftScore.compareTo(rightScore)
              : left.name.compareTo(right.name);
        });
    return matches.take(8).map((bank) => bank.name);
  }

  static Iterable<String> branchSuggestions({
    required String bankName,
    required String query,
  }) {
    final needle = _normalize(query);
    if (needle.isEmpty) return const <String>[];
    final selected = _findBank(bankName);
    final prioritized =
        selected?.branches
            .where((branch) => _normalize(branch).contains(needle))
            .toList() ??
        <String>[];
    final seen = prioritized.map(_normalize).toSet();
    final fallback =
        banks
            .expand((bank) => bank.branches)
            .where((branch) => _normalize(branch).contains(needle))
            .where((branch) => seen.add(_normalize(branch)))
            .toList()
          ..sort();
    return <String>[...prioritized, ...fallback].take(8);
  }

  static SriLankaBankReference? _findBank(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return null;
    for (final bank in banks) {
      if (_normalize(bank.name) == normalized ||
          bank.aliases.any((alias) => _normalize(alias) == normalized)) {
        return bank;
      }
    }
    return null;
  }

  static int _bankScore(SriLankaBankReference bank, String needle) {
    if (_normalize(bank.name).startsWith(needle)) return 0;
    if (bank.aliases.any((alias) => _normalize(alias).startsWith(needle))) {
      return 1;
    }
    return 2;
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
