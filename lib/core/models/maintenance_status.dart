class MaintenanceStatus {
  final bool isEnabled;
  final String message;

  const MaintenanceStatus({
    required this.isEnabled,
    required this.message,
  });

  factory MaintenanceStatus.fromJson(Map<String, dynamic> json) {
    final enabled = json['is_maintenance_mode'] == true ||
        json['isMaintenanceMode'] == true ||
        json['maintenance_mode'] == true ||
        json['enabled'] == true;

    return MaintenanceStatus(
      isEnabled: enabled,
      message: (json['message'] ?? json['maintenance_message'] ?? '')
          .toString()
          .trim(),
    );
  }
}
