import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_config.freezed.dart';
part 'delivery_config.g.dart';

enum DeliveryAssignmentMode {
  automatic,
  manual,
}

extension DeliveryAssignmentModeX on DeliveryAssignmentMode {
  String get label {
    switch (this) {
      case DeliveryAssignmentMode.automatic:
        return 'Automático';
      case DeliveryAssignmentMode.manual:
        return 'Manual';
    }
  }

  String get description {
    switch (this) {
      case DeliveryAssignmentMode.automatic:
        return 'Asigna el pedido al domiciliario menos ocupado al crearlo.';
      case DeliveryAssignmentMode.manual:
        return 'Deja el pedido sin domiciliario hasta que se asigne manualmente.';
    }
  }
}

@freezed
class DeliveryConfig with _$DeliveryConfig {
  const factory DeliveryConfig({
    @Default(DeliveryAssignmentMode.manual) DeliveryAssignmentMode assignmentMode,
  }) = _DeliveryConfig;

  factory DeliveryConfig.fromJson(Map<String, dynamic> json) =>
      _$DeliveryConfigFromJson(json);
}
