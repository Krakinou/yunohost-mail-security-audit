# 🛡️ YunoHost Mail Security Audit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![YunoHost](https://img.shields.io/badge/YunoHost-11.x-blue)](https://yunohost.org)
[![Bash](https://img.shields.io/badge/Bash-5.0+-green)](https://www.gnu.org/software/bash/)

> **⚠️ AVERTISSEMENT - À UTILISER EN CONNAISSANCE DE CAUSE**
>
> Ce script analyse les logs système et envoie des rapports par email. Il est fourni **TEL QUEL**, sans garantie.  
> **Testez-le en environnement de développement avant de l'utiliser en production.**  
> L'auteur décline toute responsabilité en cas de dysfonctionnement, perte de données ou problème de sécurité.

Script Bash générant des **rapports de sécurité HTML quotidiens** pour surveiller votre serveur mail YunoHost exposé sur Internet.

---

## 🎯 Contexte et Motivation

Lorsqu'on expose son serveur YunoHost **directement sur Internet** (sans reverse proxy intermédiaire), le serveur mail devient rapidement une **cible privilégiée** pour :
- 🎯 Attaques par force brute
- 🔑 Credential stuffing (test de mots de passe volés)
- 🌐 Scans automatisés de botnets
- 📧 Tentatives de spam relay

### Le problème

Bien que YunoHost intègre **Fail2ban** pour la protection, il manque cruellement d'**outils de visualisation et d'analyse** pour :
- 📊 Comprendre **qui** attaque votre serveur
- 🕐 Savoir **quand** les attaques ont lieu  
- 📈 Mesurer l'**ampleur** des tentatives d'intrusion
- ✅ Vérifier que les **protections fonctionnent** correctement
- 🚨 Être **alerté** en cas d'anomalie

### La solution

Ce script génère un **rapport quotidien HTML professionnel** avec :
- Dashboard visuel moderne
- Statistiques en temps réel
- Top des IPs attaquantes
- Alertes intelligentes
- Historique des bans Fail2ban

---

## ✨ Fonctionnalités

- 📊 **Dashboard visuel** avec statistiques colorées
- 🎯 **Top 5 des IPs attaquantes** avec niveau de criticité
- 🔔 **Système d'alertes** (🟢 OK / 🟠 Attention / 🔴 Critique)
- 👥 **Suivi des connexions légitimes** par utilisateur
- 🚫 **Liste des IPs bannies** par Fail2ban (postfix, sasl, dovecot, sshd)
- 📧 **Envoi automatique par email** au format HTML
- 📱 **Design responsive** (compatible mobile)
- 🎨 **Codes couleurs intuitifs** (vert=OK, orange=attention, rouge=danger)
- 🧹 **Nettoyage automatique** des anciens rapports (30 jours)

---

## 🔧 Prérequis

- **YunoHost** 11.x (testé sur Debian 12)
- **Fail2ban** activé (installé par défaut avec YunoHost)
- **Serveur mail** configuré (Postfix + Dovecot)
- **mutt** pour l'envoi d'emails HTML
- **Accès root** au serveur

---

## 📥 Installation rapide
```bash
# 1. Installer mutt
sudo apt update && sudo apt install mutt -y

# 2. Configurer mutt
cat > ~/.muttrc << 'EOF'
set from = "root@votre-domaine.fr"
set realname = "Security Audit"
set use_from = yes
set envelope_from = yes
EOF

# 3. Télécharger le script
wget https://raw.githubusercontent.com/gamersalpha/yunohost-mail-security-audit/main/mail_security_audit_html.sh -O /root/mail_security_audit_html.sh

# 4. Rendre exécutable
sudo chmod +x /root/mail_security_audit_html.sh

# 5. Configurer votre email
sudo nano /root/mail_security_audit_html.sh
# Modifier ligne 14 : ALERT_EMAIL="votre-email@domaine.fr"

# 6. Tester
sudo /root/mail_security_audit_html.sh
```

**📚 Documentation détaillée** : [INSTALLATION.md](docs/INSTALLATION.md)

---

## ⚙️ Configuration

### Configuration minimale

Éditez le script et modifiez :
```bash
# Ligne 14 : Email destinataire (OBLIGATOIRE)
ALERT_EMAIL="votre-email@domaine.fr"
```

### Automatisation (envoi quotidien à 7h00)
```bash
# Ouvrir le crontab root
sudo crontab -e

# Ajouter cette ligne
0 7 * * * /root/mail_security_audit_html.sh
```

**📚 Guide complet** : [CONFIGURATION.md](docs/CONFIGURATION.md)

## ⚡ Alertes Temps Réel (Optionnel)

En plus du rapport quotidien, vous pouvez activer des **alertes immédiates** en cas d'attaque massive.

### Installation de l'alerte temps réel
```bash
# 1. Télécharger le script d'alerte
wget https://raw.githubusercontent.com/VOTRE-USERNAME/yunohost-mail-security-audit/main/mail_security_realtime_alert.sh -O /root/mail_security_realtime_alert.sh

# 2. Rendre exécutable
sudo chmod +x /root/mail_security_realtime_alert.sh

# 3. Configurer (email et seuil)
sudo nano /root/mail_security_realtime_alert.sh
# Modifier ligne 11 : ALERT_EMAIL="votre-email@domaine.fr"
# Modifier ligne 12 : THRESHOLD_ATTEMPTS=50  (seuil de tentatives)

# 4. Tester
sudo /root/mail_security_realtime_alert.sh
```

### Automatiser les vérifications
```bash
# Ouvrir le crontab
sudo crontab -e

# Ajouter ces deux lignes :
# Rapport quotidien à 7h00
0 7 * * * /root/mail_security_audit_html.sh

# Alerte temps réel toutes les heures
0 * * * * /root/mail_security_realtime_alert.sh
```

### Configuration des seuils
```bash
# Dans le script d'alerte temps réel
THRESHOLD_ATTEMPTS=50   # Nombre de tentatives qui déclenchent une alerte
TIME_WINDOW=60          # Fenêtre de temps en minutes
COOLDOWN_MINUTES=60     # Anti-spam : 1 alerte par heure max
```

**Exemples de configuration** :

| Profil | THRESHOLD | TIME_WINDOW | COOLDOWN |
|--------|-----------|-------------|----------|
| **Strict** | 20 | 30 min | 30 min |
| **Normal** | 50 | 60 min | 60 min |
| **Tolérant** | 100 | 120 min | 120 min |

---

## 📊 Récapitulatif des deux scripts

| Script | Fréquence | Objectif | Format |
|--------|-----------|----------|--------|
| **mail_security_audit_html.sh** | Quotidien (7h00) | Rapport complet avec statistiques | Email HTML moderne |
| **mail_security_realtime_alert.sh** | Toutes les heures | Alerte en cas d'attaque massive | Email texte urgent |

---

## 📊 Ce que analyse le script

| Métrique | Description | Source |
|----------|-------------|--------|
| **Tentatives d'attaque** | Échecs d'authentification SMTP/IMAP | `/var/log/mail.log` |
| **IPs bannies** | Liste des IPs bloquées par Fail2ban | `fail2ban-client` |
| **Connexions externes** | Authentifications hors réseau local | `/var/log/mail.log` |
| **Mails envoyés** | Volume quotidien d'emails | `/var/log/mail.log` |
| **Utilisateurs actifs** | Comptes légitimes connectés | `/var/log/mail.log` |

---

## 🎨 Personnalisation

### Modifier les seuils d'alerte
```bash
# Ligne 47-48 du script
if [ "$EXTERNAL_AUTH" -eq 0 ] && [ "$SENT_MAILS" -lt 200 ] && [ "$TOTAL_ATTEMPTS" -lt 100 ]; then
```

**Valeurs par défaut** :
- Mails envoyés : < 200 → 🟢 Normal
- Tentatives d'attaque : < 100 → 🟢 OK
- Connexions externes : 0 → 🟢 Sécurisé

### Afficher plus d'IPs dans le Top
```bash
# Ligne 60 : Changer head -5 en head -10
TOP_IPS=$(... | head -10)
```

---

## 🐛 Dépannage

### Problème : Email reçu en texte brut

**Solution** :
```bash
# Vérifier la config mutt
cat ~/.muttrc

# Doit contenir :
set from = "root@votre-domaine.fr"
set use_from = yes
```

### Problème : Pas d'email reçu
```bash
# Vérifier les logs
tail -20 /var/log/mail_audit.log

# Tester l'envoi manuel
echo "Test" | mail -s "Test" votre-email@domaine.fr
```

### Problème : Statistiques à 0
```bash
# Vérifier Fail2ban
sudo systemctl status fail2ban

# Vérifier les logs mail
sudo tail -100 /var/log/mail.log | grep "auth=0/1"
```

**📚 Dépannage complet** : [Issues GitHub](https://github.com/VOTRE-USERNAME/yunohost-mail-security-audit/issues)

---

## 🔐 Sécurité et Confidentialité

### ✅ Ce que fait le script

- Lit les logs système en lecture seule
- Analyse les tentatives d'authentification
- Interroge Fail2ban
- Génère un HTML temporaire
- Envoie un email
- Nettoie automatiquement

### ✅ Ce qu'il ne fait PAS

- ❌ Ne stocke aucun mot de passe
- ❌ Ne modifie aucune configuration
- ❌ Ne se connecte à aucun service externe (sauf ifconfig.me pour l'IP)
- ❌ Ne transmet aucune donnée à des tiers

### ⚠️ Données dans le rapport

Le rapport contient :
- Nom d'hôte du serveur
- IP publique
- IPs attaquantes (anonymes)
- Statistiques d'utilisation

**Recommandation** : Masquez votre IP publique si vous partagez des screenshots publiquement.

---

## 🤝 Contribution

Les contributions sont les bienvenues ! 

### Comment contribuer

1. **Fork** le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Committez (`git commit -m 'Add AmazingFeature'`)
4. Pushez (`git push origin feature/AmazingFeature`)
5. Ouvrez une **Pull Request**

### Idées de contribution

- 📊 Ajouter des graphiques
- 🌍 Support multilingue (EN, ES, DE)
- 🔔 Notifications Telegram/Discord
- 📈 Intégration Grafana
- 🎨 Thèmes personnalisables

---

## 📜 Licence

Ce projet est sous licence **MIT** - voir [LICENSE](LICENSE)

**Vous êtes libre de** :
- ✅ Utiliser commercialement
- ✅ Modifier
- ✅ Distribuer
- ✅ Utiliser en privé

**À condition de** :
- 📄 Inclure la licence et le copyright
- ⚠️ Accepter l'absence de garantie

---

## ⚠️ Disclaimer

**CE LOGICIEL EST FOURNI "TEL QUEL", SANS GARANTIE D'AUCUNE SORTE.**

L'auteur ne peut être tenu responsable de :
- Dysfonctionnements
- Perte de données
- Failles de sécurité
- Problèmes de performances

**Recommandations** :
1. ✅ Testez en dev avant la prod
2. ✅ Faites des backups
3. ✅ Vérifiez les logs
4. ✅ Adaptez les seuils à votre usage

---

## 🙏 Remerciements

- **[YunoHost](https://yunohost.org)** - Auto-hébergement simplifié
- **[Fail2ban](https://www.fail2ban.org)** - Protection contre les attaques
- **[Postfix](http://www.postfix.org/)** - Serveur SMTP
- **[Dovecot](https://www.dovecot.org/)** - Serveur IMAP/POP3
- **Communauté YunoHost** - Support et retours

---

## 📞 Support

- 🐛 **Bug** ? → [Ouvrir une Issue](https://github.com/VOTRE-USERNAME/yunohost-mail-security-audit/issues)
- 💬 **Question** ? → [Discussions GitHub](https://github.com/VOTRE-USERNAME/yunohost-mail-security-audit/discussions)
- 🗨️ **Forum YunoHost** → [Lien vers le topic]

---

## 📈 Roadmap

### Version 1.1
- [ ] Mode interactif
- [ ] Thèmes clair/sombre
- [ ] Export PDF
- [ ] Webhooks (Slack, Discord)

### Version 2.0
- [ ] Dashboard web permanent
- [ ] Graphiques historiques
- [ ] Géolocalisation des IPs
- [ ] Package YunoHost officiel

---

**Version** : 1.0.0  
**Dernière mise à jour** : Janvier 2026  
**Testé sur** : YunoHost 11.x, Debian 12

Made with ❤️ for the self-hosting community
