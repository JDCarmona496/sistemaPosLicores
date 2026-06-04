import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

enum ProductStatus { active, outOfStock, discontinued }

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String code,
    required String name,
    required String brandId,
    required String categoryId,
    required String presentation,
    required String packagingType,
    required int packagingQuantity,
    required double unitPrice,
    required double wholesalePrice,
    @Default(ProductStatus.active) ProductStatus status,
    @Default(0) int stock,
    @Default(0) int minStock,
    String? barcode,
    bool? isCold,
    bool? hasReturnableBasket,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
