import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.nom,
    super.description,
    required super.categorie,
    required super.prix,
    super.unite,
    required super.quantiteDisponible,
    super.localisation,
    required super.images,
    required super.vendeurId,
    super.vendeurNom,
    super.vendeurTelephone,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      categorie: json['categorie'],
      prix: (json['prix'] is num) 
          ? (json['prix'] as num).toDouble() 
          : double.tryParse(json['prix'].toString()) ?? 0.0,
      unite: json['unite'],
      quantiteDisponible: (json['quantite_disponible'] is num)
          ? (json['quantite_disponible'] as num).toDouble()
          : double.tryParse(json['quantite_disponible'].toString()) ?? 0.0,
      localisation: json['localisation'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      vendeurId: json['vendeur_id'],
      vendeurNom: json['vendeur_nom'],
      vendeurTelephone: json['vendeur_telephone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'prix': prix,
      'unite': unite,
      'quantite_disponible': quantiteDisponible,
      'localisation': localisation,
      'images': images,
      'vendeur_id': vendeurId,
      'vendeur_nom': vendeurNom,
      'vendeur_telephone': vendeurTelephone,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
