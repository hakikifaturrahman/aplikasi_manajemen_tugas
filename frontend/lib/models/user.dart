/**
 * Model Data User untuk memetakan informasi profil dan pengaturan pengguna
 */
class User {
  final int id;
  final String name;
  final String email;
  final String? profilePicture;
  final bool remindDeadlines;
  final bool weeklyReport;
  final bool newTasks;
  final bool emailAlerts;
  final bool isPrivateProfile;
  final bool enableTwoFactor;
  final bool sessionTimeout;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.remindDeadlines,
    required this.weeklyReport,
    required this.newTasks,
    required this.emailAlerts,
    required this.isPrivateProfile,
    required this.enableTwoFactor,
    required this.sessionTimeout,
  });

  // Factory constructor untuk mengonversi data JSON (Map) dari API ke objek User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profile_picture'],
      // Mengonversi data integer (1/0) atau boolean dari API menjadi bool di Dart
      remindDeadlines: json['remind_deadlines'] == 1 || json['remind_deadlines'] == true,
      weeklyReport: json['weekly_report'] == 1 || json['weekly_report'] == true,
      newTasks: json['new_tasks'] == 1 || json['new_tasks'] == true,
      emailAlerts: json['email_alerts'] == 1 || json['email_alerts'] == true,
      isPrivateProfile: json['is_private_profile'] == 1 || json['is_private_profile'] == true,
      enableTwoFactor: json['enable_two_factor'] == 1 || json['enable_two_factor'] == true,
      sessionTimeout: json['session_timeout'] == 1 || json['session_timeout'] == true,
    );
  }

  // Mengonversi objek User kembali menjadi Map JSON sebelum dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_picture': profilePicture,
      'remind_deadlines': remindDeadlines ? 1 : 0,
      'weekly_report': weeklyReport ? 1 : 0,
      'new_tasks': newTasks ? 1 : 0,
      'email_alerts': emailAlerts ? 1 : 0,
      'is_private_profile': isPrivateProfile ? 1 : 0,
      'enable_two_factor': enableTwoFactor ? 1 : 0,
      'session_timeout': sessionTimeout ? 1 : 0,
    };
  }
}
