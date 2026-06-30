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

  // Liste des rédacteurs
  List<Redacteur> _redacteurs = [];

  // Instance du DatabaseManager
  final DatabaseManager _dbManager = DatabaseManager();

  @override
  void initState() {
    super.initState();
    _chargerRedacteurs();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Charger tous les rédacteurs depuis la base
  Future<void> _chargerRedacteurs() async {
    print('🔄 Chargement des rédacteurs...');
    try {
      List<Redacteur> redacteurs = await _dbManager.getAllRedacteurs();
      setState(() {
        _redacteurs = redacteurs;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement : $e');
      _showSnackBar('Erreur lors du chargement des données', Colors.red);
    }
  }

  // Ajouter un rédacteur
  Future<void> _ajouterRedacteur() async {
    print('=== AJOUT D\'UN RÉDACTEUR ===');
    
    String nom = _nomController.text.trim();
    String prenom = _prenomController.text.trim();
    String email = _emailController.text.trim();

    print('Nom : "$nom"');
    print('Prénom : "$prenom"');
    print('Email : "$email"');

    // Validation des champs
    if (nom.isEmpty || prenom.isEmpty || email.isEmpty) {
      print('❌ Champs vides détectés');
      _showSnackBar('Veuillez remplir tous les champs', Colors.red);
      return;
    }

    // Créer un nouveau rédacteur sans id
    Redacteur nouveau = Redacteur.sansId(
      nom: nom,
      prenom: prenom,
      email: email,
    );

    try {
      // Insérer dans la base
      int id = await _dbManager.insertRedacteur(nouveau);
      print('✅ Insertion réussie, ID : $id');

      // Vider les champs
      _nomController.clear();
      _prenomController.clear();
      _emailController.clear();

      // Recharger la liste
      await _chargerRedacteurs();
      _showSnackBar('Rédacteur ajouté avec succès', Colors.green);
    } catch (e) {
      print('❌ Erreur lors de l\'insertion : $e');
      _showSnackBar('Erreur lors de l\'ajout du rédacteur', Colors.red);
    }
    
    print('=== FIN AJOUT ===');
  }

  // Modifier un rédacteur
  Future<void> _modifierRedacteur(Redacteur redacteur) async {
    print('=== MODIFICATION RÉDACTEUR ID ${redacteur.id} ===');
    
    // Contrôleurs pré-remplis
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
                  _showSnackBar('Rédacteur modifié avec succès', Colors.orange);
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
    print('=== SUPPRESSION RÉDACTEUR ID ${redacteur.id} ===');
    
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
                  _showSnackBar('Rédacteur supprimé avec succès', Colors.red);
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

  // Afficher un message SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Zone de saisie
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _ajouterRedacteur,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter un Rédacteur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Liste des rédacteurs
            Expanded(
              child: _redacteurs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Aucun rédacteur enregistré',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Ajoutez votre premier rédacteur !',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _redacteurs.length,
                      itemBuilder: (context, index) {
                        Redacteur redacteur = _redacteurs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.pink.shade100,
                              child: Text(
                                redacteur.prenom[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                            title: Text(
                              '${redacteur.prenom} ${redacteur.nom}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(redacteur.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _modifierRedacteur(redacteur),
                                  tooltip: 'Modifier',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimerRedacteur(redacteur),
                                  tooltip: 'Supprimer',
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