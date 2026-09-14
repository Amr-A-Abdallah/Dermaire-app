enum ProductCategory {
  cleanser,
  toner,
  serum,
  moisturizer,
  treatment,
  sunscreen,
  other,
}

enum ProductStatus { active, inactive, archived }

enum UsageTime { morning, evening, both, asNeeded }

enum ProductSort { recentlyUpdated, name, newest, rating }

enum InteractionRisk { safe, conflict, unknown }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.brand,
    this.productType,
    this.activeIngredients = const [],
    this.skinConcerns = const [],
    this.usageInstructions = '',
    this.frequencyPerWeek = 1,
    this.timeOfUse = UsageTime.evening,
    this.startDate,
    this.endDate,
    this.status = ProductStatus.active,
    this.notes,
    this.imagePath,
    this.tags = const [],
    this.rating,
    this.inRoutine = true,
    this.inExperiment = false,
  });

  final String id;
  final String name;
  final String? brand;
  final ProductCategory category;
  final String? productType;
  final List<String> activeIngredients;
  final List<String> skinConcerns;
  final String usageInstructions;
  final int frequencyPerWeek;
  final UsageTime timeOfUse;
  final DateTime? startDate;
  final DateTime? endDate;
  final ProductStatus status;
  final String? notes;
  final String? imagePath;
  final List<String> tags;
  final double? rating;
  final bool inRoutine;
  final bool inExperiment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    bool clearBrand = false,
    ProductCategory? category,
    String? productType,
    List<String>? activeIngredients,
    List<String>? skinConcerns,
    String? usageInstructions,
    int? frequencyPerWeek,
    UsageTime? timeOfUse,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    ProductStatus? status,
    String? notes,
    bool clearNotes = false,
    String? imagePath,
    List<String>? tags,
    double? rating,
    bool? inRoutine,
    bool? inExperiment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: clearBrand ? null : brand ?? this.brand,
    category: category ?? this.category,
    productType: productType ?? this.productType,
    activeIngredients: activeIngredients ?? this.activeIngredients,
    skinConcerns: skinConcerns ?? this.skinConcerns,
    usageInstructions: usageInstructions ?? this.usageInstructions,
    frequencyPerWeek: frequencyPerWeek ?? this.frequencyPerWeek,
    timeOfUse: timeOfUse ?? this.timeOfUse,
    startDate: startDate ?? this.startDate,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    status: status ?? this.status,
    notes: clearNotes ? null : notes ?? this.notes,
    imagePath: imagePath ?? this.imagePath,
    tags: tags ?? this.tags,
    rating: rating ?? this.rating,
    inRoutine: inRoutine ?? this.inRoutine,
    inExperiment: inExperiment ?? this.inExperiment,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category.name,
    'productType': productType,
    'activeIngredients': activeIngredients,
    'skinConcerns': skinConcerns,
    'usageInstructions': usageInstructions,
    'frequencyPerWeek': frequencyPerWeek,
    'timeOfUse': timeOfUse.name,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'status': status.name,
    'notes': notes,
    'imagePath': imagePath,
    'tags': tags,
    'rating': rating,
    'inRoutine': inRoutine,
    'inExperiment': inExperiment,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, Object?> json) {
    T enumValue<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.where((value) => value.name == name).firstOrNull ?? fallback;
    List<String> strings(String key) =>
        (json[key] as List<Object?>? ?? []).whereType<String>().toList();
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      category: enumValue(
        ProductCategory.values,
        json['category'] as String?,
        ProductCategory.other,
      ),
      productType: json['productType'] as String?,
      activeIngredients: strings('activeIngredients'),
      skinConcerns: strings('skinConcerns'),
      usageInstructions: json['usageInstructions'] as String? ?? '',
      frequencyPerWeek: json['frequencyPerWeek'] as int? ?? 1,
      timeOfUse: enumValue(
        UsageTime.values,
        json['timeOfUse'] as String?,
        UsageTime.evening,
      ),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      status: enumValue(
        ProductStatus.values,
        json['status'] as String?,
        ProductStatus.active,
      ),
      notes: json['notes'] as String?,
      imagePath: json['imagePath'] as String?,
      tags: strings('tags'),
      rating: (json['rating'] as num?)?.toDouble(),
      inRoutine: json['inRoutine'] as bool? ?? true,
      inExperiment: json['inExperiment'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

extension ProductCategoryLabel on ProductCategory {
  String get label => switch (this) {
    ProductCategory.cleanser => 'Cleanser',
    ProductCategory.toner => 'Toner',
    ProductCategory.serum => 'Serum',
    ProductCategory.moisturizer => 'Moisturizer',
    ProductCategory.treatment => 'Treatment',
    ProductCategory.sunscreen => 'Sunscreen',
    ProductCategory.other => 'Other',
  };

  String get icon => switch (this) {
    ProductCategory.cleanser => '🧼',
    ProductCategory.toner => '💦',
    ProductCategory.serum => '🧪',
    ProductCategory.moisturizer => '💧',
    ProductCategory.treatment => '🧴',
    ProductCategory.sunscreen => '☀️',
    ProductCategory.other => '🌿',
  };
}

extension UsageTimeLabel on UsageTime {
  String get label => switch (this) {
    UsageTime.morning => 'Morning',
    UsageTime.evening => 'Evening',
    UsageTime.both => 'Morning & evening',
    UsageTime.asNeeded => 'As needed',
  };
}
