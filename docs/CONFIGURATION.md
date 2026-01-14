---

## ⚡ Configuration des Alertes Temps Réel

### Vue d'ensemble

Le script d'alerte temps réel (`mail_security_realtime_alert.sh`) surveille activement votre serveur et envoie des **alertes immédiates** en cas d'attaque massive.

**Différence avec le rapport quotidien** :
- **Rapport quotidien** : Vue d'ensemble complète à 7h00 (HTML)
- **Alerte temps réel** : Notification urgente si seuil dépassé (Texte brut)

---

## 🎛️ Paramètres de base

### Configuration minimale
```bash
# Éditer le script
sudo nano /root/mail_security_realtime_alert.sh
```

**Lignes 11-14 - Paramètres essentiels** :
```bash
ALERT_EMAIL="votre-email@domaine.fr"  # Email destinataire
THRESHOLD_ATTEMPTS=50                  # Seuil de déclenchement
TIME_WINDOW=60                         # Fenêtre d'analyse (minutes)
COOLDOWN_MINUTES=60                    # Anti-spam (minutes)
```

### Explication des paramètres

| Paramètre | Description | Valeur par défaut | Recommandations |
|-----------|-------------|-------------------|-----------------|
| **ALERT_EMAIL** | Email qui reçoit les alertes | `votre-email@domaine.fr` | Email avec notifications push |
| **THRESHOLD_ATTEMPTS** | Nombre de tentatives qui déclenchent l'alerte | `50` | 20-100 selon exposition |
| **TIME_WINDOW** | Fenêtre de temps analysée (minutes) | `60` | 30-120 minutes |
| **COOLDOWN_MINUTES** | Délai minimum entre 2 alertes | `60` | 30-120 minutes |

---

## 🎯 Profils de configuration

### Profil 1 : Serveur Personnel (Peu exposé)
```bash
ALERT_EMAIL="admin@domaine.fr"
THRESHOLD_ATTEMPTS=100     # Tolérant
TIME_WINDOW=120            # 2 heures
COOLDOWN_MINUTES=120       # 1 alerte toutes les 2h max
```

**Crontab** :
```bash
# Vérification toutes les 2 heures
0 */2 * * * /root/mail_security_realtime_alert.sh
```

### Profil 2 : Serveur Standard (Exposition normale)
```bash
ALERT_EMAIL="security@domaine.fr"
THRESHOLD_ATTEMPTS=50      # Normal (défaut)
TIME_WINDOW=60             # 1 heure
COOLDOWN_MINUTES=60        # 1 alerte par heure max
```

**Crontab** :
```bash
# Vérification toutes les heures (recommandé)
0 * * * * /root/mail_security_realtime_alert.sh
```

### Profil 3 : Serveur Critique (Très exposé)
```bash
ALERT_EMAIL="ops-urgent@domaine.fr"
THRESHOLD_ATTEMPTS=20      # Strict
TIME_WINDOW=30             # 30 minutes
COOLDOWN_MINUTES=30        # Alertes fréquentes
```

**Crontab** :
```bash
# Vérification toutes les 15 minutes
*/15 * * * * /root/mail_security_realtime_alert.sh
```

### Profil 4 : Mode Paranoia (Zéro tolérance)
```bash
ALERT_EMAIL="emergency@domaine.fr"
THRESHOLD_ATTEMPTS=10      # Très strict
TIME_WINDOW=15             # 15 minutes
COOLDOWN_MINUTES=15        # Alertes très fréquentes
```

**Crontab** :
```bash
# Vérification toutes les 5 minutes
*/5 * * * * /root/mail_security_realtime_alert.sh
```

---

## 📧 Configuration avancée de l'envoi

### Plusieurs destinataires
```bash
# Ligne 11 du script
ALERT_EMAIL="admin@domaine.fr, security@domaine.fr, ops@domaine.fr"
```

### Email avec copie cachée (BCC)
```bash
# Ligne ~80 du script - remplacer par :
echo "$MESSAGE" | mail -s "🚨 [URGENT] Attaque Mail Détectée - $HOSTNAME" \
    -b "copie-cachee@domaine.fr" \
    "$ALERT_EMAIL"
```

### Changer l'expéditeur
```bash
# Dans ~/.muttrc (ou créer si inexistant)
cat >> ~/.muttrc << 'EOF'
# Pour les alertes urgentes
set from = "alerte-securite@votre-domaine.fr"
set realname = "Système Alerte Sécurité"
EOF
```

### Priorité haute pour les alertes
```bash
# Ligne ~80 du script - remplacer par :
echo "$MESSAGE" | mail -s "🚨 [URGENT] Attaque Mail Détectée - $HOSTNAME" \
    -a "X-Priority: 1" \
    -a "Importance: high" \
    "$ALERT_EMAIL"
```

---

## 🔔 Intégrations avec d'autres services

### Slack Webhook
```bash
# Ajouter après la ligne 80 (envoi email)
SLACK_WEBHOOK="https://hooks.slack.com/services/VOTRE/WEBHOOK/URL"
SLACK_MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')

curl -X POST "$SLACK_WEBHOOK" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"$SLACK_MESSAGE\"}"
```

### Discord Webhook
```bash
# Ajouter après la ligne 80
DISCORD_WEBHOOK="https://discord.com/api/webhooks/VOTRE/WEBHOOK"

curl -X POST "$DISCORD_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"$MESSAGE\"}"
```

### Telegram Bot
```bash
# Ajouter après la ligne 80
TELEGRAM_BOT_TOKEN="votre_token_bot"
TELEGRAM_CHAT_ID="votre_chat_id"

curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$MESSAGE"
```

### SMS (via service comme Twilio)
```bash
# Ajouter après la ligne 80
TWILIO_ACCOUNT_SID="votre_sid"
TWILIO_AUTH_TOKEN="votre_token"
TWILIO_FROM="+33123456789"
TWILIO_TO="+33987654321"

curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
    --data-urlencode "Body=ALERTE SECURITE: $ATTEMPTS tentatives en $TIME_WINDOW min sur $HOSTNAME" \
    --data-urlencode "From=$TWILIO_FROM" \
    --data-urlencode "To=$TWILIO_TO" \
    -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
```

---

## 🎨 Personnalisation du message d'alerte

### Format par défaut
```bash
# Lignes 50-75 du script
MESSAGE="🚨 ALERTE SÉCURITÉ - Attaque en cours détectée !
...
"
```

### Format court (pour SMS)
```bash
# Remplacer la construction du MESSAGE par :
MESSAGE="🚨 ALERTE $HOSTNAME: $ATTEMPTS tentatives/$TIME_WINDOW min. Top IP: $(echo "$TOP_IPS" | head -1 | awk '{print $2}'). IPs ban: $BANNED_TOTAL"
```

### Format technique détaillé
```bash
MESSAGE="🚨 ALERTE SÉCURITÉ MAIL
═══════════════════════════════════════════
📍 Serveur : $HOSTNAME
🕐 Timestamp : $TIMESTAMP
📊 Période : $TIME_WINDOW dernières minutes

⚠️ MÉTRIQUES D'ATTAQUE
───────────────────────────────────────────
- Tentatives totales : $ATTEMPTS
- Seuil configuré : $THRESHOLD_ATTEMPTS
- Dépassement : +$(( ATTEMPTS - THRESHOLD_ATTEMPTS )) tentatives
- Taux : $(( ATTEMPTS / TIME_WINDOW )) tentatives/minute

🎯 TOP 5 DES SOURCES
───────────────────────────────────────────
$TOP_IPS

🛡️ DÉFENSE FAIL2BAN
───────────────────────────────────────────
- Total IPs bannies : $BANNED_TOTAL
- Détails par jail :
$(echo -e "$BANNED_LIST")

⚡ COMMANDES RAPIDES
───────────────────────────────────────────
# Logs temps réel
tail -f /var/log/mail.log | grep auth=0/1

# Status Fail2ban
fail2ban-client status postfix

# Ban manuel
fail2ban-client set postfix banip X.X.X.X

═══════════════════════════════════════════
Alerte générée automatiquement
Prochain envoi possible dans $COOLDOWN_MINUTES min
"
```

---

## ⏱️ Fréquence de vérification (Crontab)

### Modifier la fréquence
```bash
# Éditer le crontab
sudo crontab -e
```

**Options de fréquence** :
```bash
# Toutes les 5 minutes (très actif)
*/5 * * * * /root/mail_security_realtime_alert.sh

# Toutes les 10 minutes
*/10 * * * * /root/mail_security_realtime_alert.sh

# Toutes les 15 minutes (recommandé pour serveurs exposés)
*/15 * * * * /root/mail_security_realtime_alert.sh

# Toutes les 30 minutes (équilibré)
*/30 * * * * /root/mail_security_realtime_alert.sh

# Toutes les heures (défaut, bon pour la plupart)
0 * * * * /root/mail_security_realtime_alert.sh

# Toutes les 2 heures (léger)
0 */2 * * * /root/mail_security_realtime_alert.sh

# Seulement pendant les heures de bureau (9h-18h)
0 9-18 * * * /root/mail_security_realtime_alert.sh

# Seulement en semaine
0 * * * 1-5 /root/mail_security_realtime_alert.sh
```

### Combiner avec le rapport quotidien
```bash
# Dans le même crontab
# Rapport quotidien HTML à 7h00
0 7 * * * /root/mail_security_audit_html.sh

# Alerte temps réel toutes les heures
0 * * * * /root/mail_security_realtime_alert.sh
```

---

## 🧪 Tests et validation

### Test 1 : Vérifier la configuration
```bash
# Syntaxe du script
bash -n /root/mail_security_realtime_alert.sh

# Afficher la config
head -20 /root/mail_security_realtime_alert.sh
```

### Test 2 : Forcer une alerte (mode debug)
```bash
# Temporairement abaisser le seuil
sudo nano /root/mail_security_realtime_alert.sh
# Changer ligne 12 : THRESHOLD_ATTEMPTS=1

# Lancer en mode debug
sudo bash -x /root/mail_security_realtime_alert.sh

# Vérifier l'email reçu
# Remettre le seuil à 50 !
```

### Test 3 : Simuler une attaque
```bash
# Créer 60 tentatives factices dans les logs (pour test uniquement !)
for i in {1..60}; do
    echo "$(date '+%b %d %H:%M:%S') test postfix/smtpd[$$]: disconnect from unknown[1.2.3.4] ehlo=1 auth=0/1 commands=2/3" | sudo tee -a /var/log/mail.log > /dev/null
done

# Lancer l'alerte
sudo /root/mail_security_realtime_alert.sh

# Nettoyer les logs de test
sudo sed -i '/disconnect from unknown\[1.2.3.4\]/d' /var/log/mail.log
```

### Test 4 : Vérifier le cooldown
```bash
# Lancer deux fois de suite
sudo /root/mail_security_realtime_alert.sh
sudo /root/mail_security_realtime_alert.sh

# La deuxième fois ne doit PAS envoyer d'email
# Vérifier les logs
tail -5 /var/log/mail_audit.log
```

---

## 🔧 Désactiver temporairement les alertes

### Méthode 1 : Commenter le cron
```bash
sudo crontab -e

# Ajouter un # devant la ligne
# 0 * * * * /root/mail_security_realtime_alert.sh
```

### Méthode 2 : Augmenter drastiquement le seuil
```bash
sudo nano /root/mail_security_realtime_alert.sh
# Changer : THRESHOLD_ATTEMPTS=999999
```

### Méthode 3 : Supprimer temporairement le fichier
```bash
# Renommer
sudo mv /root/mail_security_realtime_alert.sh /root/mail_security_realtime_alert.sh.disabled

# Le cron ne trouvera pas le fichier et ne fera rien
```

---

## 📊 Logs et monitoring

### Consulter les logs des alertes
```bash
# Logs du script
tail -f /var/log/mail_audit.log

# Filtrer uniquement les alertes temps réel
grep "Alerte temps réel" /var/log/mail_audit.log

# Compter les alertes envoyées aujourd'hui
grep "$(date '+%Y-%m-%d')" /var/log/mail_audit.log | grep "Alerte temps réel" | wc -l
```

### Vérifier le cooldown actuel
```bash
# Afficher le timestamp du cooldown
cat /tmp/mail_alert_cooldown

# Convertir en date lisible
date -d @$(cat /tmp/mail_alert_cooldown) '+%Y-%m-%d %H:%M:%S'

# Temps restant avant prochaine alerte possible
LAST=$(cat /tmp/mail_alert_cooldown 2>/dev/null || echo 0)
NOW=$(date +%s)
REMAINING=$(( 60 - (NOW - LAST) / 60 ))
echo "Prochaine alerte possible dans : $REMAINING minutes"
```

### Réinitialiser le cooldown (forcer une alerte)
```bash
# Supprimer le fichier de cooldown
sudo rm /tmp/mail_alert_cooldown

# La prochaine exécution pourra envoyer une alerte
```

---

## 🎛️ Scénarios de configuration avancés

### Scénario 1 : Alertes différentes selon la gravité
```bash
# Créer 2 versions du script avec seuils différents

# Script 1 : Alerte normale (50 tentatives)
cp /root/mail_security_realtime_alert.sh /root/mail_alert_normal.sh
# THRESHOLD_ATTEMPTS=50, ALERT_EMAIL="admin@domaine.fr"

# Script 2 : Alerte critique (200 tentatives)
cp /root/mail_security_realtime_alert.sh /root/mail_alert_critical.sh
# THRESHOLD_ATTEMPTS=200, ALERT_EMAIL="urgence@domaine.fr"

# Crontab
0 * * * * /root/mail_alert_normal.sh    # Toutes les heures
0 * * * * /root/mail_alert_critical.sh  # Toutes les heures
```

### Scénario 2 : Alertes uniquement la nuit
```bash
# Dans le crontab
# Vérifier toutes les 15 min entre 22h et 6h (quand vous dormez)
*/15 22-23,0-6 * * * /root/mail_security_realtime_alert.sh

# Rapport quotidien au réveil
0 7 * * * /root/mail_security_audit_html.sh
```

### Scénario 3 : Alertes progressives (escalade)
```bash
# Créer 3 scripts avec seuils croissants

# Niveau 1 : Surveillance (50 tentatives) → Email normal
THRESHOLD_ATTEMPTS=50
ALERT_EMAIL="monitoring@domaine.fr"

# Niveau 2 : Attention (100 tentatives) → Email + Slack
THRESHOLD_ATTEMPTS=100
ALERT_EMAIL="admin@domaine.fr"
# + Slack webhook

# Niveau 3 : Critique (200 tentatives) → Email + SMS + Appel
THRESHOLD_ATTEMPTS=200
ALERT_EMAIL="emergency@domaine.fr"
# + SMS + Appel téléphonique automatique
```

---

## 🔍 Dépannage des alertes temps réel

### Problème : Aucune alerte reçue
```bash
# 1. Vérifier que le script s'exécute
grep "mail_security_realtime_alert" /var/log/syslog

# 2. Vérifier les logs du script
tail -20 /var/log/mail_audit.log

# 3. Tester manuellement
sudo /root/mail_security_realtime_alert.sh

# 4. Vérifier le crontab
sudo crontab -l | grep realtime
```

### Problème : Trop d'alertes (spam)
```bash
# Augmenter le cooldown
sudo nano /root/mail_security_realtime_alert.sh
# Ligne 14 : COOLDOWN_MINUTES=120  # 2 heures au lieu de 1

# Augmenter le seuil
# Ligne 12 : THRESHOLD_ATTEMPTS=100  # Au lieu de 50
```

### Problème : Alertes en retard
```bash
# Augmenter la fréquence de vérification
sudo crontab -e
# Changer de : 0 * * * *
# À : */15 * * * *  # Toutes les 15 minutes
```

### Problème : Fausses alertes
```bash
# Vérifier les logs manuellement
sudo grep "auth=0/1" /var/log/mail.log | tail -100

# Ajuster TIME_WINDOW (fenêtre plus large)
TIME_WINDOW=120  # 2 heures au lieu de 1

# Ou THRESHOLD plus élevé
THRESHOLD_ATTEMPTS=100  # Au lieu de 50
```

---

## ✅ Checklist de configuration optimale

### Configuration recommandée pour la majorité des serveurs
```bash
# Script d'alerte temps réel
ALERT_EMAIL="votre-email@domaine.fr"
THRESHOLD_ATTEMPTS=50
TIME_WINDOW=60
COOLDOWN_MINUTES=60

# Crontab
0 * * * * /root/mail_security_realtime_alert.sh      # Alertes toutes les heures
0 7 * * * /root/mail_security_audit_html.sh          # Rapport quotidien à 7h
```

### Vérifications post-installation

- [ ] Email destinataire configuré
- [ ] Seuils adaptés à votre trafic
- [ ] Test manuel réussi
- [ ] Crontab configuré
- [ ] Email de test reçu
- [ ] Logs fonctionnels
- [ ] Cooldown vérifié

---

## 📚 Exemples de logs typiques

### Log normal (pas d'alerte)
```
2026-01-14 15:00:01 - Vérification temps réel : 23 tentatives (seuil: 50) - OK
```

### Log avec alerte envoyée
```
2026-01-14 15:00:01 - Alerte temps réel envoyée : 127 tentatives en 60 min
```

### Log pendant cooldown
```
2026-01-14 15:30:01 - Cooldown actif, prochaine alerte possible à 16:00:00
```

---

**Configuration des alertes temps réel terminée !** ⚡

Vous disposez maintenant d'un système complet :
- 📧 **Rapport quotidien détaillé** (HTML, 7h00)
- ⚡ **Alertes immédiates** (Texte, temps réel)
- 🔔 **Intégrations possibles** (Slack, Discord, Telegram, SMS)
