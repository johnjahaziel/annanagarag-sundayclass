import 'package:flutter/material.dart';

import '../models/main_class.dart';
import '../repositories/class_repository.dart';
import 'class_detail.dart';

class _DivisionEntry {
  const _DivisionEntry({required this.division, this.mainClassName});

  final String division;

  /// The parent main class name, shown as a "Part of X" subtitle — null
  /// when [division] *is* the main class itself (it has no divisions of
  /// its own), since that subtitle would just repeat the title.
  final String? mainClassName;
}

/// Shows every class division — reached from the Homepage's "Classes" stat
/// card. Tapping a card opens its [ClassDetail], same as the Homepage's
/// Class List panel.
class ClassesList extends StatefulWidget {
  const ClassesList({super.key});

  @override
  State<ClassesList> createState() => _ClassesListState();
}

class _ClassesListState extends State<ClassesList> {
  final _repository = ClassRepository();
  late Future<List<MainClass>> _future;

  static const _accentColor = Color(0xFFEF6C00);

  @override
  void initState() {
    super.initState();
    _future = _repository.getMainClasses();
  }

  void _retry() {
    setState(() {
      _future = _repository.getMainClasses();
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
          'Classes',
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
      body: FutureBuilder<List<MainClass>>(
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
          final mainClasses = snapshot.data ?? const [];
          final entries = <_DivisionEntry>[
            for (final mainClass in mainClasses)
              for (final division in mainClass.displayClassNames)
                _DivisionEntry(
                  division: division,
                  mainClassName: mainClass.divisions.isEmpty
                      ? null
                      : mainClass.name,
                ),
          ];
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No classes yet — add one to get started.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClassDetail(className: entry.division),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              Icons.class_,
                              color: _accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.division,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (entry.mainClassName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Part of ${entry.mainClassName}',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: _accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
