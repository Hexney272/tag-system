// RealRPG - járműtípusonkénti rendszámtábla NUI modul
// Az app.js után töltődik be, és kibővíti a meglévő renderVehicles függvényt.

let plateTypeMap = Object.create(null);
let plateTypeLabels = {
    civil: 'RealCity',
    police: 'RENDŐRSÉG',
    ambulance: 'MENTŐSZOLGÁLAT',
    boat: 'VÍZI JÁRMŰ',
    aircraft: 'LÉGI JÁRMŰ',
    electric: 'E-REALCITY',
};

const validPlateTypes = new Set([
    'civil', 'police', 'ambulance', 'boat', 'aircraft', 'electric'
]);

function normalizePlateType(value) {
    const normalized = String(value || '').toLowerCase();
    return validPlateTypes.has(normalized) ? normalized : 'civil';
}

function plateAsset(type) {
    return `plates/${type}.svg`;
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'plateTypes') {
        plateTypeMap = data.types || Object.create(null);
        return;
    }

    if (data.action === 'plateTypeConfig') {
        plateTypeLabels = { ...plateTypeLabels, ...(data.labels || {}) };
    }
});

// Felülírjuk az eredeti renderelőt, miközben megtartjuk ugyanazt az adatfolyamot.
renderVehicles = function renderTypedVehicles(list, region) {
    const seen = {};
    const sw = window.innerWidth;
    const sh = window.innerHeight;

    for (const vehicle of list) {
        if (!vehicle.plate) continue;

        const id = String(vehicle.netId);
        const type = normalizePlateType(plateTypeMap[id]);
        const label = type === 'civil'
            ? (region || plateTypeLabels.civil || 'RealCity')
            : (plateTypeLabels[type] || type);

        seen[id] = true;
        let element = plates[id];

        if (!element) {
            element = document.createElement('div');
            element.className = 'plate';
            element.innerHTML = `
                <div class="board">
                    <img class="plate-art" alt="" draggable="false">
                    <span class="bolt tl"></span>
                    <span class="bolt tr"></span>
                    <span class="bolt bl"></span>
                    <span class="bolt br"></span>
                    <div class="region"></div>
                    <div class="number"></div>
                </div>
            `;
            element._cache = {};
            vehiclesEl.appendChild(element);
            plates[id] = element;
        }

        element.style.left = `${vehicle.x * sw}px`;
        element.style.top = `${vehicle.y * sh}px`;
        element.style.transform = `translate(-50%, -100%) scale(${vehicle.scale.toFixed(3)})`;

        if (element._cache.type !== type) {
            element.className = `plate plate--${type}`;
            element.querySelector('.plate-art').src = plateAsset(type);
            element._cache.type = type;
            element._cache.plate = null;
        }

        const key = `${type}|${label}|${vehicle.plate}`;
        if (element._cache.plate !== key) {
            element.querySelector('.region').textContent = label;
            element.querySelector('.number').textContent = vehicle.plate;
            element._cache.plate = key;
        }
    }

    for (const id in plates) {
        if (!seen[id]) {
            plates[id].remove();
            delete plates[id];
        }
    }
};
