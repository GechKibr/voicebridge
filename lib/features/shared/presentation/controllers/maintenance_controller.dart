import 'package:flutter/material.dart';

import '../../../../core/models/maintenance_status.dart';
import '../../../../core/services/maintenance_service.dart';

class MaintenanceController with ChangeNotifier {
  final MaintenanceService _service = MaintenanceService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MaintenanceStatus _status = const MaintenanceStatus(
    isEnabled: false,
    message: '',
  );

  MaintenanceStatus get status => _status;
  bool get isMaintenanceMode => _status.isEnabled;
  String get message => _status.message;

  Future<void> loadStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _status = await _service.fetchStatus();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
