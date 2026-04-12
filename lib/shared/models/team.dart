// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// SHARED DATA MODELS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class TeamModel {
  final String id;
  final String name;
  final String? flagUrl;
  final String groupLetter;

  const TeamModel({
    required this.id,
    required this.name,
    this.flagUrl,
    required this.groupLetter,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
        id: json['id'] as String,
        name: json['name'] as String,
        flagUrl: json['flag_url'] as String?,
        groupLetter: json['group_letter'] as String,
      );
}
