import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../modele/redacteur.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;
  DatabaseManager._internal();

  static Database? _database;

  // Getter pour la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialisation de la base de données
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'redacteurs.db');
    print('📁 Chemin de la base : $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Création de la table redacteurs
  Future<void> _onCreate(Database db, int version) async {
    print('🛠️ Création de la table redacteurs...');
    await db.execute('''
      CREATE TABLE redacteurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');
    print('✅ Table redacteurs créée avec succès');
  }

  // Récupérer tous les rédacteurs
  Future<List<Redacteur>> getAllRedacteurs() async {
    print('📋 Récupération de tous les rédacteurs...');
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('redacteurs');
    print('📋 ${maps.length} rédacteurs trouvés');
    return List.generate(maps.length, (i) {
      return Redacteur.fromMap(maps[i]);
    });
  }

  // Insérer un rédacteur
  Future<int> insertRedacteur(Redacteur redacteur) async {
    print('📝 Insertion du rédacteur : ${redacteur.nom} ${redacteur.prenom}');
    Database db = await database;
    int id = await db.insert(
      'redacteurs',
      redacteur.toMap(),
    );
    print('✅ Rédacteur inséré avec l\'ID : $id');
    return id;
  }

  // Mettre à jour un rédacteur
  Future<int> updateRedacteur(Redacteur redacteur) async {
    print('📝 Mise à jour du rédacteur ID ${redacteur.id}');
    Database db = await database;
    int count = await db.update(
      'redacteurs',
      redacteur.toMap(),
      where: 'id = ?',
      whereArgs: [redacteur.id],
    );
    print('✅ $count ligne(s) mise(s) à jour');
    return count;
  }

  // Supprimer un rédacteur
  Future<int> deleteRedacteur(int id) async {
    print('📝 Suppression du rédacteur ID $id');
    Database db = await database;
    int count = await db.delete(
      'redacteurs',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('✅ $count ligne(s) supprimée(s)');
    return count;
  }

  // Supprimer tous les rédacteurs (optionnel)
  Future<void> deleteAllRedacteurs() async {
    print('📝 Suppression de tous les rédacteurs');
    Database db = await database;
    await db.delete('redacteurs');
    print('✅ Tous les rédacteurs ont été supprimés');
  }
}