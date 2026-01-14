# 📥 Guide d'Installation Complet

Ce guide vous accompagne pas à pas dans l'installation du script d'audit de sécurité mail.

---

## 📋 Prérequis

Avant de commencer, vérifiez que vous avez :

- ✅ **YunoHost 11.x** installé et fonctionnel
- ✅ **Serveur mail configuré** (via YunoHost)
- ✅ **Accès SSH root** au serveur
- ✅ **Connexion Internet** active

---

## 🚀 Installation en 6 étapes

### Étape 1 : Connexion SSH
```bash
# Se connecter au serveur YunoHost
ssh admin@votre-domaine.fr

# Passer en root
sudo su
```

### Étape 2 : Installation de mutt

Mutt est nécessaire pour envoyer les emails au format HTML.
```bash
# Mettre à jour les paquets
sudo apt update

# Installer mutt
sudo apt install mutt -y

# Vérifier l'installation
mutt -v
```

**Résultat attendu** : Version de mutt affichée (ex: `Mutt 2.2.9`)

### Étape 3 : Configuration de mutt
```bash
# Créer le fichier de configuration
cat > ~/.muttrc << 'EOF'
set from = "root@votre-domaine.fr"
set realname = "Security Audit"
set use_from = yes
set envelope_from = yes
EOF

# Vérifier la création du fichier
cat ~/.muttrc
```

**⚠️ Important** : Remplacez `votre-domaine.fr` par votre vrai domaine !

### Étape 4 : Téléchargement du script

#### Option A : Via wget (recommandé)
```bash
# Télécharger le script
wget https://raw.githubusercontent.com/gamersalpha/yunohost-mail-security-audit/main/mail_security_audit_html.sh -O /root/mail_security_audit_html.sh

# Vérifier le téléchargement
ls -lh /root/mail_security_audit_html.sh
```

#### Option B : Via git clone
```bash
# Cloner le repository
cd /root
git clone https://github.com/gamersalpha/yunohost-mail-security-audit.git

# Copier le script
cp yunohost-mail-security-audit/mail_security_audit_html.sh /root/

# Vérifier
ls -lh /root/mail_security_audit_html.sh
```

#### Option C : Copie manuelle

Si vous n'avez pas accès à Internet depuis le serveur :

1. Téléchargez le script sur votre PC
2. Utilisez SCP pour le transférer :
```bash
# Depuis votre PC
scp mail_security_audit_html.sh root@votre-domaine.fr:/root/
```

### Étape 5 : Rendre le script exécutable
```bash
# Donner les droits d'exécution
sudo chmod +x /root/mail_security_audit_html.sh

# Vérifier les permissions
ls -l /root/mail_security_audit_html.sh
```

**Résultat attendu** : `-rwxr-xr-x` (le `x` indique exécutable)

### Étape 6 : Configuration de l'email destinataire
```bash
# Éditer le script
sudo nano /root/mail_security_audit_html.sh

# Aller à la ligne 14 et modifier :
# ALERT_EMAIL="votre-email@domaine.fr"

# Sauvegarder : Ctrl+O puis Entrée
# Quitter : Ctrl+X
```

**⚠️ OBLIGATOIRE** : Sans cette configuration, aucun email ne sera envoyé !

---

## ✅ Test de l'installation

### Test 1 : Vérifier Fail2ban
```bash
# Vérifier que Fail2ban fonctionne
sudo systemctl status fail2ban

# Lister les jails actives
sudo fail2ban-client status
```

**Résultat attendu** : 
```
Status
|- Number of jail:      12-13
`- Jail list:   postfix, sasl, dovecot, sshd, ...
```

### Test 2 : Vérifier les logs mail
```bash
# Vérifier que les logs existent
ls -lh /var/log/mail.log

# Voir les dernières lignes
sudo tail -20 /var/log/mail.log
```

### Test 3 : Tester l'envoi d'email
```bash
# Test simple
echo "Test d'envoi" | mail -s "Test Script Audit" votre-email@domaine.fr

# Vérifier dans les logs mail
sudo tail -f /var/log/mail.log | grep "Test Script"
```

**Vérifiez votre boîte mail** : vous devriez recevoir l'email de test.

### Test 4 : Exécuter le script
```bash
# Lancer le script manuellement
sudo /root/mail_security_audit_html.sh

# Vérifier les logs du script
tail -10 /var/log/mail_audit.log
```

**Résultat attendu** :
```
2026-01-14 15:30:05 - Rapport HTML envoyé à votre-email@domaine.fr
```

**Vérifiez votre boîte mail** : vous devriez recevoir un magnifique rapport HTML ! 🎉

---

## 🔧 Configuration avancée

### Automatiser l'envoi quotidien
```bash
# Ouvrir le crontab root
sudo crontab -e

# Si première utilisation, choisir nano (option 1)

# Ajouter à la fin du fichier :
0 7 * * * /root/mail_security_audit_html.sh

# Sauvegarder et quitter
```

**Explication** :
- `0 7 * * *` = Tous les jours à 7h00
- Vous pouvez changer l'heure selon vos besoins

**Exemples d'autres horaires** :
```bash
0 8 * * * /root/mail_security_audit_html.sh   # 8h00
30 6 * * * /root/mail_security_audit_html.sh  # 6h30
0 */6 * * * /root/mail_security_audit_html.sh # Toutes les 6h
```

### Vérifier le crontab
```bash
# Lister les tâches cron
sudo crontab -l

# Vérifier les logs cron
sudo grep CRON /var/log/syslog | tail -20
```

---

## 🐛 Dépannage Installation

### Problème : "mutt: command not found"

**Solution** :
```bash
sudo apt update
sudo apt install mutt -y
```

### Problème : "Permission denied"

**Solution** :
```bash
# Vérifier que vous êtes root
whoami  # Doit afficher "root"

# Donner les bonnes permissions
sudo chmod +x /root/mail_security_audit_html.sh
```

### Problème : "No such file or directory"

**Solution** :
```bash
# Vérifier l'emplacement du script
ls -l /root/mail_security_audit_html.sh

# Si absent, re-télécharger
wget https://raw.githubusercontent.com/gamersalpha/yunohost-mail-security-audit/main/mail_security_audit_html.sh -O /root/mail_security_audit_html.sh
```

### Problème : Email non reçu

**Vérifications** :
```bash
# 1. Vérifier la config mutt
cat ~/.muttrc

# 2. Vérifier les logs
tail -50 /var/log/mail.log | grep "Security Audit"

# 3. Vérifier les logs du script
tail -20 /var/log/mail_audit.log

# 4. Tester manuellement
echo "Test" | mutt -s "Test" votre-email@domaine.fr
```

### Problème : Statistiques à 0

**Causes possibles** :
1. Aucune attaque aujourd'hui (c'est bien !)
2. Fail2ban inactif
3. Logs mail vides

**Vérifications** :
```bash
# Vérifier Fail2ban
sudo systemctl status fail2ban

# Vérifier les logs
sudo grep "auth=0/1" /var/log/mail.log | wc -l

# Forcer une lecture des derniers jours
sudo grep "auth=0/1" /var/log/mail.log | tail -50
```

---

## 📚 Étapes suivantes

Une fois l'installation terminée :

1. ✅ Consultez [CONFIGURATION.md](CONFIGURATION.md) pour personnaliser le script
2. ✅ Attendez le premier rapport quotidien (ou lancez manuellement)
3. ✅ Ajustez les seuils d'alerte selon vos besoins
4. ✅ Partagez vos retours sur GitHub !

---

## 🆘 Besoin d'aide ?

- 🐛 [Ouvrir une Issue](https://github.com/gamersalpha/yunohost-mail-security-audit/issues)
- 💬 [Discussions GitHub](https://github.com/gamersalpha/yunohost-mail-security-audit/discussions)
- 📖 [Retour au README](../README.md)

---

**Installation terminée !** 🎉

Vous recevrez votre premier rapport demain matin à 7h00 (ou à l'heure que vous avez configurée).






---

## ⚡ Installation des Alertes Temps Réel (Optionnel)

### Pourquoi activer les alertes temps réel ?

Le rapport quotidien est envoyé à 7h00 chaque matin. Si une attaque massive se produit à 15h00, vous ne serez averti que le lendemain matin ! 

Les alertes temps réel vous préviennent **immédiatement** en cas d'activité suspecte.

### Installation
```bash
# 1. Télécharger le script
wget https://raw.githubusercontent.com/gamersalpha/yunohost-mail-security-audit/main/mail_security_realtime_alert.sh -O /root/mail_security_realtime_alert.sh

# 2. Rendre exécutable
sudo chmod +x /root/mail_security_realtime_alert.sh

# 3. Configurer
sudo nano /root/mail_security_realtime_alert.sh
```

Modifiez les lignes 11-13 :
```bash
ALERT_EMAIL="votre-email@domaine.fr"  # Votre email
THRESHOLD_ATTEMPTS=50                  # Seuil d'alerte (50 tentatives)
TIME_WINDOW=60                         # Dans les 60 dernières minutes
```

### Tester
```bash
# Test en mode debug
sudo bash -x /root/mail_security_realtime_alert.sh

# Forcer une alerte (temporairement abaisser le seuil à 1)
sudo nano /root/mail_security_realtime_alert.sh
# Changer THRESHOLD_ATTEMPTS=1
sudo /root/mail_security_realtime_alert.sh
# Remettre à 50 après le test !
```

### Automatiser
```bash
# Ouvrir le crontab
sudo crontab -e

# Ajouter cette ligne (vérification toutes les heures)
0 * * * * /root/mail_security_realtime_alert.sh
```

**Autres fréquences possibles** :
```bash
# Toutes les 30 minutes (recommandé pour serveurs exposés)
*/30 * * * * /root/mail_security_realtime_alert.sh

# Toutes les 15 minutes (très actif)
*/15 * * * * /root/mail_security_realtime_alert.sh

# Toutes les 6 heures (serveur peu ciblé)
0 */6 * * * /root/mail_security_realtime_alert.sh
```

### Anti-spam d'alertes

Le script inclut un **cooldown automatique** :
- Une seule alerte par heure maximum
- Évite la saturation de votre boîte mail
- Configurable via `COOLDOWN_MINUTES`

### Format de l'alerte reçue
```
🚨 ALERTE SÉCURITÉ - Attaque en cours détectée !

Serveur : votre-serveur.fr
Heure : 2026-01-14 15:23:45

📊 STATISTIQUES DES 60 DERNIÈRES MINUTES :
- Tentatives d'authentification échouées : 127
- Seuil configuré : 50
- IPs bannies par Fail2ban : 3

🎯 TOP 5 DES IPS ATTAQUANTES :
    89 91.92.241.223
    23 158.94.210.190
    ...

🚫 IPS ACTUELLEMENT BANNIES :
postfix: 91.92.241.223 158.94.210.190
sasl: 91.92.241.223

⚡ ACTIONS RECOMMANDÉES :
1. Vérifier les logs
2. Vérifier Fail2ban
3. Bloquer manuellement si nécessaire
```

---

✅ **Installation des alertes temps réel terminée !**

Tu as maintenant :
- 📧 **Rapport quotidien HTML** à 7h00
- ⚡ **Alertes temps réel** toutes les heures (ou plus)
```

---

## 📋 Structure finale complète du repo :
```
yunohost-mail-security-audit/
├── README.md                           ✅
├── LICENSE                             ✅
├── .gitignore                          ✅
├── mail_security_audit_html.sh         ✅ (Rapport quotidien)
├── mail_security_realtime_alert.sh     ✅ (Alertes temps réel) 🆕
└── docs/
    ├── INSTALLATION.md                 ✅ (mis à jour)
    └── CONFIGURATION.md                ✅
