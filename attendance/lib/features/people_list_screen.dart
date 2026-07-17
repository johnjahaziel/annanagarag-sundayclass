import 'package:flutter/material.dart';

import '../models/service.dart';

/// A minimal view-model shared by Teachers/Students/Admins list screens —
/// just enough to render a [PeopleListScreen] card.
class PersonListItem {
  const PersonListItem({
    required this.name,
    required this.phone,
    required this.assignedClass,
    required this.service,
    this.photoUrl,
    this.onTap,
  });

  final String name;
  final String phone;
  final String assignedClass;

  /// Which Sunday service this person belongs to — see [Service].
  final String service;
  final String? photoUrl;

  /// Opens this person's detail screen, if one is wired up by the caller.
  final VoidCallback? onTap;

  /// Whether this person matches a search [query] against name, phone,
  /// service, or class — case-insensitive substring match.
  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        phone.toLowerCase().contains(q) ||
        service.toLowerCase().contains(q) ||
        assignedClass.toLowerCase().contains(q);
  }
}

/// Color-codes a service the same way everywhere it's shown — Service 1
/// sky blue, Service 2 magenta — so it's recognizable at a glance.
Color serviceColor(String service) {
  return service == Service.two
      ? const Color(0xFFAB47BC)
      : const Color(0xFF29B6F6);
}

/// Reusable "people" list screen used by the Teachers, Students, and Admins
/// pages reached from the Homepage's stat cards — same rectangular-card
/// look, different data source.
class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({
    super.key,
    required this.title,
    required this.accentColor,
    required this.icon,
    required this.emptyMessage,
    required this.loader,
  });

  final String title;
  final Color accentColor;
  final IconData icon;
  final String emptyMessage;
  final Future<List<PersonListItem>> Function() loader;

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  late Future<List<PersonListItem>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: widget.accentColor,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, service, or class',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: widget.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: widget.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: widget.accentColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PersonListItem>>(
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
                          TextButton(
                            onPressed: _retry,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final people = snapshot.data ?? const [];
                if (people.isEmpty) {
                  return Center(
                    child: Text(
                      widget.emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }
                final filtered = people
                    .where((person) => person.matches(_query))
                    .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No matches for "$_query"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final person = filtered[index];
                    return _PersonCard(
                      person: person,
                      accentColor: widget.accentColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.accentColor});

  final PersonListItem person;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: person.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    color: accentColor.withValues(alpha: 0.1),
                  ),
                  child: ClipOval(
                    child:
                        person.photoUrl != null && person.photoUrl!.isNotEmpty
                        ? Image.network(
                            person.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: accentColor,
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
                                    color: accentColor,
                                  ),
                                ),
                              );
                            },
                          )
                        : Icon(Icons.person, color: accentColor, size: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
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
                          Icon(Icons.class_, size: 13, color: accentColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              person.assignedClass,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _ServiceBadge(service: person.service),
                    ],
                  ),
                ),
                if (person.onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small colored pill showing which service a teacher/student belongs to
/// — Service 1 sky blue, Service 2 magenta, so it reads at a glance.
class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.service});

  final String service;

  @override
  Widget build(BuildContext context) {
    final color = serviceColor(service);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        service,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
