# Octobre et novembre 2026 : ce que les attaques sur la chaîne du froid ont confirmé

> Chapitre ajouté en novembre 2026. Le projet lui-même date de mars 2026 et n'a pas été réécrit après coup : les constats ci-dessous renvoient à l'analyse telle qu'elle a été remise.
>
> Les entreprises citées dans ce chapitre le sont d'après la presse, au titre des attaques d'octobre et novembre 2026. Aucune n'a de rapport avec le client du projet, qui n'est pas nommé.

## Ce qui s'est passé

Dans la nuit du 11 au 12 octobre 2026, une attaque a visé les automates de régulation frigorifique d'environ 700 sites en France. Les attaquants ont forcé un cycle de dégivrage nocturne avec les denrées à l'intérieur. Les températures sont montées autour de 50 °C, jusqu'à 80 °C dans un magasin de Normandie. Au moins quinze départs de feu ont été signalés, et les pertes de marchandise se comptent en millions d'euros.

Les cibles ne se limitent pas à la grande distribution. Aux enseignes touchées s'ajoutent **des boucheries, un abattoir et des usines coopératives agroalimentaires**, ainsi que des équipements de régulation sur de petites installations hydroélectriques.

Le 2 novembre, une seconde vague a touché plusieurs pays européens. Trois sites de l'Établissement français du sang ont également été visés. Cette fois, les températures anormales ont été repérées assez tôt : les produits ont été déplacés ou sécurisés, et l'EFS n'a déclaré aucune perte. L'EFS n'était pas la cible directe, mais son fournisseur d'équipements frigorifiques.

Le 10 novembre, le gouvernement français a attribué ces attaques à une unité cyber étatique étrangère. L'ambassadeur du pays concerné a été convoqué, le parquet de Paris a requis des mandats d'arrêt internationaux, et la France a annoncé rechercher des sanctions au niveau européen. L'enquête s'appuie notamment sur la langue employée par les attaquants et sur des adresses réseau liées à des équipements situés dans ce pays.

**Le vecteur.** Des automates de régulation Danfoss AK-SM800 et AK-SC355, ainsi que des contrôleurs Copeland et Dixell XWEB, exposaient leur serveur web directement sur Internet. Beaucoup étaient accessibles avec l'identifiant `admin` et un mot de passe dérivé de la date du jour, par une fonction interne de type « code du jour ». Ces défauts avaient été publiés par Claroty en 2025. Danfoss a corrigé la série AK-SM800A en août 2025, mais les AK-SC355 et AK-SM800 étaient déjà en fin de vie. Après l'attaque française, environ 4 500 automates restaient joignables depuis Internet.

Un point revient dans tous les comptes rendus : la réfrigération est presque toujours confiée à un prestataire extérieur, et l'entreprise qui exploite le site ne maîtrise pas la sécurité de ces équipements.

## Ce que ce projet avait identifié

Je n'ai rien prédit. J'ai constaté qu'une attaque de ce type était possible, et je l'ai écrit.

Mon analyse partait d'un renversement : dans cette PME, la valeur métier la plus critique n'était ni le serveur ni la base de données, c'était la chaîne du froid. VM1 est cotée CRITIQUE, au-dessus des données personnelles et de l'application de gestion.

| Dans l'analyse de mars 2026 | Dans les attaques d'octobre et novembre |
|---|---|
| La chaîne du froid est la valeur métier prioritaire | Des millions d'euros de marchandise perdus, des sites fermés, des équipements détruits |
| Parmi les sources de menace retenues : un attaquant structuré visant le sabotage | Attaques attribuées par le gouvernement français à une unité cyber étatique |
| Le risque passe par le prestataire frigoriste et son accès distant, pas par les utilisateurs internes | L'EFS n'était pas la cible : son fournisseur de froid l'était |
| Perdre la supervision de la chaîne du froid est un événement redouté à part entière, ER1, qui justifie un mécanisme d'alerte indépendant | À l'EFS, c'est le repérage des températures anormales qui a permis d'intervenir avant la perte des produits |
| Le logiciel de gestion du froid tourne sur le serveur applicatif, avec la base de données et les fichiers partagés. Le service lui-même est une surface d'attaque, pas seulement le chemin qui y mène | Le point d'entrée a été l'équipement frigorifique, pas le système d'information bureautique |

Deux de ces lignes méritent un mot.

La première source de menace que j'avais retenue était l'attaquant opportuniste, celui qui balaie Internet et exploite ce qu'il trouve. J'avais aussi retenu l'attaquant structuré visant le sabotage, en le considérant comme moins probable pour une PME de cette taille. C'est celui-là qui s'est matérialisé, et à l'échelle nationale.

Le profil des victimes compte aussi. Il ne s'agit pas seulement de grandes enseignes : des boucheries et des usines agroalimentaires figurent parmi les cibles. Autrement dit, exactement le type d'entreprise sur lequel portait ce projet.

## Le vrai sujet : l'arbitrage

Les axes d'amélioration que j'avais proposés, isoler le service frigorifique dans une machine virtuelle dédiée puis sur une machine physique en segment réseau distinct, sont restés des propositions. Le projet a été conçu sous une contrainte explicite : aucune acquisition matérielle supplémentaire.

Ce n'est pas un oubli, c'est la situation habituelle dans une PME. Le budget informatique sert à ce qui est visible et à ce qui tombe en panne. Isoler un service qui fonctionne, pour un risque qui ne s'est pas encore produit, demande un investissement que la direction ne voit pas comme urgent. L'analyse acte donc un risque résiduel assumé et documenté, plutôt que de recommander une architecture que personne n'aurait financée.

C'est exactement cet arbitrage que les attaques d'octobre ont pris à revers, à grande échelle. L'équipement frigorifique est peu coûteux à sécuriser tant que le sujet est posé à l'installation, et très coûteux une fois que la marchandise est perdue.

Une analyse de risques ne sert pas seulement à choisir des mesures. Elle sert à écrire noir sur blanc ce qu'on décide de ne pas traiter, pour que la décision soit prise en connaissance de cause et puisse être revue quand le contexte change. Novembre 2026 est précisément ce changement de contexte.

## La limite de mon périmètre

Mes mesures techniques protègent le chemin d'accès au logiciel de gestion du froid : fermeture du RDP exposé, tunnel avec certificat, moindre privilège, IPS, SIEM. Mes axes d'amélioration visaient l'isolation du service lui-même.

Ce que mon inventaire ne couvrait pas, ce sont les automates de régulation en tant qu'équipements : marque, modèle, version, fin de support, et accès réseau propre. Je raisonnais sur un service hébergé par un serveur Windows. Les attaques d'octobre sont entrées par du matériel industriel qui parlait à Internet sans passer par aucun serveur.

Le raisonnement était bon, son périmètre s'arrêtait trop tôt. Les automates frigorifiques relèvent de l'OT et sont posés par le frigoriste, souvent sans que l'informatique sache qu'ils existent.

## Ce que j'ajouterais aujourd'hui

**Inventaire des équipements OT.** Lister les automates et régulateurs installés par le frigoriste : marque, modèle, version, fin de support, et accès réseau. Un équipement dont personne ne connaît l'existence ne peut pas être corrigé.

**Aucun automate joignable depuis Internet.** C'est le défaut exploité en octobre. L'accès du prestataire doit emprunter le même tunnel que le reste, avec certificat et moindre privilège.

**Segmentation OT et IT.** C'est l'axe d'amélioration que j'avais proposé, étendu au-delà du serveur applicatif : les automates dans un segment qui ne communique ni avec le LAN bureautique ni avec Internet.

**Identifiants par défaut et fonctions de maintenance cachées.** Comptes constructeur et mots de passe dérivés de la date sont à traiter comme des portes ouvertes. Quand ils ne peuvent pas être désactivés, c'est le réseau qui doit rendre l'équipement inatteignable.

**Équipements en fin de vie.** Un automate hors support derrière une segmentation stricte reste exploitable. Exposé, il ne l'est pas.

**Contrat avec le prestataire.** Qui met à jour l'automate, dans quel délai, et qui est prévenu en cas d'alerte de sécurité ? C'est contractuel avant d'être technique, et c'est la question que la directive NIS2 impose de poser à ses fournisseurs.

**Supervision de la température indépendante de l'automate.** Si l'automate est compromis, ce qu'il rapporte n'a plus de valeur. Une sonde séparée, qui remonte par un autre chemin, est la seule façon de savoir ce qui se passe réellement dans la chambre froide. C'est le prolongement direct de la logique du mécanisme d'alerte développé dans ce projet, et c'est ce qui a limité les dégâts à l'EFS.

## Sources

- [Cyberattaque de 2026 contre la grande distribution en France](https://fr.wikipedia.org/wiki/Cyberattaque_de_2026_contre_la_grande_distribution_en_France) · Wikipédia
- [2026 French supermarket refrigerator hack](https://en.wikipedia.org/wiki/2026_French_supermarket_refrigerator_hack) · Wikipedia
- [Cyberattack disrupts blood storage refrigeration systems in France](https://www.bleepingcomputer.com/news/security/cyberattack-disrupts-blood-storage-refrigeration-systems-in-france/) · BleepingComputer
- [French blood banks foil new cyberattack targeting refrigerators](https://www.france24.com/en/france/20261104-french-blood-banks-foil-new-cyberattack-targeting-refrigerators) · France 24
- [Paris attribue le sabotage des frigos de supermarchés et promet des sanctions](https://www.usine-digitale.fr/cybersecurite/une-premiere-en-france-par-son-ampleur-et-la-nature-de-ses-cibles-paris-attribue-a-liran-le-sabotage-des-frigos-de-supermarches-et-promet-des-sanctions.AA4US35M2NALVON6EKBCTBSFRQ.html) · L'Usine Digitale, 10 novembre 2026
- [La France accuse et enquête sur une unité cyber-offensive](https://securite.developpez.com/actu/388916/La-France-accuse-l-Iran-d-une-cyberattaque-contre-les-rayons-refrigeres-des-supermarches-et-enquete-sur-une-unite-cybernetique-affiliee-au-CGRI-islamique-dans-le-cadre-de-ces-attaques/) · Developpez, 10 novembre 2026
- [Froid industriel : l'EFS déjoue une cyberattaque grâce à une surveillance indépendante](https://www.processalimentaire.com/procedes/froid-industriel-l-efs-dejoue-une-cyberattaque-grace-a-une-surveillance-independante) · Process Alimentaire

