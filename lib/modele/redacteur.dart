class Redacteur {
  int? id;
  String nom;
  String prenom;
  String email;

  // Constructeur avec id (pour les données existantes)
  Redacteur({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
  });

  // Constructeur sans id (pour les nouveaux rédacteurs)
  Redacteur.sansId({
    required this.nom,
    required this.prenom,
    required this.email,
  });

  // Convertir un objet Redacteur en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
    };
  }

  // Créer un objet Redacteur à partir d'un Map
  factory Redacteur.fromMap(Map<String, dynamic> map) {
    return Redacteur(
      id: map['id'],
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
    );
  }

  // Validation du format email
  static bool estEmailValide(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  @override
  String toString() {
    return 'Redacteur{id: $id, nom: $nom, prenom: $prenom, email: $email}';
  }
}