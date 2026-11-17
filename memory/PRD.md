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
## Iteration 7 (2026-06)
- FIX: partner never spawned (duplicate guard saw old partner pending deletion during reset_stats); guard now checks live sibling item-script nodes
- Partner dormant (hidden, no cheers/heals/chat/emotes) until player first has control; floor chat waits for intro to end
## Iteration 8 (2026-06)
- Partner entrance: teleport hole pop-in (Toon.teleport_in) + greeting + wave on first activation
## Iteration 9 (2026-06)
- Removed doodle reappear sfx from entrance
- Settings > Gameplay "Partner Dialogue" toggle (SettingsFile.partner_dialogue); all partner speech routed via ToonPartner.speak()
## Iteration 10 (2026-06)
- Follow spacing 1.6 -> 3.0 (history 120)
- Goodbye: wave + line + Toon.teleport_out on player.s_dying (lose) and in penthouse win_game after cage opens (win); partner then stays departed
## Iteration 11 (2026-06)
- Removed win goodbye from penthouse_boss.gd (file restored to original); goodbye now only on loss
## Iteration 12 (2026-06)
- Settings > Gameplay "Partner Distance" slider (1.0-6.0, default 3.0) -> SettingsFile.partner_follow_distance, read live by ToonPartner.follow_spacing
## Iteration 13 (2026-06)
- Multiple partners: item no longer unique, spawn guard removed; each ToonPartner trails the previous one (leader getter); only the lead partner chats/cheers aloud; 2nd+ partners ignore character partner_dna/name/accessories/shoes (always random)
## Iteration 14 (2026-06)
- PlayerCharacter.max_toon_partners (3) + ignore_partner_cap; enforced in item script + ItemService.flag_check
- Partners hidden in ElevatorScene (floor select)
- Air anims: jump-zhang (airborne idle) / zhang (airborne moving) via ground raycast
- Hidden seed "poopcity": fullscreen brown-tone shader (seed_poopcity.gd/.tres)
- Long idle: 60s roam within 6u, 180s bored anim + lines, 300s teleport away; sarcastic quip on return
- Floor clear team dance: Globals.s_elevator_entered(elevator); partners line up beside player in elevator, synced happy-dance
- Miss reactions: BattleManager.s_battle_text_shown; partner shrug/cringe + line on MISSED
## Iteration 15 (2026-06)
- poopcity shader: hue-mapped browns (HSV), not just luminance
- Idle games (roam phase, partners paired 1+2, 3+4): tag (chase/flee, swap on catch) and pie toss (cream pie model, splat, cringe); abort when player moves/battle
- PlayerCharacter.partner_accuracy multiplier applied in BattleManager.roll_for_accuracy for ToonPartner users
## Iteration 16 (2026-06)
- PlayerCharacter.partner_items (Array[Item]): stats_add/stats_multiply layered onto a copy of player battle stats for partner gags only (no item scripts, no visuals, money/hp ignored)
## Iteration 17 (2026-06)
- Per-partner items: PlayerCharacter.partner_items is now Array[PartnerItemList] (objects/toon_partner/partner_item_list.gd), indexed by ToonPartner.get_line_index()
## Iteration 18 (2026-06)
- ItemScript: partner_owner, supports_partner_owner(), get_owner_multipliers(), add_owner_stat(); converted bee/dragon/dragonfly/butterfly wings, motorcycle boots, narrow glasses, cowboy hat, silly gauge
- ToonPartner.setup_items() runs supported item scripts with partner_owner; stat_multipliers + stat_offsets merged into partner battle stats
## Iteration 19 (2026-06)
- Golden CPUParticles3D sparkle on partners with items
- Partner gag track boosts: ToonPartner.get_track_effectiveness() (items gag_boost:Track + script offsets) applied in BattleManager.get_damage for ToonPartner users
- Converted Moe Zart Thorns (partner: flat dmg boost only via flat_damage_bonuses) and Clara trap boost; Philosophers Stone skipped (no stat effect)
## Iteration 20 (2026-06)
- Setting "Partner Item Pickup" (settings.partner_item_pickup, default off): partners grab nearby passive non-evergreen WorldItems (group world_items, WorldItem.collect_for_partner); carried items saved in source item arbitrary_data.carried
- Turns per round: PartnerItemList.turns (0=random 1-3 rolled once, stored in arbitrary_data.turns); action loops take_turn()
- Witch Hat / Bubbles squirt boost partner-capable via ToonPartner.s_gag_started
- Pause menu Partners page (name, turns, items coloured by qualitoon w/ hover)
- Sparkle colour by best item qualitoon (QUALITOON_COLORS)
## Iteration 21 (2026-06)
- Pickup bubble over partner (item icon Sprite3D or spinning mini model, ~3s)
- Pause Partners page: "Give" row (OptionButton of your passive items -> Item.remove_item + partner.add_carried_item)
- Partners wear picked-up / given hats, glasses, backpacks (ItemAccessory.place_accessory on partner toon; restored on reload)
## Iteration 22 (2026-06)
- Partners pick up / get given shoes (ItemShoe.place_shoes), old carried pair swapped out via remove_carried_item
- Gift reaction: happy dance + "Thanks, <character name>!" when handed an item from pause menu
## Backlog
- Partner name/nameplate, Lure/Trap/Toon-Up support, editor playtest
