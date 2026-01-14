#!/bin/bash

# ===================================================================
# Script d'alerte temps réel - Sécurité Mail
# Auteur : Communauté YunoHost
# Licence : MIT
# Description : Envoie une alerte immédiate en cas d'attaque massive
# ===================================================================

# ⚠️ CONFIGURATION - MODIFIEZ CES LIGNES ⚠️
ALERT_EMAIL="votre-email@domaine.fr"
THRESHOLD_ATTEMPTS=50  # Nombre de tentatives qui déclenchent une alerte
TIME_WINDOW=60         # Fenêtre de temps en minutes

LOG_FILE="/var/log/mail.log"
LOCK_FILE="/tmp/mail_alert.lock"
COOLDOWN_FILE="/tmp/mail_alert_cooldown"
COOLDOWN_MINUTES=60    # Éviter le spam d'alertes (1 alerte par heure max)

# Vérifier le cooldown (éviter trop d'alertes)
if [ -f "$COOLDOWN_FILE" ]; then
    LAST_ALERT=$(cat "$COOLDOWN_FILE")
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$(( (CURRENT_TIME - LAST_ALERT) / 60 ))
    
    if [ "$TIME_DIFF" -lt "$COOLDOWN_MINUTES" ]; then
        # Trop tôt pour envoyer une nouvelle alerte
        exit 0
    fi
fi

# Créer un lock pour éviter les exécutions simultanées
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi
touch "$LOCK_FILE"

# Analyser la dernière heure
TIME_AGO=$(date -d "$TIME_WINDOW minutes ago" '+%Y-%m-%d %H:%M')
ATTEMPTS=$(grep "$TIME_AGO" "$LOG_FILE" 2>/dev/null | grep "auth=0/1" | wc -l)

# Si le nombre de tentatives dépasse le seuil
if [ "$ATTEMPTS" -gt "$THRESHOLD_ATTEMPTS" ]; then
    # Récupérer les détails
    HOSTNAME=$(hostname -f)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Top 5 IPs de la dernière heure
    TOP_IPS=$(grep "$TIME_AGO" "$LOG_FILE" 2>/dev/null | \
        grep "auth=0/1" | \
        grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | \
        sort | uniq -c | sort -rn | head -5)
    
    # État Fail2ban
    BANNED_TOTAL=0
    BANNED_LIST=""
    for jail in postfix sasl dovecot; do
        if fail2ban-client status "$jail" &>/dev/null; then
            BANNED=$(fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned" | awk '{print $4}')
            BANNED_TOTAL=$((BANNED_TOTAL + BANNED))
            IPS=$(fail2ban-client status "$jail" 2>/dev/null | grep "Banned IP list" | awk -F: '{print $2}')
            if [ -n "$IPS" ]; then
                BANNED_LIST+="$jail: $IPS\n"
            fi
        fi
    done
    
    # Construire le message d'alerte
    MESSAGE="🚨 ALERTE SÉCURITÉ - Attaque en cours détectée !

Serveur : $HOSTNAME
Heure : $TIMESTAMP

📊 STATISTIQUES DES $TIME_WINDOW DERNIÈRES MINUTES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Tentatives d'authentification échouées : $ATTEMPTS
- Seuil configuré : $THRESHOLD_ATTEMPTS
- IPs bannies par Fail2ban : $BANNED_TOTAL

🎯 TOP 5 DES IPS ATTAQUANTES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$TOP_IPS

🚫 IPS ACTUELLEMENT BANNIES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$(echo -e "$BANNED_LIST")

⚡ ACTIONS RECOMMANDÉES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Vérifier les logs : sudo tail -100 /var/log/mail.log
2. Vérifier Fail2ban : sudo fail2ban-client status postfix
3. Bloquer manuellement si nécessaire : sudo fail2ban-client set postfix banip X.X.X.X

Ce message est une alerte automatique générée par Mail Security Audit.
Prochain envoi possible dans $COOLDOWN_MINUTES minutes (anti-spam).
"
    
    # Envoyer l'alerte
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$MESSAGE" | mail -s "🚨 [URGENT] Attaque Mail Détectée - $HOSTNAME" "$ALERT_EMAIL"
        
        # Enregistrer le timestamp pour le cooldown
        date +%s > "$COOLDOWN_FILE"
        
        # Logger
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Alerte temps réel envoyée : $ATTEMPTS tentatives en $TIME_WINDOW min" >> /var/log/mail_audit.log
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR : ALERT_EMAIL non configuré" >> /var/log/mail_audit.log
    fi
fi

# Supprimer le lock
rm -f "$LOCK_FILE"

exit 0
