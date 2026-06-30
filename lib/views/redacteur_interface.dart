import 'package:flutter/material.dart';
import '../modele/redacteur.dart';
import '../services/database_manager.dart';

class RedacteurInterface extends StatefulWidget {
  const RedacteurInterface({super.key});

  @override
  State<RedacteurInterface> createState() => _RedacteurInterfaceState();
}

class _RedacteurInterfaceState extends State<RedacteurInterface> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Contrôleur pour la recherche
  final TextEditingController _searchController = TextEditingController();

  // Liste des rédacteurs
  List<Redacteur> _redacteurs = [];
  List<Redacteur> _redacteursFiltres = [];

  // Instance du DatabaseManager
  final DatabaseManager _dbManager = DatabaseManager();

  @override
  void initState() {
    super.initState();
    _chargerRedacteurs();
    _searchController.addListener(_filtrerRedacteurs);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Charger tous les rédacteurs depuis la base
  Future<void> _chargerRedacteurs() async {
    print('🔄 Chargement des rédacteurs...');
    try {
      List<Redacteur> redacteurs = await _dbManager.getAllRedacteurs();
      redacteurs.sort((a, b) => a.nom.compareTo(b.nom));
      setState(() {
        _redacteurs = redacteurs;
        _redacteursFiltres = redacteurs;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement : $e');
      _showSnackBar('Erreur lors du chargement des données', Colors.red);
    }
  }

  // Filtrer les rédacteurs
  void _filtrerRedacteurs() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _redacteursFiltres = _redacteurs;
      } else {
        _redacteursFiltres = _redacteurs.where((redacteur) {
          return redacteur.nom.toLowerCase().contains(query) ||
              redacteur.prenom.toLowerCase().contains(query) ||
              redacteur.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Valider le format de l'email
  bool _validerEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  // Ajouter un rédacteur
  Future<void> _ajouterRedacteur() async {
    print('=== AJOUT D\'UN RÉDACTEUR ===');

    String nom = _nomController.text.trim();
    String prenom = _prenomController.text.trim();
    String email = _emailController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || email.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs', Colors.red);
      return;
    }

    if (!_validerEmail(email)) {
      _showSnackBar('Format d\'email invalide', Colors.red);
      return;
    }

    Redacteur nouveau = Redacteur.sansId(
      nom: nom,
      prenom: prenom,
      email: email,
    );

    try {
      await _dbManager.insertRedacteur(nouveau);
      _nomController.clear();
      _prenomController.clear();
      _emailController.clear();
      await _chargerRedacteurs();
      _showSnackBar('✅ Rédacteur ajouté avec succès', Colors.green);
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout du rédacteur', Colors.red);
    }
  }

  // Modifier un rédacteur
  Future<void> _modifierRedacteur(Redacteur redacteur) async {
    TextEditingController nomCtrl = TextEditingController(text: redacteur.nom);
    TextEditingController prenomCtrl = TextEditingController(text: redacteur.prenom);
    TextEditingController emailCtrl = TextEditingController(text: redacteur.email);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier le rédacteur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomCtrl,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                String nom = nomCtrl.text.trim();
                String prenom = prenomCtrl.text.trim();
                String email = emailCtrl.text.trim();

                if (nom.isEmpty || prenom.isEmpty || email.isEmpty) {
                  _showSnackBar('Veuillez remplir tous les champs', Colors.red);
                  return;
                }

                if (!_validerEmail(email)) {
                  _showSnackBar('Format d\'email invalide', Colors.red);
                  return;
                }

                Redacteur modifie = Redacteur(
                  id: redacteur.id,
                  nom: nom,
                  prenom: prenom,
                  email: email,
                );

                try {
                  await _dbManager.updateRedacteur(modifie);
                  Navigator.pop(context);
                  await _chargerRedacteurs();
                  _showSnackBar('✅ Rédacteur modifié avec succès', Colors.orange);
                } catch (e) {
                  _showSnackBar('Erreur lors de la modification', Colors.red);
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );
  }

  // Supprimer un rédacteur
  Future<void> _supprimerRedacteur(Redacteur redacteur) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${redacteur.prenom} ${redacteur.nom} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dbManager.deleteRedacteur(redacteur.id!);
                  Navigator.pop(context);
                  await _chargerRedacteurs();
                  _showSnackBar('🗑️ Rédacteur supprimé avec succès', Colors.red);
                } catch (e) {
                  _showSnackBar('Erreur lors de la suppression', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // Vider tous les rédacteurs
  Future<void> _viderTousLesRedacteurs() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Attention'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer TOUS les rédacteurs ?\n\nCette action est irréversible !',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dbManager.deleteAllRedacteurs();
                  Navigator.pop(context);
                  await _chargerRedacteurs();
                  _showSnackBar('🗑️ Tous les rédacteurs ont été supprimés', Colors.red);
                } catch (e) {
                  _showSnackBar('Erreur lors de la suppression', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tout supprimer'),
            ),
          ],
        );
      },
    );
  }

  // Afficher un message SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Rédacteurs'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _redacteurs.isEmpty ? null : _viderTousLesRedacteurs,
            tooltip: 'Supprimer tous les rédacteurs',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Réduit de 16 à 8
        child: Column(
          children: [
            // Zone de saisie - Plus compacte
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Réduit de 16 à 12
                child: Column(
                  children: [
                    // Champs plus compacts
                    TextField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                        helperText: 'exemple@domaine.com',
                        helperStyle: TextStyle(fontSize: 10),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _ajouterRedacteur,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter un Rédacteur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Champ de recherche
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher un rédacteur',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Liste des rédacteurs - avec Expanded pour prendre tout l'espace restant
            Expanded(
              child: _redacteursFiltres.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Aucun rédacteur enregistré',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            'Ajoutez votre premier rédacteur !',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _redacteursFiltres.length,
                      itemBuilder: (context, index) {
                        Redacteur redacteur = _redacteursFiltres[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            dense: true, // Réduit la hauteur des ListTile
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.pink.shade100,
                              child: Text(
                                redacteur.prenom[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              '${redacteur.prenom} ${redacteur.nom}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              redacteur.email,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                  onPressed: () => _modifierRedacteur(redacteur),
                                  tooltip: 'Modifier',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _supprimerRedacteur(redacteur),
                                  tooltip: 'Supprimer',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}