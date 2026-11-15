# Toon Partner item (Godot Toontown-like project)
## Request
Toon partner item using existing partner system (like Doodle): follows player Tails-style, uses random owned gag on random cog in battle, 7.5% pass-and-buff, 7.5% passive heal out of battle when hurt, random DNA unless set on character.
## User choices
Only via starting character setting; random existing stat buff; heal = % of max laff; partner not targetable.
## Implemented (2026-06)
- objects/toon_partner/toon_partner.gd/.tscn (ToonPartner actor, trail follow, passive heal 10% max laff)
- objects/toon_partner/toon_partner_action.gd (gag use / 7.5% buff: +20% damage/defense/evasiveness/luck, 2 rounds)
- objects/items/custom/toon_partner/toon_partner_script.gd + objects/items/resources/passive/toon_partner.tres
- PlayerCharacter.partner_dna export; gag_throw.gd keeps ToonPartner as user
## Backlog
- Partner name/nameplate, Lure/Trap/Toon-Up support, editor playtest
