const playersEl  = document.getElementById('players');
const vehiclesEl = document.getElementById('vehicles');

// ====== Inline SVG ikonok (offline, élesek minden felbontáson) ======
// FA6 stílusú formák: microphone-lines, handcuffs, shield-halved, gun, medical cross
const ICONS = {
    voice:  `<svg viewBox="0 0 384 512"><path d="M192 0C139 0 96 43 96 96v160c0 53 43 96 96 96s96-43 96-96V96c0-53-43-96-96-96zm-16 88a16 16 0 0 1 32 0 16 16 0 0 1-32 0zm0 80a16 16 0 0 1 32 0 16 16 0 0 1-32 0zm-128 88c0-13 11-24 24-24s24 11 24 24a96 96 0 0 0 192 0c0-13 11-24 24-24s24 11 24 24a144 144 0 0 1-120 142v34h48a24 24 0 0 1 0 48H120a24 24 0 0 1 0-48h48v-34A144 144 0 0 1 48 256z"/></svg>`,
    armour: `<svg viewBox="0 0 512 512"><path d="M256 0c-4 0-8 1-12 3L54 84c-13 6-22 19-22 33 0 154 90 264 202 311 4 2 8 3 12 3V0z" opacity=".95"/><path d="M256 0c4 0 8 1 12 3l190 81c13 6 22 19 22 33 0 154-90 264-202 311-4 2-8 3-12 3V0z" opacity=".75"/></svg>`,
    weapon: `<svg viewBox="0 0 640 512"><path d="M96 96c-18 0-32 14-32 32v32H32a32 32 0 0 0 0 64h32v32c0 18 14 32 32 32h48l40 56c6 8 15 12 25 12h53c12 0 23-7 28-18l18-38h156a48 48 0 0 0 48-48v-48a48 48 0 0 0-48-48H160v-28c0-18-14-32-32-32H96zm48 192h64l-26 48h-22l-16-22v-26z"/></svg>`,
    cuffed: `<svg viewBox="0 0 640 512"><path d="M176 96a112 112 0 1 0 0 224 112 112 0 0 0 0-224zm0 64a48 48 0 1 1 0 96 48 48 0 0 1 0-96zM464 96a112 112 0 1 0 0 224 112 112 0 0 0 0-224zm0 64a48 48 0 1 1 0 96 48 48 0 0 1 0-96zM240 200h160v32H240z"/></svg>`,
    cross:  `<svg viewBox="0 0 448 512"><path d="M160 32c-18 0-32 14-32 32v64H64c-18 0-32 14-32 32v96c0 18 14 32 32 32h64v128c0 18 14 32 32 32h128c18 0 32-14 32-32V320h64c18 0 32-14 32-32v-96c0-18-14-32-32-32h-64V64c0-18-14-32-32-32H160z"/></svg>`
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
