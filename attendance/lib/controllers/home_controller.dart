import 'package:get/get.dart';

import '../models/main_class.dart';
import '../repositories/class_repository.dart';

/// Loads the main classes (and their divisions) shown in the Homepage's
/// Class List panel.
class HomeController extends GetxController {
  HomeController({ClassRepository? repository})
    : _repository = repository ?? ClassRepository();

  final ClassRepository _repository;

  final mainClasses = <MainClass>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadClasses();
  }

  Future<void> loadClasses() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      mainClasses.value = await _repository.getMainClasses();
    } catch (e) {
      loadError.value = 'Failed to load classes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// All division names across every main class, in display order.
  List<String> get divisionNames =>
      mainClasses.expand((mainClass) => mainClass.divisions).toList();
}
