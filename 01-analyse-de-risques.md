# Contexte, cadre légal et analyse de risques

> Les noms de domaine, de machines, de comptes et de tiers qui apparaissent ici sont fictifs. Les captures proviennent d'un laboratoire.

## Le contexte

Une PME agroalimentaire, sans informaticien interne. Toute son informatique est confiée à un prestataire d'infogérance, celui chez qui j'ai effectué mon stage.

L'entreprise est passée d'une affaire familiale à un fournisseur référencé, avec des contrats en grande distribution et en restauration collective institutionnelle. Elle vend aussi en boutique et en ligne, ce qui implique des données personnelles de clients et des paiements par carte.

Deux conséquences comptent pour la suite. L'activité dépend entièrement du maintien de la chaîne du froid, et les engagements pris auprès des clients rendent toute interruption contractuellement coûteuse.

## Le périmètre

Cette analyse ne porte pas sur l'ensemble du système d'information. Elle porte sur **un vecteur : l'accès distant du prestataire frigoriste**, et sur l'infrastructure telle qu'elle était **après** la migration réalisée pendant mon stage.

Ce cadrage est important. La migration avait déjà traité l'obsolescence du système, la redondance matérielle et la sauvegarde. Ce qu'elle n'avait pas touché, c'est le pare-feu : une règle NAT redirigeait toujours le port 3389 depuis Internet vers le serveur applicatif, et le prestataire frigoriste s'y connectait en RDP direct.

## Le cadre légal et les référentiels

Je sépare ce qui oblige de ce qui explique comment faire.

### Ce qui oblige

**RGPD, article 32.** Le responsable du traitement met en œuvre les mesures techniques appropriées afin de garantir un niveau de sécurité adapté au risque. L'article 33 impose la notification à la CNIL sous 72 heures en cas de violation. L'entreprise traite des données RH, des données de clients en ligne et des paiements : elle est pleinement concernée.

**NIS2, article 21 §2.d, par effet indirect.** La directive ne s'applique pas à une PME de cette taille. Elle s'applique à certains de ses clients, qui sont des entités essentielles, et leur impose de tenir compte de la qualité des pratiques de cybersécurité de leurs fournisseurs. La sécurité de la PME devient donc une condition de la relation commerciale.

**PCI DSS.** L'activité de vente par carte place l'entreprise dans le champ du standard, dont l'exigence 11.4 porte sur la détection des intrusions.

### Ce qui explique comment faire

**ANSSI, guide d'hygiène informatique.** Trois mesures retenues : la 29 sur le VPN avec authentification forte et la non-exposition des interfaces d'administration sur Internet, la 14 sur la sauvegarde, la 20 sur les sondes de détection.

**CERT-FR.** Une alerte énonce que le protocole RDP ne doit pas être directement exposé sur Internet et que son utilisation doit passer par un accès VPN. Elle réaffirme une alerte bien plus ancienne sur le filtrage du port 3389 au pare-feu frontière.

La configuration trouvée chez le client était donc déconseillée depuis des années, par l'autorité nationale, par écrit.

## La méthode

L'analyse est **inspirée d'EBIOS Risk Manager**, la méthode recommandée par l'ANSSI. Je n'en ai pas appliqué le déroulé complet : j'en ai repris le principe qui change tout, **partir des valeurs métier au lieu de partir des actifs techniques**.

La suite n'est pas une cotation théorique. Chaque scénario de risque a été éprouvé par un test, et c'est le résultat observé qui en détermine la gravité.

La question habituelle, « quelles données faut-il protéger », mène aux données RH, aux clients et aux paiements. Une autre question donne une réponse différente : **qu'est-ce qui arrête cette entreprise ?**

Ce n'est pas la fuite d'un fichier. C'est la chambre froide.

## Valeurs métier

| | Valeur métier | Criticité | Ce qui est en jeu |
|---|---|---|---|
| **VM1** | **Chaîne du froid** | **CRITIQUE** | Arrêt total d'activité, perte de la marchandise, rupture des engagements clients |
| VM2 | Données commerciales | Élevée | Contrats, conditions tarifaires et plannings de livraison des clients grands comptes |
| VM3 | Données personnelles | Élevée | RH des salariés, clients du canal de vente en ligne, données de paiement |
| VM4 | Continuité de l'application de gestion | Moyenne | Commandes, facturation, stocks |

VM1 est prioritaire, et ce classement commande tout ce qui suit.

## Événements redoutés

| | Événement redouté | Valeurs impactées |
|---|---|---|
| ER1 | Perte de supervision de la chaîne du froid | VM1 |
| ER2 | Compromission ou fuite de données sensibles | VM2, VM3 |
| ER3 | Indisponibilité des systèmes critiques | VM1, VM4 |
| ER4 | Incident entraînant des sanctions réglementaires | VM3 |

ER1 mérite une précision. Perdre la supervision n'est pas perdre la chaîne du froid, c'est perdre la capacité de savoir qu'elle est en train de tomber. Dans une PME sans astreinte technique, la différence est théorique.

## Sources de menace

- Un attaquant externe opportuniste, qui exploite un service exposé trouvé par balayage automatisé.
- Un attaquant structuré, qui vise le vol de données ou le sabotage.
- Le poste du prestataire frigoriste, compromis à son insu.
- Une indisponibilité ou une erreur du prestataire lui-même.

Les deux dernières ne sont pas malveillantes. Elles comptent autant, parce que l'impact sur VM1 est identique.

## Les quatre scénarios, et ce que les tests ont montré

### SO1 — Reconnaissance

Le service répond depuis Internet et révèle, **avant toute authentification**, le nom du domaine, le nom NetBIOS, le nom DNS du serveur et le numéro de version exact de Windows. Un attaquant dispose immédiatement de quoi cibler la suite.

Un second outil, exécuté sans fournir d'identifiants, rapporte un accès accordé.

<!-- À VALIDER : confirmer que le laboratoire reproduisait l'état antérieur à la migration, sans NLA activé, au moment de ce test « avant ». C'est l'explication la plus probable de ce résultat. -->

### SO2 — Tentatives d'authentification répétées

Le port est joignable en permanence depuis Internet et rien ne limite le nombre d'essais au niveau réseau. Un outil de force brute lancé contre le compte du prestataire enchaîne les tentatives sans aucun blocage.

La politique du domaine finit par verrouiller le compte après quelques échecs. Ce qui protège le compte déclenche le scénario suivant.

### SO3 — Verrouillage du compte du prestataire

Le compte verrouillé, le frigoriste ne peut plus intervenir. La chambre froide tourne sans personne pour la surveiller.

**C'est le scénario prioritaire**, et le plus contre-intuitif : la mesure de sécurité qui protège le compte produit elle-même l'événement redouté le plus grave. Je ne l'ai pas déduit sur le papier, je l'ai constaté en lançant l'attaque et en relevant ensuite l'état du compte dans l'annuaire.

### SO4 — Poste du prestataire compromis

Un attaquant qui prend le contrôle du poste du prestataire utilise sa connexion légitime. Elle est indiscernable d'un accès normal : bon certificat, bon mot de passe, bonne adresse.

Ce scénario ne peut pas être éliminé par des mesures prises de ce côté-ci du tunnel. Il est réduit et surveillé, pas supprimé.

## Tests réalisés

Huit tests d'intrusion menés depuis une machine Kali, et un test fonctionnel sur le mécanisme de supervision.

| Test | Avant les mesures | Après les mesures | Scénario |
|---|---|---|---|
| Balayage du port RDP | Port ouvert, service identifié | Port filtré, aucune réponse | SO1 |
| Interrogation sans authentification | Domaine, serveur et version de Windows révélés | Aucune réponse | SO1 |
| Connexion sans identifiants | Accès rapporté comme accordé | Délai d'attente dépassé, connexion impossible | SO1 |
| Force brute sur le compte du prestataire | Tentatives illimitées, compte verrouillé par l'annuaire | Aucune réponse, port filtré | SO2 et SO3 |
| Force brute à l'intérieur du tunnel | Sans objet | Détectée par le SIEM, alerte de niveau 15, MITRE T1110 | SO2 |
| Connexion VPN depuis une machine sans certificat | Sans objet | Échec de certificat journalisé par le SIEM, MITRE T1133 | SO2 |
| Déplacement du poste prestataire vers le contrôleur de domaine | Sans objet | Bloqué par la règle de moindre privilège | SO4 |
| Balayage SYN multi-ports | Sans objet | Détecté par l'IPS, adresse source bloquée | SO1 |
| Arrêt du service de supervision du froid | Aucune alerte, VM1 sans surveillance | Courriel d'alerte reçu | SO3 |

Le détail de chaque test et les preuves figurent dans les chapitres correspondants.

## Décisions de traitement

**Trois risques inacceptables, traités.** SO1, SO2 et SO3 sont traités par la fermeture du vecteur, le tunnel à double authentification, le moindre privilège, la détection, et un mécanisme d'alerte indépendant du compte et du tunnel.

**Un risque résiduel, accepté et documenté.** SO4 subsiste. Un poste compromis chez un tiers ne s'élimine pas depuis l'infrastructure du client. Il est contenu par le moindre privilège et surveillé par le SIEM.

Cette acceptation n'est pas un renoncement, c'est une décision prise en connaissance de cause. Une analyse de risques sert autant à écrire ce qu'on décide de ne pas traiter qu'à choisir des mesures : la décision reste visible, et peut être revue quand le contexte change.

## Ce que ce cadrage a changé

Si j'avais classé les données en premier, j'aurais construit du chiffrement, du cloisonnement d'accès aux fichiers et de la journalisation sur l'annuaire. Des mesures utiles, qui auraient laissé intact le scénario qui arrête réellement l'entreprise.

En classant la chaîne du froid en premier, le projet a pris une autre direction : fermer le vecteur d'entrée, confiner le prestataire, et construire un mécanisme d'alerte qui survit à la défaillance de tout le reste.

---

Suivant : [VPN, PKI et authentification mutuelle](02-vpn-mtls.md)
