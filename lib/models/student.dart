class Student {
  final String name;
  final String institutionName;
  final String? uid;
  final String? birthName;
  final String? birthPlace;
  final String? mothersName;
  final String? email;
  final String? phone;
  final List<String> addresses;
  final String? birthDate;
  final List<Map<String, dynamic>> guardians;
  final DateTime? nextDowntime;

  const Student({
    required this.name,
    required this.institutionName,
    this.uid,
    this.birthName,
    this.birthPlace,
    this.mothersName,
    this.email,
    this.phone,
    this.addresses = const [],
    this.birthDate,
    this.guardians = const [],
    this.nextDowntime,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    final inst = json['Intezmeny'];
    final settings = inst?['TestreszabasBeallitasok'];
    final nextDowntimeRaw = settings?['KovetkezoTelepitesDatuma'];
    DateTime? parsedNextDowntime;
    if (nextDowntimeRaw != null) {
      parsedNextDowntime = DateTime.tryParse(nextDowntimeRaw.toString())?.toLocal();
    }

    return Student(
      name: json['Nev'] ?? 'Ismeretlen',
      institutionName: json['IntezmenyNev'] ?? json['Intezmeny']?['TeljesNev'] ?? 'Ismeretlen intézmény',
      uid: json['Uid']?.toString(),
      birthName: json['SzuletesiNev'],
      birthPlace: json['SzuletesiHely'],
      mothersName: json['AnyjaNeve'],
      email: json['EmailCim'],
      phone: json['Telefonszam'],
      addresses: (json['Cimek'] as List?)?.map((e) => e.toString()).toList() ?? [],
      birthDate: json['SzuletesiDatum'],
      guardians: (json['Gondviselok'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      nextDowntime: parsedNextDowntime,
    );
  }
}
