import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

enum ProductStatus { active, outOfStock, discontinued }

enum PackagingType {
  unit,
  sixpack,
  basket,
  pack,
  box,
  packCigarettes,
  halfPack,
}

String packagingTypeToDb(PackagingType type) {
  switch (type) {
    case PackagingType.packCigarettes:
      return 'pack_cigarettes';
    case PackagingType.halfPack:
      return 'half_pack';
    default:
      return type.name;
  }
}

String convertPackagingTypeFromDb(dynamic value) {
  if (value == null) return 'unit';
  final str = value.toString();
  switch (str) {
    case 'pack_cigarettes':
      return 'packCigarettes';
    case 'half_pack':
      return 'halfPack';
    default:
      return str;
  }
}

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required int code,
    required String name,
    required String brandId,
    required String categoryId,
    required String presentation,
    required PackagingType packagingType,
    required int unitsPerPackage,
    required double priceRetail,
    required double priceWholesale,
    required double cost,
    required int stockCurrent,
    required int stockMin,
    required int stockMax,
    @Default(ProductStatus.active) ProductStatus status,
    String? barcode,
    String? description,
    int? volumeMl,
    @Default(false) bool isCold,
    @Default(false) bool isReturnable,
    @Default(0) double returnableDeposit,
    double? priceWholesaleFractional,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => Product._fromJson(json);

  static Product _fromJson(Map<String, dynamic> json) {
    return _$ProductFromJson({
      ...json,
      'packagingType': convertPackagingTypeFromDb(json['packaging_type']),
      'priceRetail': (json['price_retail'] as num?)?.toDouble() ?? 0,
      'priceWholesale': (json['price_wholesale'] as num?)?.toDouble() ?? 0,
      'priceWholesaleFractional': (json['price_wholesale_fractional'] as num?)?.toDouble(),
      'returnableDeposit': (json['returnable_deposit'] as num?)?.toDouble() ?? 0,
      'cost': (json['cost'] as num?)?.toDouble() ?? 0,
      'unitsPerPackage': json['units_per_package'] ?? 1,
      'stockCurrent': json['stock_current'] ?? 0,
      'stockMin': json['stock_min'] ?? 5,
      'stockMax': json['stock_max'] ?? 100,
      'volumeMl': json['volume_ml'],
      'isCold': json['is_cold'] ?? false,
      'isReturnable': json['is_returnable'] ?? false,
      'imageUrl': json['image_url'],
      'brandId': json['brand_id'],
      'categoryId': json['category_id'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    });
  }
}

extension ProductSupabaseExtension on Product {
  Map<String, dynamic> toSupabaseJson() {
    final json = <String, dynamic>{
      'code': code,
      'brand_id': brandId,
      'category_id': categoryId,
      'name': name,
      'presentation': presentation,
      'packaging_type': packagingTypeToDb(packagingType),
      'units_per_package': unitsPerPackage,
      'is_cold': isCold,
      'is_returnable': isReturnable,
      'returnable_deposit': returnableDeposit,
      'price_retail': priceRetail,
      'price_wholesale': priceWholesale,
      'cost': cost,
      'stock_current': stockCurrent,
      'stock_min': stockMin,
      'stock_max': stockMax,
      'status': status.name,
    };

    if (barcode != null && barcode!.isNotEmpty) {
      json['barcode'] = barcode;
    }

    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }

    if (volumeMl != null) {
      json['volume_ml'] = volumeMl;
    }

    if (priceWholesaleFractional != null) {
      json['price_wholesale_fractional'] = priceWholesaleFractional;
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      json['image_url'] = imageUrl;
    }

    return json;
  }
}
