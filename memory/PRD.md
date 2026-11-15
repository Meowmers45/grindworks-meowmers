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
## Iteration 2 (2026-06)
- Partner cheers on cog defeat (BattleService.s_cog_died) and gag unlocks (gags_unlocked total increase)
- Partner can use Lure & Trap (trap_fall/trap_toss keep ToonPartner user; lure_fish dollar flies to user); skips already lured/trapped cogs
## Iteration 3 (2026-06)
- Nameplate (Label3D above head), random Toon name or PlayerCharacter.partner_name; saved in item arbitrary_data
- Idle emotes after 4s standing still: wave, applause laugh, shrug, happy/victory dance
## Iteration 4 (2026-06)
- PlayerCharacter.partner_accessories (ItemAccessory array) placed on partner toon; saved as paths
- Partner says a random tip/joke 2.5s after Util.s_floor_started
## Iteration 5 (2026-06)
- PlayerCharacter.partner_shoes (ItemShoe) applied to partner; saved as path
## Iteration 6 (2026-06)
- Item.unique export; ItemService.flag_check discards unique items the player owns or that are already in play; partner script refuses to spawn a 2nd ToonPartner
## Backlog
- Partner name/nameplate, Lure/Trap/Toon-Up support, editor playtest
