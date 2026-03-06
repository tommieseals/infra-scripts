#!/bin/bash
# Auto Email Check - Runs every 15 minutes
# Fixed 2026-03-02: Better recruiter detection, excludes spam

# Read credentials from .env
if [ -f ~/clawd/.env ]; then
    export $(grep -v '^#' ~/clawd/.env | xargs)
fi

python3 << 'PYCODE'
import imaplib
import email
from datetime import datetime, timedelta
import os

app_pass = os.getenv('GMAIL_APP_PASSWORD', '')

if not app_pass or len(app_pass) < 10:
    print("⚠️ App password not configured")
    exit(0)

try:
    mail = imaplib.IMAP4_SSL('imap.gmail.com')
    mail.login('tommieseals7700@gmail.com', app_pass)
    mail.select('INBOX')
    
    # Check last 2 hours (since it runs every 15 min)
    since = (datetime.now() - timedelta(hours=2)).strftime('%d-%b-%Y')
    status, messages = mail.search(None, f'(SINCE {since})')
    
    if status == 'OK' and messages[0]:
        msg_nums = messages[0].split()
        
        # IMPROVED: Specific recruiter keywords
        recruiter_sources = [
            'linkedin.com', 'indeed.com', 'ziprecruiter.com', 
            'glassdoor.com', 'dice.com', 'monster.com',
            'talent', 'recruiting', 'recruiter@', 'careers@',
            'hr@', 'hiring'
        ]
        
        recruiter_subjects = [
            'job opportunity', 'position available', 'interview',
            'phone screen', 'technical interview', 'application',
            'career opportunity', 'hiring for'
        ]
        
        # SPAM EXCLUSIONS
        spam_keywords = [
            'siriusxm', 'subscription', 'discount', 'sale',
            'offer ends', 'limited time', 'buy now', 'promo'
        ]
        
        urgent = []
        for num in msg_nums[-30:]:  # Check last 30
            try:
                status, data = mail.fetch(num, '(RFC822)')
                msg = email.message_from_bytes(data[0][1])
                
                subject = str(msg.get('Subject', ''))
                from_addr = str(msg.get('From', ''))
                full_text = (subject + ' ' + from_addr).lower()
                
                # Check if recruiter email
                is_recruiter = any(src in full_text for src in recruiter_sources)
                is_recruiter = is_recruiter or any(subj in subject.lower() for subj in recruiter_subjects)
                
                # Exclude spam
                is_spam = any(spam in full_text for spam in spam_keywords)
                
                if is_recruiter and not is_spam:
                    urgent.append(f"{from_addr[:50]}: {subject[:60]}")
            except:
                continue
        
        if urgent:
            print(f"🚨 {len(urgent)} RECRUITER EMAILS:")
            for u in urgent[:10]:
                print(f"  - {u}")
        else:
            print(f"✅ No new recruiter emails (checked {len(msg_nums)} total)")
    else:
        print("✅ No new emails in last 2 hours")
    
    mail.close()
    mail.logout()
    
except Exception as e:
    print(f"❌ Email check error: {e}")

PYCODE
