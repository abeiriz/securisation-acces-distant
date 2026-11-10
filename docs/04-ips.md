# IPS et règles de détection

> Les noms de domaine, de machines, de comptes et de tiers qui apparaissent ici sont fictifs. Les captures proviennent d'un laboratoire.

## Le rôle de cette couche

Le VPN ferme le vecteur d'entrée. L'IPS surveille ce qui arrive quand même au pare-feu et bloque la reconnaissance avant qu'elle ne serve à quelque chose.

Il est placé sur l'interface WAN, là où le trafic d'Internet arrive, avant tout traitement par les règles de filtrage. Le mode blocage est actif : quand une règle se déclenche, l'adresse source est ajoutée à la liste des hôtes bloqués.

Deux jeux de règles cohabitent. Les règles publiques couvrent les signatures de menaces connues. Les règles personnalisées, dans la plage réservée aux règles locales, couvrent le contexte de cette infrastructure.

> *Capture : IPS activé sur l'interface WAN, mode blocage, jeu de règles publiques chargé*

## Ce que l'IPS voit, et ce qu'il ne voit pas

Cette distinction a fini par décider de la forme de mes règles, alors autant la poser d'emblée.

L'IPS lit des paquets. Il voit des adresses, des ports, des drapeaux TCP, des volumes et des rythmes. Il détecte donc très bien qu'une source ouvre beaucoup de connexions vers un port, ou qu'elle balaie une plage.

Il ne voit pas le résultat d'une authentification. Une session RDP est chiffrée : savoir qu'un mot de passe a été refusé est hors de sa portée. Cette information existe, mais ailleurs, dans le journal de sécurité de Windows.

**L'IPS détecte des tentatives de connexion. Le SIEM détecte des échecs d'authentification.** J'y reviens plus bas, parce que c'est en l'oubliant que j'ai écrit une règle de trop.

## Les règles

```
# Regles personnalisees - laboratoire PME-AGRO

# 9000001 - tentatives de connexion repetees vers le port RDP
alert tcp any any -> $HOME_NET 3389 (msg:"PME-AGRO - Tentatives de connexion RDP";
  flags:S; threshold:type threshold, track by_src, count 5, seconds 60;
  sid:9000001; rev:2;)

# 9000003 - balayage ICMP
alert icmp any any -> $HOME_NET any (msg:"PME-AGRO - Balayage ICMP detecte";
  itype:8; threshold:type threshold, track by_src, count 5, seconds 10;
  sid:9000003; rev:2;)

# 9000004 - balayage SYN multi-ports
alert tcp any any -> $HOME_NET any (msg:"PME-AGRO - Balayage SYN multi-ports";
  flags:S; threshold:type threshold, track by_src, count 20, seconds 10;
  sid:9000004; rev:2;)
```

| SID | Détecte | Seuil |
|---|---|---|
| 9000001 | Tentatives de connexion répétées vers le port RDP | 5 paquets SYN en 60 s, par IP source |
| 9000003 | Balayage ICMP | 5 requêtes écho en 10 s, par IP source |
| 9000004 | Balayage SYN multi-ports | 20 paquets SYN en 10 s, par IP source |

L'identifiant 9000002 a existé puis a été retiré. L'explication est plus bas, c'est le passage le plus instructif de ce chapitre.

Les trois règles déclenchent le blocage de l'adresse source. Le mode blocage s'applique à toute règle qui se déclenche, il n'y a pas de réglage par règle.

> *Capture : onglet des règles personnalisées*

## À quoi servent les seuils

Un seuil n'est pas seulement un filtre anti-bruit, c'est une partie de la définition de ce qu'on cherche.

Prenons le balayage ICMP. Un ping isolé est du trafic normal : un poste qui vérifie si une machine répond. Cinq requêtes écho en dix secondes depuis la même source, c'est autre chose, c'est quelqu'un qui cartographie le réseau. Le seuil est ce qui sépare les deux.

Il a un second effet, pratique : il regroupe la salve en une détection au lieu d'en produire une par paquet. Sans cela, un balayage remplirait le journal de centaines de lignes identiques et le rendrait illisible au moment où on en a besoin.

Même logique pour les deux autres. Personne n'a de raison légitime d'envoyer cinq demandes de connexion RDP en une minute vers une infrastructure où ce port est censé être fermé, ni vingt SYN vers vingt ports en dix secondes.

## La règle que j'ai retirée, et pourquoi

J'avais écrit quatre règles. La 9000002 devait détecter le brute-force RDP, là où la 9000001 détectait le scan. Deux choses différentes, dans mon intention.

Elles ne l'étaient pas.

```
# 9000001
alert tcp any any -> $HOME_NET 3389 (... flags:S; ... track by_src, count 5, seconds 60; ...)
# 9000002
alert tcp any any -> $HOME_NET 3389 (... flags:S; ... track by_src, count 10, seconds 60; ...)
```

La condition de correspondance est identique : TCP, n'importe quelle source, port 3389, drapeau SYN. Seul le seuil change. Et les deux comptent `by_src`, donc par adresse source : la distinction que je croyais faire entre « depuis Internet » et « depuis la même IP » n'existait pas, les deux faisaient la seconde.

Résultat : tout paquet qui déclenche la 9000002 a nécessairement déclenché la 9000001 avant.

**Je ne l'ai pas vu en relisant le code. Je l'ai vu dans le journal d'alertes.**

En validant les règles, j'ai remarqué des alertes par paires : même adresse source, même port source, même seconde, deux identifiants de règle différents. Un seul paquet, deux alertes. Sur 212 entrées, une bonne partie était du doublon.

> *Capture : journal d'alertes, paires d'alertes 9000001 et 9000002 sur le même port source et le même horodatage*

### Ce que j'en ai tiré

La distinction que je cherchais ne se fait pas à ce niveau. Compter des paquets SYN mesure des tentatives de connexion, pas des tentatives de mot de passe. Une attaque menée lentement, sur une seule connexion maintenue, ne déclencherait rien.

Les tentatives de mot de passe produisent un événement, mais sur le serveur : l'identifiant 4625 du journal de sécurité Windows, « échec d'ouverture de session ». C'est une information d'authentification, pas de réseau.

J'ai donc retiré la 9000002 et confié la détection du brute-force à la couche qui dispose de la bonne information : le SIEM, et sa règle locale bâtie sur ces événements.

Chaque couche détecte ce qu'elle est en mesure de voir. Vouloir faire faire à l'IPS le travail du SIEM produit une règle qui a l'air de fonctionner, qui génère des alertes, et qui ne mesure pas ce qu'elle prétend mesurer.

## La validation

Pour éprouver les règles, j'ai généré depuis une machine Kali plusieurs types de trafic vers l'adresse publique du pare-feu, simultanément : balayage SYN multi-ports, balayage ciblant le port RDP, sollicitations répétées.

Puis j'ai vérifié deux choses, dans cet ordre :

1. **Les alertes attendues apparaissent**, avec la bonne adresse source et le bon identifiant de règle.
2. **L'adresse a bien été bloquée**, en consultant la liste des hôtes bloqués.

Le second point est celui qu'on oublie. Une règle qui alerte sans bloquer donne l'illusion de la protection : elle remplit le journal et laisse passer le trafic.

La liste des hôtes bloqués montre l'adresse de test, avec mes trois règles et plusieurs règles du jeu public qui se sont déclenchées sur le même balayage. Les balayages suivants depuis cette adresse n'obtiennent plus de réponse.

> *Capture : journal d'alertes avec l'adresse source et l'horodatage*
> *Capture : liste des hôtes bloqués, adresse de test présente*

## Les limites

Le blocage par adresse source arrête un attaquant opportuniste qui balaie depuis une machine. Il est beaucoup moins efficace contre quelqu'un qui change d'adresse, et inopérant contre une attaque venue d'une adresse légitime.

Par ailleurs, depuis la fermeture du port RDP, le seul port joignable depuis Internet est celui du VPN. La règle 9000001 n'a plus de trafic à voir en fonctionnement normal : elle sert de filet si une redirection était recréée par erreur. Surveiller le port du VPN lui-même mériterait sa propre règle, ce que je n'ai pas mis en place.

C'est la raison d'être du chapitre suivant. L'IPS arrête le bruit en périphérie. La corrélation des journaux est ce qui permet de voir une attaque discrète menée depuis un accès autorisé.

## Transposition en production

Le pare-feu de production dispose de son propre moteur de prévention d'intrusion, configuré depuis son interface d'administration. La logique de détection, les seuils et le choix de bloquer la source sont identiques. Seule la syntaxe d'écriture des règles change.

---

Précédent : [Moindre privilège et confinement](03-moindre-privilege.md) · Suivant : [SIEM, règles locales et réponse active](05-siem-wazuh.md)
