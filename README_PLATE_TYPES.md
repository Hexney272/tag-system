# RealRPG járműtípusonkénti rendszámtáblák

## Beépített típusok

- `civil` – fehér RealCity civil tábla
- `police` – kék rendőrségi tábla
- `ambulance` – piros/türkiz mentőszolgálati tábla
- `boat` – tengerkék hajós tábla
- `aircraft` – kék légi jármű tábla, helikopterre és repülőre
- `electric` – zöld/türkiz elektromos tábla

## Telepítés

A ZIP tartalmát másold a meglévő `tag-system` resource gyökérmappájába, és engedélyezd a fájlok felülírását. A csomag csak két meglévő fájlt ír felül:

- `fxmanifest.lua`
- `html/index.html`

A többi fájl új.

Ezután:

```text
restart tag-system
```

## Addon járművek

A `plate_config.lua` fájlban add hozzá a modellneveket a megfelelő listához:

```lua
Models = {
    police = {
        'police',
        'sajat_rendor_auto',
    },
    ambulance = {
        'ambulance',
        'sajat_mento_auto',
    },
    electric = {
        'voltic',
        'sajat_elektromos_auto',
    },
}
```

A hajó és a repülő/helikopter automatikusan felismerésre kerül a GTA járműosztály alapján.

## Külső scriptből felülbírálás

```lua
exports['tag-system']:SetVehiclePlateType(vehicle, 'police', true)
```

Lekérdezés:

```lua
local plateType = exports['tag-system']:GetVehiclePlateType(vehicle)
```

Statebag közvetlenül:

```lua
Entity(vehicle).state:set('plateType', 'ambulance', true)
```

## Tesztparancs

Ülj be egy járműbe:

```text
/tagplatetype police
/tagplatetype ambulance
/tagplatetype boat
/tagplatetype aircraft
/tagplatetype electric
/tagplatetype civil
/tagplatetype clear
```

A `clear` visszaállítja az automatikus felismerést.
