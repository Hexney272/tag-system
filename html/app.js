const playersEl  = document.getElementById('players');
const vehiclesEl = document.getElementById('vehicles');

// ====== Inline SVG ikonok (offline) ======
const ICONS = {
    voice:  `<svg viewBox="0 0 24 24"><path d="M12 14a3 3 0 0 0 3-3V5a3 3 0 0 0-6 0v6a3 3 0 0 0 3 3zm5-3a5 5 0 0 1-10 0H5a7 7 0 0 0 6 6.92V21h2v-3.08A7 7 0 0 0 19 11h-2z"/></svg>`,
    armour: `<svg viewBox="0 0 24 24"><path d="M12 2 4 5v6c0 5 3.4 9.7 8 11 4.6-1.3 8-6 8-11V5l-8-3z"/></svg>`,
    weapon: `<svg viewBox="0 0 24 24"><path d="M7 5h13v4h-2v2h-4l-2 3H8l-1-2H4V7h3V5zm0 8h3l1 2v3H8l-1-2v-3z"/></svg>`,
    cuffed: `<svg viewBox="0 0 24 24"><path d="M7 9a4 4 0 0 1 4 4v3a4 4 0 1 1-8 0v-3a4 4 0 0 1 4-4zm0 2a2 2 0 0 0-2 2v3a2 2 0 1 0 4 0v-3a2 2 0 0 0-2-2zm10-2a4 4 0 0 1 4 4v3a4 4 0 1 1-8 0v-3a4 4 0 0 1 4-4zm0 2a2 2 0 0 0-2 2v3a2 2 0 1 0 4 0v-3a2 2 0 0 0-2-2zM8 7h8v2H8z"/></svg>`,
    cross:  `<svg viewBox="0 0 24 24"><path d="M9 2h6v7h7v6h-7v7H9v-7H2V9h7z"/></svg>`
};

const tags = {};   // serverId -> element
const plates = {}; // netId -> element

function fmtTime(sec) {
    sec = Math.max(0, Math.floor(sec));
    const m = String(Math.floor(sec / 60)).padStart(2, '0');
    const s = String(sec % 60).padStart(2, '0');
    return `${m}:${s}`;
}

// ====== JÁTÉKOS TAGEK ======
function renderPlayers(list) {
    const seen = {};
    const sw = window.innerWidth, sh = window.innerHeight;

    for (const p of list) {
        seen[p.serverId] = true;
        let el = tags[p.serverId];

        if (!el) {
            el = document.createElement('div');
            el.className = 'tag';
            el.innerHTML = `
                <div class="row">
                    <span class="name"></span>
                    <span class="icons"></span>
                </div>
                <div class="job"></div>
                <div class="death">
                    <span class="cross">${ICONS.cross}</span>
                    <span class="timer"></span>
                </div>
            `;
            el._cache = {};
            playersEl.appendChild(el);
            tags[p.serverId] = el;
        }

        // pozíció + skála
        el.style.left = (p.x * sw) + 'px';
        el.style.top  = (p.y * sh) + 'px';
        el.style.transform = `translate(-50%, -100%) scale(${p.scale.toFixed(3)})`;

        const isDeadTimer = p.dead && p.deathRemaining > 0;
        el.classList.toggle('dead', !!isDeadTimer);

        if (isDeadTimer) {
            // csak a halott-időzítő látszik
            el.querySelector('.death').style.display = 'flex';
            el.querySelector('.timer').textContent = fmtTime(p.deathRemaining);
        } else {
            el.querySelector('.death').style.display = 'none';

            // név + ID
            const nameKey = `${p.name}|${p.serverId}`;
            if (el._cache.name !== nameKey) {
                el.querySelector('.name').innerHTML =
                    `${p.name} <span class="id">[${p.serverId}]</span>`;
                el._cache.name = nameKey;
            }

            // frakció / rang sor
            const jobEl = el.querySelector('.job');
            if (p.job && p.job.label) {
                const badge = p.job.badge ? ` <span class="badge">#${p.job.badge}</span>` : '';
                const grade = p.job.grade ? ` ${p.job.grade}` : '';
                const jobHtml = `${p.job.label}${badge}${grade}`;
                if (el._cache.job !== jobHtml) {
                    jobEl.innerHTML = jobHtml;
                    el._cache.job = jobHtml;
                }
                jobEl.style.display = 'block';
            } else {
                jobEl.style.display = 'none';
                el._cache.job = null;
            }

            // ikonok (a név jobb oldalán)
            const icons = [];
            if (p.talking) icons.push(`<span class="icon voice">${ICONS.voice}</span>`);
            if (p.cuffed)  icons.push(`<span class="icon cuffed">${ICONS.cuffed}</span>`);
            if (p.armour)  icons.push(`<span class="icon armour">${ICONS.armour}</span>`);
            if (p.weapon)  icons.push(`<span class="icon weapon">${ICONS.weapon}</span>`);
            const joined = icons.join('');
            const iconsEl = el.querySelector('.icons');
            if (el._cache.icons !== joined) {
                iconsEl.innerHTML = joined;
                el._cache.icons = joined;
            }
        }
    }

    for (const id in tags) {
        if (!seen[id]) { tags[id].remove(); delete tags[id]; }
    }
}

// ====== JÁRMŰ RENDSZÁMTÁBLÁK ======
function renderVehicles(list, brand, server) {
    const seen = {};
    const sw = window.innerWidth, sh = window.innerHeight;

    for (const v of list) {
        if (!v.plate) continue;
        seen[v.netId] = true;
        let el = plates[v.netId];

        if (!el) {
            el = document.createElement('div');
            el.className = 'plate';
            el.innerHTML = `
                <div class="board">
                    <div class="brand"></div>
                    <div class="number"></div>
                    <div class="sub"></div>
                </div>
            `;
            el._cache = {};
            vehiclesEl.appendChild(el);
            plates[v.netId] = el;
        }

        el.style.left = (v.x * sw) + 'px';
        el.style.top  = (v.y * sh) + 'px';
        el.style.transform = `translate(-50%, -100%) scale(${v.scale.toFixed(3)})`;

        if (el._cache.plate !== v.plate) {
            el.querySelector('.brand').textContent = brand || 'RealRP';
            el.querySelector('.number').textContent = v.plate;
            el.querySelector('.sub').textContent = server || '';
            el._cache.plate = v.plate;
        }
    }

    for (const id in plates) {
        if (!seen[id]) { plates[id].remove(); delete plates[id]; }
    }
}

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'players') {
        renderPlayers(d.players || []);
    } else if (d.action === 'vehicles') {
        renderVehicles(d.vehicles || [], d.brand, d.server);
    }
});
