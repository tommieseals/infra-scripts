#!/bin/bash
cd ~/clawd/dashboard

# Create TaskBot card file
cat > /tmp/taskbot_card.html << 'TASKBOT'
            <div class="project-card current-focus" style="border-left-color: #f59e0b; background: rgba(245, 158, 11, 0.15);">
                <h3>💰 TASKBOT - Enterprise Automation Platform <span class="badge badge-in-progress">PRIORITY #1</span></h3>
                <p><strong>Started:</strong> February 23, 2026</p>
                <p><strong>Goal:</strong> Build and sell enterprise automation platform. THIS IS HOW WE MAKE MONEY.</p>
                <p><strong>Public URL:</strong> <a href="https://later-plot-cuts-corrections.trycloudflare.com" style="color: #fbbf24;">https://later-plot-cuts-corrections.trycloudflare.com</a></p>
                <p><strong>Dashboard:</strong> <a href="/taskbot.html" style="color: #fbbf24;">/taskbot.html</a></p>
                <p><strong>Current Version:</strong> Power Automate Clone (v2)</p>
                <p><strong>Pages Built:</strong> Homepage, Case Studies, Security, Discovery, Finance/HR Verticals</p>
                <p><strong>Next:</strong> Marketing, Domain, Payment integration</p>
            </div>
            
            <div class="project-card" style="border-left-color: #1d9bf0;">
                <h3>🐦 Twitter Outreach Strategy <span class="badge badge-in-progress">IN PROGRESS</span></h3>
                <p><strong>Started:</strong> February 25, 2026</p>
                <p><strong>Goal:</strong> Build presence in orphan drug/rare disease Twitter space</p>
                <p><strong>Targets:</strong> 45+ (Goal: 200+) | Key: @eperlste, @BioDueDiligence</p>
                <p><strong>Status:</strong> ⚠️ BLOCKED - Rusty needs to create @ArbitragePharma manually</p>
            </div>

TASKBOT

# Create Arbitrage Pharma card file
cat > /tmp/arbitrage_card.html << 'ARBITRAGE'
            
            <div class="project-card" style="border-left-color: #10b981; background: rgba(16, 185, 129, 0.1);">
                <h3>🧬 ARBITRAGE PHARMA - Orphan Drug Platform <span class="badge badge-complete">100% COMPLETE</span></h3>
                <p><strong>Completed:</strong> February 24, 2026</p>
                <p><strong>Public Site:</strong> <a href="https://arbitrage-pharma.pages.dev/" style="color: #10b981;">https://arbitrage-pharma.pages.dev/</a></p>
                <p><strong>Dashboard:</strong> <a href="/arbitrage-pharma.html" style="color: #10b981;">/arbitrage-pharma.html</a></p>
                <p><strong>All 9 Layers:</strong> Harvesters, Alchemists, Moat Builders, Hustlers, Cartographers, CRM, Competitive Intel, Pitch Deck, Master Pipeline</p>
                <p><strong>Top Compounds:</strong> Tolrestat (92), Mibefradil (88), Rimonabant (85)</p>
                <p><strong>Built with:</strong> 8+ agent swarm (hours, not weeks!)</p>
            </div>
ARBITRAGE

# Use awk to insert at specific lines
# Line 266 = after "Currently Working On" h2 tag
# Line 292 = after "Recently Completed" h2 tag (this will shift after first insert)
awk '
NR==266 { print; while ((getline line < "/tmp/taskbot_card.html") > 0) print line; next }
NR==292 { print; while ((getline line < "/tmp/arbitrage_card.html") > 0) print line; next }
{ print }
' projects.html > /tmp/projects_new.html

# Verify and replace
if [ -s /tmp/projects_new.html ]; then
    mv /tmp/projects_new.html projects.html
    echo "✅ projects.html updated successfully"
    echo "Added: TaskBot card after line 266"
    echo "Added: Arbitrage Pharma card after line 292"
else
    echo "❌ Error: new file is empty"
fi
