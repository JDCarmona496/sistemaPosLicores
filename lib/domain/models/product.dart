import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_helpers.dart';

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

PackagingType? _packagingTypeFromDb(String value) {
  switch (value) {
    case 'pack_cigarettes':
      return PackagingType.packCigarettes;
    case 'half_pack':
      return PackagingType.halfPack;
    default:
      return PackagingType.values.cast<PackagingType?>().firstWhere(
            (e) => e?.name == value,
            orElse: () => null,
          );
  }
}

ProductStatus? _productStatusFromDb(String value) {
  return ProductStatus.values.cast<ProductStatus?>().firstWhere(
        (e) => e?.name == value,
        orElse: () => null,
      );
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
      'packagingType': jsonEnum(
        json['packaging_type'],
        _packagingTypeFromDb,
        defaultValue: PackagingType.unit,
      ).name,
      'priceRetail': jsonDouble(json['price_retail']),
      'priceWholesale': jsonDouble(json['price_wholesale']),
      'priceWholesaleFractional':
          jsonDouble(json['price_wholesale_fractional']),
      'returnableDeposit': jsonDouble(json['returnable_deposit']),
      'cost': jsonDouble(json['cost']),
      'unitsPerPackage': jsonInt(json['units_per_package'], defaultValue: 1),
      'stockCurrent': jsonInt(json['stock_current']),
      'stockMin': jsonInt(json['stock_min'], defaultValue: 5),
      'stockMax': jsonInt(json['stock_max'], defaultValue: 100),
      'volumeMl': json['volume_ml'] == null ? null : jsonInt(json['volume_ml']),
      'isCold': jsonBool(json['is_cold']),
      'isReturnable': jsonBool(json['is_returnable']),
      'status': jsonEnum(
        json['status'],
        _productStatusFromDb,
        defaultValue: ProductStatus.active,
      ).name,
      'imageUrl': jsonString(json['image_url']),
      'brandId': jsonStringRequired(json['brand_id']),
      'categoryId': jsonStringRequired(json['category_id']),
      'createdAt': jsonDateTime(json['created_at']),
      'updatedAt': jsonDateTime(json['updated_at']),
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
