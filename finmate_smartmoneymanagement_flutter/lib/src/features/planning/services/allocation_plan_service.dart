import '../../../core/network/api_client.dart';

class AllocationPlan {
  const AllocationPlan({
    required this.necessary,
    required this.accumulation,
    required this.flexibility,
  });

  final double necessary;
  final double accumulation;
  final double flexibility;
}

class AllocationPlanService {
  AllocationPlanService({ApiClient? client}) : _client = client ?? ApiClient();

  static const double _defaultNecessary = 60;
  static const double _defaultAccumulation = 20;
  static const double _defaultFlexibility = 20;

  final ApiClient _client;

  Future<AllocationPlan> getAllocationPlan() async {
    final data = await _client.get('/api/settings');
    return _fromSettings(data as Map<String, dynamic>);
  }

  Future<AllocationPlan> saveAllocationPlan({
    required double necessary,
    required double accumulation,
    required double flexibility,
  }) async {
    final body = {
      'necessaryAllocationPercent': necessary.round(),
      'accumulationAllocationPercent': accumulation.round(),
      'flexibilityAllocationPercent': flexibility.round(),
    };
    final data = await _client.put('/api/settings', body: body);
    return _fromSettings(data as Map<String, dynamic>);
  }

  AllocationPlan _fromSettings(Map<String, dynamic> json) {
    return AllocationPlan(
      necessary: _toDouble(
        json['necessaryAllocationPercent'],
        fallback: _defaultNecessary,
      ),
      accumulation: _toDouble(
        json['accumulationAllocationPercent'],
        fallback: _defaultAccumulation,
      ),
      flexibility: _toDouble(
        json['flexibilityAllocationPercent'],
        fallback: _defaultFlexibility,
      ),
    );
  }

  double _toDouble(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
