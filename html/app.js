const playersEl  = document.getElementById('players');
const vehiclesEl = document.getElementById('vehicles');

// ====== MUNKA SZÍNEK ======
let jobColors = {};

// ====== Inline SVG ikonok (a felhasználó által megadott kártya-stílus) ======
const BG_WHITE = { fill: '#ECECEC', stroke: '#B8B8B8' };
const BG_GREEN = { fill: '#CFE4CF', stroke: '#9BB79B' };

function card(bg, inner) {
    return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">`
        + `<rect x="4" y="4" width="120" height="120" rx="12" fill="${bg.fill}" stroke="${bg.stroke}" stroke-width="2"/>`
        + inner + `</svg>`;
}

const ICONS = {
    // mikrofon: zöld (csak beszéd közben jelenik meg)
    mic(active) {
        return card(active ? BG_GREEN : BG_WHITE,
            `<rect x="44" y="22" width="40" height="54" rx="20" fill="none" stroke="#2A2A2A" stroke-width="4"/>`
          + `<path d="M38 66 C38 88 52 98 64 98 C76 98 90 88 90 66" fill="none" stroke="#2A2A2A" stroke-width="4" stroke-linecap="round"/>`
          + `<line x1="64" y1="98" x2="64" y2="112" stroke="#2A2A2A" stroke-width="4"/>`
          + `<line x1="48" y1="112" x2="80" y2="112" stroke="#2A2A2A" stroke-width="4" stroke-linecap="round"/>`);
    },
    radio: card(BG_WHITE,
        `<rect x="38" y="28" width="52" height="72" rx="6" fill="none" stroke="#2A2A2A" stroke-width="4"/>`
      + `<circle cx="64" cy="50" r="10" fill="none" stroke="#2A2A2A" stroke-width="3"/>`
      + `<line x1="80" y1="28" x2="92" y2="12" stroke="#2A2A2A" stroke-width="4"/>`
      + `<line x1="50" y1="74" x2="78" y2="74" stroke="#2A2A2A" stroke-width="3"/>`
      + `<line x1="50" y1="84" x2="78" y2="84" stroke="#2A2A2A" stroke-width="3"/>`),
    phone: card(BG_WHITE,
        `<rect x="42" y="18" width="44" height="92" rx="8" fill="none" stroke="#2A2A2A" stroke-width="4"/>`
      + `<circle cx="64" cy="94" r="4" fill="#2A2A2A"/>`
      + `<rect x="50" y="28" width="28" height="50" fill="none" stroke="#2A2A2A" stroke-width="2"/>`),
    armour: card(BG_WHITE,
        `<path d="M44 22 H84 C84 38 88 48 98 56 V96 H30 V56 C40 48 44 38 44 22Z" fill="none" stroke="#2A2A2A" stroke-width="4"/>`
      + `<rect x="40" y="54" width="16" height="8" fill="none" stroke="#2A2A2A" stroke-width="2"/>`
      + `<rect x="72" y="54" width="16" height="8" fill="none" stroke="#2A2A2A" stroke-width="2"/>`
      + `<rect x="40" y="72" width="16" height="8" fill="none" stroke="#2A2A2A" stroke-width="2"/>`
      + `<rect x="72" y="72" width="16" height="8" fill="none" stroke="#2A2A2A" stroke-width="2"/>`
      + `<rect x="58" y="50" width="12" height="34" fill="none" stroke="#2A2A2A" stroke-width="2"/>`),
    // biztonsági öv: fehér = nincs becsatolva, zöld = becsatolva
    seatbelt(buckled) {
        return card(buckled ? BG_GREEN : BG_WHITE,
            `<circle cx="64" cy="34" r="12" fill="none" stroke="#2A2A2A" stroke-width="4"/>`
          + `<path d="M42 60 C42 50 50 46 64 46 C78 46 86 50 86 60 V92 H42 Z" fill="none" stroke="#2A2A2A" stroke-width="4"/>`
          + `<path d="M42 54 L82 98" stroke="#2A2A2A" stroke-width="10" stroke-linecap="round"/>`
          + `<rect x="70" y="82" width="14" height="10" rx="2" fill="${buckled ? '#CFE4CF' : '#ECECEC'}" stroke="#2A2A2A" stroke-width="3"/>`);
    },
    // fegyver és bilincs ugyanabban a kártya-stílusban
    weapon: card(BG_WHITE,
        `<path d="M26 46 H92 V60 H74 L64 76 H50 L44 60 H26 Z" fill="none" stroke="#2A2A2A" stroke-width="4" stroke-linejoin="round"/>`
      + `<rect x="50" y="60" width="14" height="20" fill="none" stroke="#2A2A2A" stroke-width="3"/>`),
    cuffed: card(BG_WHITE,
        `<circle cx="44" cy="80" r="20" fill="none" stroke="#2A2A2A" stroke-width="5"/>`
      + `<circle cx="84" cy="80" r="20" fill="none" stroke="#2A2A2A" stroke-width="5"/>`
      + `<path d="M58 64 Q64 54 70 64" fill="none" stroke="#2A2A2A" stroke-width="5" stroke-linecap="round"/>`),
    // halott-időzítő piros keresztje (külön, CSS színezi)
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
                <div class="admin"></div>
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

        el.style.left = (p.x * sw) + 'px';
        el.style.top  = (p.y * sh) + 'px';
        el.style.transform = `translate(-50%, -100%) scale(${p.scale.toFixed(3)})`;

        const isDeadTimer = p.dead && p.deathRemaining > 0;
        el.classList.toggle('dead', !!isDeadTimer);

        if (isDeadTimer) {
            el.querySelector('.death').style.display = 'flex';
            el.querySelector('.timer').textContent = fmtTime(p.deathRemaining);
        } else {
            el.querySelector('.death').style.display = 'none';

            // admin tag
            const adminEl = el.querySelector('.admin');
            if (p.admin && p.admin.label) {
                const adminHtml = p.admin.label;
                const adminColor = p.admin.color || '#FF0000';
                
                if (el._cache.admin !== adminHtml) {
                    adminEl.textContent = adminHtml;
                    adminEl.style.color = adminColor;
                    el._cache.admin = adminHtml;
                }
                adminEl.style.display = 'block';
            } else {
                adminEl.style.display = 'none';
                el._cache.admin = null;
            }

            // név + ID
            const nameKey = `${p.name || ''}|${p.serverId}`;
            if (el._cache.name !== nameKey) {
                const nameEl = el.querySelector('.name');
                if (p.name) {
                    nameEl.innerHTML = `${p.name} <span class="id">[${p.serverId}]</span>`;
                } else {
                    nameEl.innerHTML = `<span class="id">[${p.serverId}]</span>`;
                }
                el._cache.name = nameKey;
            }

            // frakció / rang sor
            const jobEl = el.querySelector('.job');
            if (p.job && p.job.label) {
                const badge = p.job.badge ? ` <span class="badge">#${p.job.badge}</span>` : '';
                const grade = p.job.grade ? ` <span class="rank">${p.job.grade}</span>` : '';
                const jobHtml = `<span class="job-label">${p.job.label}</span>${badge}${grade}`;
                
                // Cache kulcs tartalmazza a jobName-t is, hogy színváltáskor frissüljön
                const cacheKey = `${jobHtml}|${p.jobName || ''}`;
                
                if (el._cache.job !== cacheKey) {
                    jobEl.innerHTML = jobHtml;
                    
                    // Állítsuk be a munka színét AZUTÁN, hogy létrehoztuk az elemet
                    const jobLabelEl = jobEl.querySelector('.job-label');
                    if (jobLabelEl && p.jobName && jobColors[p.jobName]) {
                        jobLabelEl.style.color = jobColors[p.jobName];
                    } else if (jobLabelEl) {
                        // Ha nincs egyedi szín, fehér legyen (alapértelmezett)
                        jobLabelEl.style.color = '#FFFFFF';
                    }
                    
                    el._cache.job = cacheKey;
                }
                jobEl.style.display = 'block';
            } else {
                jobEl.style.display = 'none';
                el._cache.job = null;
            }

            // ikonok (a név jobb oldalán)
            const icons = [];
            // mic CSAK beszéd közben -> mindig zöld
            if (p.mic) icons.push(`<span class="icon mic talking">${ICONS.mic(true)}</span>`);
            if (p.radio)  icons.push(`<span class="icon">${ICONS.radio}</span>`);
            if (p.phone)  icons.push(`<span class="icon">${ICONS.phone}</span>`);
            if (p.armour) icons.push(`<span class="icon">${ICONS.armour}</span>`);
            if (p.weapon) icons.push(`<span class="icon">${ICONS.weapon}</span>`);
            if (p.cuffed) icons.push(`<span class="icon">${ICONS.cuffed}</span>`);
            // öv csak járműben (fehér = nincs, zöld = becsatolva)
            if (p.seatbeltShow) icons.push(`<span class="icon">${ICONS.seatbelt(p.seatbelt)}</span>`);

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

// ====== JÁRMŰ RENDSZÁMTÁBLÁK (modern, valódi kinézet) ======
function renderVehicles(list, region) {
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
                    <span class="bolt tl"></span>
                    <span class="bolt tr"></span>
                    <span class="bolt bl"></span>
                    <span class="bolt br"></span>
                    <div class="region"></div>
                    <div class="number"></div>
                </div>
            `;
            el._cache = {};
            vehiclesEl.appendChild(el);
            plates[v.netId] = el;
        }

        el.style.left = (v.x * sw) + 'px';
        el.style.top  = (v.y * sh) + 'px';
        el.style.transform = `translate(-50%, -100%) scale(${v.scale.toFixed(3)})`;

        const key = `${region || 'RealCity'}|${v.plate}`;
        if (el._cache.plate !== key) {
            el.querySelector('.region').textContent = region || 'RealCity';
            el.querySelector('.number').textContent = v.plate;
            el._cache.plate = key;
        }
    }

    for (const id in plates) {
        if (!seen[id]) { plates[id].remove(); delete plates[id]; }
    }
}

window.addEventListener('message', (e) => {
    const d = e.data;
    if (d.action === 'visibility') {
        document.body.classList.toggle('overlay-hidden', d.visible === false);
        if (d.visible === false) {
            for (const id in tags) { tags[id].remove(); delete tags[id]; }
            for (const id in plates) { plates[id].remove(); delete plates[id]; }
        }
        return;
    }
    if (d.action === 'setJobColors') {
        jobColors = d.colors || {};
        return;
    }
    if (d.action === 'players') {
        renderPlayers(d.players || []);
    } else if (d.action === 'vehicles') {
        renderVehicles(d.vehicles || [], d.region);
    }
});
