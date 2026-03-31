# Disco Science Lite

_The Disco Must Grow. Into Space, with a performance twist._

Disco Science Lite is a variant of the beloved [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod by Daniel Brauer, featuring algorithmic UPS optimizations and additional features including Space Age mods support.

**Multiplayer support is still experimental.** It may cause desync errors when joining a game, or could increase UPS load. Please avoid using it in large multiplayer sessions or in important saves.

This mod is not officially affiliated with the original mod author. Please **DO NOT** contact the original mod author with questions or issues about this mod.

## What It Does

Your science labs glow with the color of the science packs they're consuming, shifting and pulsing dynamically, disco-style. One glance at your factory floor tells you exactly what's being researched.

Demo Video: https://www.youtube.com/watch?v=gYLMDnKurTc

## Features

- **Performance**: Heavily optimized to keep UPS (Updates Per Second) impact minimal, even with large numbers of labs in mega-bases. Additional performance tuning options are available in mod settings. ([Technical details](docs/ups-optimization.md))

- **Built-in Mod Support**: Over 30 mods are natively supported with properly fitted color animations, including Space Age Biolabs, Planet mods (e.g. Maraxis, Cerys), Krastorio 2, Exotic Space Industries, and many more. See the full list below.

- **Automatic Colorization for Unsupported Mods**: Any labs added by unsupported mods are automatically colorized too using a generic glow effect. This can be toggled in mod settings.

- **Color Customization**: Adjust color saturation (how vivid) and brightness through mod settings to get the look that suits your taste.

- **New Color Patterns**: In addition to the color patterns from the original mod, Disco Science Lite includes new ones that offer different visual rhythms and blending styles.

- **Mod API Compatibility**: Compatible with the original Disco Science mod's API, so most mods that support Disco Science will work with this one too. Some mods may not recognize it as a compatible replacement if they specifically check for the original mod by name.

If you are a modder, see the [full API reference](docs/api.md) for quick start examples and prototype/runtime stage APIs.

## Supported Mods

These mods are supported out of the box.

- [5Dim's mod - New Automatization](https://mods.factorio.com/mod/5dim_automation) by McGuten
- [AAI Industry](https://mods.factorio.com/mod/aai-industry) by Earendel
- [Age of Production](https://mods.factorio.com/mod/Age-of-Production) by AndreusAxolotl
- [Big Lab](https://mods.factorio.com/mod/BigLabFork) by DellAquila and \_CodeGreen
- [Bob's Tech](https://mods.factorio.com/mod/bobtech) by Bobingabout
- [Exotic Space Industries](https://mods.factorio.com/mod/exotic-space-industries) by eliont and PreLeyZero
- [Exotic Space Industries: Remembrance](https://mods.factorio.com/mod/exotic-space-industries-remembrance) by aRighteousGod
- [Factorio and Conquer: Tiberian Dawn](https://mods.factorio.com/mod/Factorio-Tiberium) by James-Fire
- [Factorio HD Age](https://mods.factorio.com/mod/factorio_hd_age_modpack) by Ingo_Igel
- [Krastorio 2](https://mods.factorio.com/mod/Krastorio2) by raiguard
- [Krastorio 2 Spaced Out](https://mods.factorio.com/mod/Krastorio2-spaced-out) by Polka_37
- [Lab-O-Matic](https://mods.factorio.com/mod/LabOMatic) by Stargateur
- [Omnimatter](https://mods.factorio.com/user/OmnissiahZelos) mods by OmnissiahZelos
- [One More Tier](https://mods.factorio.com/mod/one-more-tier) by Jakzie
- [Pyanodons](https://mods.factorio.com/user/pyanodon) by pyanodon
- [Quality Glassware](https://mods.factorio.com/mod/quality_glassware) by Hornwitser
- [Space Exploration](https://mods.factorio.com/mod/space-exploration) by Earendel (Space science lab is not colorized though)

Supported Space-Age Planet Mods:

- [Cerys](https://mods.factorio.com/mod/Cerys-Moon-of-Fulgora) by thesixthroc
- [🌐Corrundum](https://mods.factorio.com/mod/corrundum) by Zach Kolansky
- [🌐Dea Dia System](https://mods.factorio.com/mod/dea-dia-system) by Frontrider
- [🌐Igrys](https://mods.factorio.com/mod/Igrys) by Egorex W
- [Lignumis](https://mods.factorio.com/mod/lignumis) by cackling fiend
- [🌐Metal and Stars](https://mods.factorio.com/mod/metal-and-stars) by Alex Boucher
- [Moshine](https://mods.factorio.com/mod/Moshine) by snouz
- [Muluna, Moon of Nauvis](https://mods.factorio.com/mod/planet-muluna) by Nicholas Gower
- [Planet Castra](https://mods.factorio.com/mod/castra) by Bartz24
- [Planet Maraxsis](https://mods.factorio.com/mod/maraxsis) by notnotmelon
- [🌐 Planet Paracelsin](https://mods.factorio.com/mod/Paracelsin) by Andreus
- [🌐Planet Rubia](https://mods.factorio.com/mod/rubia) by Loup&Snoop
- [🌐Secretas&Frozeta](https://mods.factorio.com/mod/secretas) by Zach Kolansky
- [SLP - Dyson Sphere Reworked](https://mods.factorio.com/mod/slp-dyson-sphere-reworked) by SLywnow
- [Tenebris](https://mods.factorio.com/mod/tenebris) by Big_J
- [Tenebris Prime](https://mods.factorio.com/mod/tenebris-prime) by MeteorSwarm

In addition to the mods listed above, mods that support the original Disco Science mod may still work, unless it specifically checks for the original mod by name and doesn't recognize Disco Science Lite as a compatible mod.

If you'd like support for a specific mod, feel free to reach out via the [Discussion](https://mods.factorio.com/mod/disco-science-lite/discussion) on the Mod Portal. No promises, but I'll do my best!

## Compatibility

It is safe to add or remove this mod in mid-game.

If you are using the original Disco Science mod, you have to disable it to use Disco Science Lite.

---

## Development

For development of this mod, see [docs/development.md](docs/development.md).

---

## Acknowledgements

Thanks to these amazing creators for their work:

- **[Daniel Brauer](https://mods.factorio.com/user/danielbrauer)**: for the original [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod that started it all.
- **[BiusArt](https://mods.factorio.com/user/BiusArt)**: for the graphics from [BiusArt Lab graphics](https://mods.factorio.com/mod/laborat).
- **[raiguard](https://mods.factorio.com/user/raiguard)**: for the graphics from [Krastorio 2](https://mods.factorio.com/mod/Krastorio2).
- **[Hurricane](https://mods.factorio.com/user/Hurricane046)**: for the graphics from [Factorio Buildings](https://shorturl.at/AFcDm).
- **[Zach Kolansky](https://mods.factorio.com/user/AnotherZach)**: for the graphics from [🌐Corrundum](https://mods.factorio.com/mod/corrundum).

## License

This mod includes code originally derived from the [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod created by [Daniel Brauer](https://mods.factorio.com/user/danielbrauer), which is licensed under the MIT License.

The source code is released under the [MIT License](LICENSE).

Some image assets are derived from third-party works and are **NOT** covered by the MIT License:

| Files                                                                | Source                                                        | Author                                                      | License                     |
| -------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------- |
| [graphics/factorio/](graphics/factorio/)                             | Factorio                                                      | Wube Software Ltd.                                          | © Wube Software Ltd. (EULA) |
| [graphics/laborat/](graphics/laborat/)                               | [BiusArt Lab graphics](https://mods.factorio.com/mod/laborat) | [BiusArt](https://mods.factorio.com/user/BiusArt)           | GNU LGPL v3.0               |
| [graphics/Krastorio2/](graphics/Krastorio2/)                         | [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)       | [raiguard](https://mods.factorio.com/user/raiguard)         | GNU LGPL v3.0               |
| [graphics/hurricane/](graphics/hurricane/)                           | [Factorio Buildings](https://shorturl.at/AFcDm)               | [Hurricane](https://mods.factorio.com/user/Hurricane046)    | CC BY 4.0                   |
| [graphics/corrundum/](graphics/corrundum/)                           | [🌐Corrundum](https://mods.factorio.com/mod/corrundum)        | [Zach Kolansky](https://mods.factorio.com/user/AnotherZach) | MIT                         |
| [tasks/graphics/source/hurricane/](tasks/graphics/source/hurricane/) | [Factorio Buildings](https://shorturl.at/AFcDm)               | [Hurricane](https://mods.factorio.com/user/Hurricane046)    | CC BY                       |

See the `NOTICE.txt` and `LICENSE` files in each directory for details.
