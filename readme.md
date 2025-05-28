Protocol twin :  https://app.twinfinance.io/

Le but du projet est de fabriqué des actifs synthétiques NVDA MSTR ... 

J'explique un peu le fonctionnement du protocol (y'a la doc du protocol aussi). 

Au moment du lancement des contrats le prix des actifs sous-jacent (NVDA ici) a été enregistrer et une variable 
u = uperlimitprice a été enregistrer (2 x prix de l'action au lancement).

Un utilisateur apporte un montant a d'usdc et il va pouvoir minter deux tokens
NVDA et iNVDA

et il va recevoir a / u des deux tokens. 

1. La stratégie d'arbitrage est assez simple, on regarde les prix de NVDA et iNVDA sur les dex. Et si en enchangeant es a/u token NVDA et iNVDA je recoit plus que a et bien j'ai fais un gain. 

2. on peut également redem des usdc en apportant une quantité équivalente de NVDA et iNVDA mais ici y'a un 2% de fee.

Dans le contrat manager : j'ai juste fait la strétégie 1 pour NVDA, il y a 3 autres assets a faire mais y'a un truc a prendre en compte c'est que 2 assets sont dans des pools sur le dex kodiac et 2 autres sont sur des pools sur
https://app.burrbear.io/#/berachain/pool/0x8213bb9c018edc0295b177278aeaa1a704f123ab000200000000000000000018

Donc le code ne peux pas s'adapter facilement, il faut changer le contrat qui fait les swaps. Je pense le mieux c'est de faire un mini-agrégateur qui permet de swap facilement.

Concrétement la fonction exec(...) du contrat fait les actions suivante : 

1. appelle le protocol berraborrow pour obtenir un flashloan en un stable coin nect (0.05% de fees). Celui appelle la fonction  onflashloan de contrat qui l'appelle (callback) en lui renvoie les fonds, et les infos. 
2. swap nect to usdc sur buurbear protocol.
3. mint les tokens NVDA et iNVA avec les usdc recu.
4. swap de NVDA et iNVDA en nect sur buurbear protocol.
5. reboursement de la dette du flash loan et envoie le reste des nect sur le wallet owner.
