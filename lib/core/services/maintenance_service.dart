import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/backend_endpoints.dart';
import '../models/maintenance_status.dart';

class MaintenanceService {
  Future<MaintenanceStatus> fetchStatus() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.maintenance),
      headers: const {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      return const MaintenanceStatus(isEnabled: false, message: '');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return MaintenanceStatus.fromJson(decoded);
    }

    return const MaintenanceStatus(isEnabled: false, message: '');
  }
}
