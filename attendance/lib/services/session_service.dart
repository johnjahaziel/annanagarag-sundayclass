import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user's identity, persisted locally so the app can skip
/// the login screen on subsequent launches.
class UserSession {
  const UserSession({
    required this.username,
    required this.role,
    required this.docId,
    required this.name,
  });

  final String username;

  /// "Admin" or "Teacher" — which collection this user was found in.
  final String role;

  /// The signed-in user's Firestore document id (in `admins` or
  /// `teachers`, depending on [role]).
  final String docId;
  final String name;
}

/// Persists the signed-in user's session with SharedPreferences.
class SessionService {
  static const _keyUsername = 'session_username';
  static const _keyRole = 'session_role';
  static const _keyDocId = 'session_docId';
  static const _keyName = 'session_name';

  Future<void> saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, session.username);
    await prefs.setString(_keyRole, session.role);
    await prefs.setString(_keyDocId, session.docId);
    await prefs.setString(_keyName, session.name);
  }

  /// The saved session, or null if nobody is signed in.
  Future<UserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    final role = prefs.getString(_keyRole);
    final docId = prefs.getString(_keyDocId);
    final name = prefs.getString(_keyName);
    if (username == null || role == null || docId == null || name == null) {
      return null;
    }
    return UserSession(username: username, role: role, docId: docId, name: name);
  }

  Future<bool> hasSession() async => (await getSession()) != null;

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyDocId);
    await prefs.remove(_keyName);
  }
}
