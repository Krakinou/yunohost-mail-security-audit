#!/bin/bash

# ===================================================================
# Script d'alerte temps réel - Sécurité Mail
# Auteur : Communauté YunoHost
# Licence : MIT
# Repository : https://github.com/gamersalpha/yunohost-mail-security-audit
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

# Analyser la dernière fenêtre de temps (TIME_WINDOW minutes)
TIME_AGO=$(date -d "$TIME_WINDOW minutes ago" '+%Y-%m-%d %H:%M')

# Compter les tentatives sur tous les logs disponibles
ATTEMPTS=$(cat /var/log/mail.log /var/log/mail.log.1 2>/dev/null | \
    awk -v time_ago="$TIME_AGO" '$0 >= time_ago' | \
    grep "auth=0/1" | wc -l)

# Si le nombre de tentatives dépasse le seuil
if [ "$ATTEMPTS" -gt "$THRESHOLD_ATTEMPTS" ]; then
    # Récupérer les détails
    HOSTNAME=$(hostname -f)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Top 5 IPs de la dernière fenêtre
    TOP_IPS=$(cat /var/log/mail.log /var/log/mail.log.1 2>/dev/null | \
        awk -v time_ago="$TIME_AGO" '$0 >= time_ago' | \
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
    
    # Taux d'attaque par minute
    RATE_PER_MIN=$(echo "scale=1; $ATTEMPTS / $TIME_WINDOW" | bc)
    
    # Construire le message d'alerte
    MESSAGE="🚨 ALERTE SÉCURITÉ - Attaque en cours détectée !

Serveur : $HOSTNAME
Heure : $TIMESTAMP

📊 STATISTIQUES DES $TIME_WINDOW DERNIÈRES MINUTES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Tentatives d'authentification échouées : $ATTEMPTS
• Seuil configuré : $THRESHOLD_ATTEMPTS
• Dépassement : +$(( ATTEMPTS - THRESHOLD_ATTEMPTS )) tentatives
• Taux d'attaque : $RATE_PER_MIN tentatives/minute
• IPs bannies par Fail2ban : $BANNED_TOTAL

🎯 TOP 5 DES IPS ATTAQUANTES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$TOP_IPS

🚫 IPS ACTUELLEMENT BANNIES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$(echo -e "$BANNED_LIST")

⚡ ACTIONS RECOMMANDÉES :
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Vérifier les logs temps réel :
   sudo tail -f /var/log/mail.log | grep auth=0/1

2. Vérifier Fail2ban :
   sudo fail2ban-client status postfix
   sudo fail2ban-client status sasl

3. Bloquer manuellement si nécessaire :
   sudo fail2ban-client set postfix banip X.X.X.X

4. Voir le rapport détaillé :
   sudo /root/mail_security_audit_html.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ce message est une alerte automatique générée par Mail Security Audit.
Prochain envoi possible dans $COOLDOWN_MINUTES minutes (anti-spam).
"
    
    # Envoyer l'alerte
    if [ -n "$ALERT_EMAIL" ]; then
        if command -v mail &> /dev/null; then
            echo "$MESSAGE" | mail -s "🚨 [URGENT] Attaque Mail Détectée - $HOSTNAME" "$ALERT_EMAIL"
            
            # Enregistrer le timestamp pour le cooldown
            date +%s > "$COOLDOWN_FILE"
            
            # Logger
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Alerte temps réel envoyée : $ATTEMPTS tentatives en $TIME_WINDOW min (taux: $RATE_PER_MIN/min)" >> /var/log/mail_audit.log
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR : commande 'mail' non disponible" >> /var/log/mail_audit.log
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERREUR : ALERT_EMAIL non configuré" >> /var/log/mail_audit.log
    fi
else
    # Pas d'alerte nécessaire - Logger l'état normal
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Vérification temps réel : $ATTEMPTS tentatives en $TIME_WINDOW min (seuil: $THRESHOLD_ATTEMPTS) - OK" >> /var/log/mail_audit.log
fi

# Supprimer le lock
rm -f "$LOCK_FILE"

exit 0
