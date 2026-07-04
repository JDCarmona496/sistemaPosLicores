import 'package:freezed_annotation/freezed_annotation.dart';

part 'printer_config.freezed.dart';
part 'printer_config.g.dart';

enum PrinterConnectionType {
  bluetooth,
  usb,
  serial,
  wifi,
  windows,
}

extension PrinterConnectionTypeX on PrinterConnectionType {
  String get label {
    switch (this) {
      case PrinterConnectionType.bluetooth:
        return 'Bluetooth';
      case PrinterConnectionType.usb:
        return 'USB';
      case PrinterConnectionType.serial:
        return 'Puerto COM';
      case PrinterConnectionType.wifi:
        return 'WiFi / Red';
      case PrinterConnectionType.windows:
        return 'Impresora Windows';
    }
  }
}

@freezed
class PrinterConfig with _$PrinterConfig {
  const factory PrinterConfig({
    required PrinterConnectionType connectionType,
    String? address,
    String? name,
    @Default('COM1') String comPort,
    @Default(9600) int baudRate,
    @Default(58) int paperWidthMm,
    @Default(true) bool autoPrintOnSale,
    @Default(2) int copies,
  }) = _PrinterConfig;

  factory PrinterConfig.fromJson(Map<String, dynamic> json) =>
      _$PrinterConfigFromJson(json);
}
