import 'package:flutter/material.dart';

import '../models/admin.dart';
import '../repositories/admin_repository.dart';

/// Shows every admin — name, phone, and gender — reached from the
/// Homepage's "Admins" stat card.
class AdminsList extends StatefulWidget {
  const AdminsList({super.key});

  @override
  State<AdminsList> createState() => _AdminsListState();
}

class _AdminsListState extends State<AdminsList> {
  final _repository = AdminRepository();
  late Future<List<Admin>> _future;

  static const _accentColor = Color(0xFFEC407A);

  @override
  void initState() {
    super.initState();
    _future = _repository.getAdmins();
  }

  void _retry() {
    setState(() {
      _future = _repository.getAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Admins',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Admin>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _retry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final admins = snapshot.data ?? const [];
          if (admins.isEmpty) {
            return const Center(
              child: Text(
                'No admins yet — add one to get started.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        color: _accentColor.withValues(alpha: 0.1),
                      ),
                      child: ClipOval(
                        child: admin.photoUrl != null && admin.photoUrl!.isNotEmpty
                            ? Image.network(
                                admin.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  admin.gender == 'Female'
                                      ? Icons.face_3
                                      : Icons.face,
                                  color: _accentColor,
                                  size: 28,
                                ),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _accentColor,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Icon(
                                admin.gender == 'Female'
                                    ? Icons.face_3
                                    : Icons.face,
                                color: _accentColor,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            admin.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1E3A5F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 13, color: _accentColor),
                              const SizedBox(width: 4),
                              Text(
                                admin.phone,
                                style: const TextStyle(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
