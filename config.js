/* Réglages du site Bio d’Ivoire — ce fichier est lu par la boutique (index.html) et par l'espace administrateur (admin.html). */
window.BIO_CONFIG = {
  /* Base de données Supabase. Tant que ces deux lignes sont vides, le site est en mode démonstration :
     les commandes restent sur l'appareil du visiteur et n'arrivent pas à l'administrateur. */
  SUPABASE_URL: '',
  SUPABASE_ANON_KEY: '',

  /* Point de départ des livraisons (position de la boutique). Par défaut : centre de Bouaké — à remplacer par la vraie position. */
  BOUTIQUE: { lat: 7.6906, lng: -5.0297 },

  /* Livraison gratuite à partir de ce montant d'achat (FCFA). */
  LIVRAISON_GRATUITE: 20000,

  /* Frais de livraison selon la distance (km, en ligne droite depuis la boutique).
     Au-delà de la dernière tranche, le prix est « à confirmer par téléphone ». */
  TARIFS: [
    { jusqua: 3,  prix: 500 },
    { jusqua: 6,  prix: 1000 },
    { jusqua: 10, prix: 1500 },
    { jusqua: 20, prix: 2500 }
  ]
};
