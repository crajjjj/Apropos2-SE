# Apropos2 SE — Smoke Test / Use Cases

A manual in-game checklist to confirm a build works end-to-end after packaging/deploying the mod.
It is not exhaustive — it exercises the main user-facing paths so a broken build is caught fast.

Mark each row: ✅ pass · ⚠️ partial · ❌ fail. Note the game version / load order if something fails.

## What Apropos2 is (context for the tester)

Apropos2 hooks SexLab animation events and narrates them as on-screen text ("descriptions"),
tracks per-orifice **Wear & Tear (W&T)** on the player and (optionally) NPCs, and turns high W&T
into gameplay **effects** (debuff spells, staggers, body morphs) and visual **abuse textures**
(via SlaveTats). Everything is driven from the **Apropos2 MCM**.

Key concepts a tester should keep in mind:
- **State 0–9** per orifice (Vaginal / Anal / Oral). Higher = more worn. State ≥ 4 triggers debuff spells.
- **Abuse** is a separate rape/aggression-only track that drives face/body textures.
- **Narrative voice**: descriptions render in 1st / 2nd / 3rd person (MCM → Message Preferences).

---

## 0. Prerequisites & Install

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 0.1 | Prereqs detected | Open MCM before install → **Install** page | SKSE 1.7.3+, JContainers 3.2.5+, SexLabAroused 2.7, SlaveTats 1.1.1 all show "ok" (SlaveTats optional) |
| 0.2 | Install runs | Click **Install / Update** | No CTD; page repopulates with the 9 config pages (General, Wear And Tear, …, Rebuild/Clean) |
| 0.3 | Version shown | Check page title / Rebuild page | Displays current version string, matches the built version |
| 0.4 | No integrity error | Install page | No "CRITICAL ERROR: File Integrity" banner |

---

## 1. Descriptions (core narration)

Precondition: MCM → Events And Messages → **Show Descriptions** ON. Have a SexLab scene ready
(player + 1 NPC). Try each narrative voice from Message Preferences → **Person**.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 1.1 | Animation start message | Start a SexLab scene with **Animation Start Messages** ON | A description appears in the widget when the animation begins |
| 1.2 | Stage progression | Advance animation stages with **Stage Progression Messages** ON | A new fitting description on each stage advance |
| 1.3 | Animation change | Switch animation mid-scene with **Animation Change Messages** ON | A description fires on the change |
| 1.4 | Orgasm | Let the scene reach orgasm | Orgasm-start description shows; orgasm-end handled without error |
| 1.5 | 1st person voice | Set Person = 1st, run a scene | Text reads "I / my …" |
| 1.6 | 2nd person voice | Set Person = 2nd | Text reads "you / your …" |
| 1.7 | 3rd person voice | Set Person = 3rd | Text reads by name / "she / her …" |
| 1.8 | Descriptions OFF | Turn **Show Descriptions** OFF, run a scene | No description text appears |
| 1.9 | Creature scene | Run a creature animation | Description picks a creature-appropriate partner/phrasing, no error |

---

## 2. Wear & Tear accumulation

Precondition: Wear And Tear → **Enable Wear And Tear** ON. Watch the player row in
**Wear And Tear Actors** page (Vaginal/Anal/Oral State menus reflect current state).

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 2.1 | Vaginal W&T rises | Complete vaginal sex | Vaginal State increases; "Increased" W&T message shown (if **Show WT Changed Messages** ON) |
| 2.2 | Anal W&T rises | Complete anal sex | Anal State increases |
| 2.3 | Oral W&T rises | Complete oral sex | Oral State increases |
| 2.4 | Manual override | Wear And Tear Actors → set **Vaginal State** menu to e.g. 6 | State applies immediately; effects/textures update to match |
| 2.5 | Male PC guard | With a male player character | Vaginal State menu is disabled/greyed (no vaginal W&T on male PC) |
| 2.6 | Test button | Wear And Tear → **Test W&T on Player** | Player jumps to high W&T; effects + textures visibly apply |

---

## 3. W&T degradation over time (healing)

Precondition: Enable W&T. Set **Frequency Wear Tear Degrade** low (e.g. 1 hr) and
**Chance WT Degrade** high (e.g. 100%) to speed the test.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 3.1 | Natural heal | Raise W&T, then wait/sleep past the degrade frequency | State drops; "Reduced" W&T message may show |
| 3.2 | Degrade factor | Raise **Wear Tear Degrade Factor**, repeat | Reduction per tick is larger |
| 3.3 | Full heal → untrack | Let all three orifices reach ~0 | Actor stops being actively tracked (returns to ready state), no errors |

---

## 4. W&T gameplay effects

Precondition: Wear And Tear → **Enable Wear Tear Effects** ON. Drive a state to ≥ 4
(use override or Test button).

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 4.1 | Oral debuffs | Oral state ≥ 4 | Magicka-regen + Speech debuff spells added to actor |
| 4.2 | Vaginal debuffs | Vaginal state ≥ 4 | Stamina/Health regen + movement-speed debuffs added |
| 4.3 | Anal debuffs | Anal state ≥ 4 | Stamina/Health regen + movement-speed debuffs added |
| 4.4 | Hardcore scaling | Toggle **Enable Hardcore Wear Tear Effects** ON, re-apply | Debuff magnitudes are larger (hc key set) |
| 4.5 | Effects OFF cleanup | Turn **Enable Wear Tear Effects** OFF | All Apropos debuff spells are dispelled from the actor |
| 4.6 | Stagger | **Stagger** ON, cause a W&T **increase** | Actor staggers when W&T goes up |
| 4.7 | W&T Morph | **W&T Morph** ON (needs body morphs), change state | Body morphs apply/clear with state; cleared when disabled |
| 4.8 | Auto-masturbate | **Enable Auto-Masturbate** ON, arousal ≥ **Min Arousal**, cause a W&T **reduction** | Actor auto-masturbates; "There's an itch…" message in the correct voice; player controls restored afterward |

---

## 5. Abuse textures (SlaveTats)

Precondition: SlaveTats installed; Wear And Tear → **Enable Skin Textures** ON. Abuse only
rises from **rape/aggressive** scenes; use override with the abuse flags or a rape scene.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 5.1 | After-effects | Raise general abuse (**Enable After Effects** ON) | Body after-effect overlay appears, scaling with state |
| 5.2 | Tears & sobs | **Enable Tears And Sobs** ON, increasing abuse | Face tears/sob overlay appears at the right thresholds |
| 5.3 | Mascara smears | **Enable Mascara Smears** ON, low increasing abuse | Running-mascara overlays appear (with Mascara tint) |
| 5.4 | Cut/scratches | **Enable Cut Scratches** ON, creature rape | Cuts overlay appears (creature-abuse track) |
| 5.5 | Daedric scars | **Enable Daedric Scars** ON, Daedra/Dremora rape | Scar overlay appears (daedric-abuse track) |
| 5.6 | Tint | Change **Tats Color Tint** | New overlays use the chosen tint |
| 5.7 | Cleanup | Turn **Enable Skin Textures** OFF / heal fully | All abuse overlays are removed and re-synced |
| 5.8 | No SlaveTats | Uninstall SlaveTats | Texture options greyed; mod still runs, no CTD |

---

## 6. Consumables

Precondition: Wear And Tear → related consumable toggles set as noted.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 6.1 | Healing item | Drink a healing potion / eat a healing ingredient while worn | W&T is reduced by the item |
| 6.2 | Arousal from food | **Consumables Increase Arousal** ON, eat/drink | Arousal rises within Min/Max bounds |

---

## 7. Message widget

Precondition: Message Widget Settings page.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 7.1 | Widget test | **Widget Test Mode** ON, press **Widget Test HotKey** | A test message renders in the widget |
| 7.2 | Position | Change H/V anchor + offset | Widget moves accordingly |
| 7.3 | Appearance | Change font size, spacing, width, seconds-to-display | Text renders with the new style and dwell time |
| 7.4 | Player font | Change **Player Font Size** | Player-directed messages use that size |

---

## 8. Periodic player descriptions

Precondition: Events And Messages → **Periodic PC Messages Mode**.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 8.1 | Hotkey mode | Mode = "Use hotkey", press **Key to Generate Player Messages** | A player description is generated on demand |
| 8.2 | Timed mode | Mode = "Timed msg" | Player descriptions appear periodically on their own |
| 8.3 | Disabled | Mode = "Disabled" | No periodic player messages; hotkey does nothing |

---

## 9. Special messages

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 9.1 | Virginity lost | **Show Virginity Lost Messages** ON, first vaginal/anal/oral for an actor with 0 skill | Virginity-loss message fires once |
| 9.2 | Huge load | **Min Arousal for huge load** > 0, aggressor arousal above it, orgasm | HUGELOAD-flavored orgasm description |
| 9.3 | Large load | **Min Arousal for Large load** > 0, aggressor arousal above it | LARGELOAD-flavored description |
| 9.4 | Load msgs off | Set both arousal thresholds to 0 | No huge/large load variants |

---

## 10. NPC tracking

Precondition: Wear And Tear → **Enable NPC Wear And Tear** ON.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 10.1 | NPC tracked | Run an NPC-only scene | NPC appears in Wear And Tear Actors → NPC list with W&T values |
| 10.2 | NPC effects | Drive an NPC to state ≥ 4 | Debuffs/textures apply to that NPC |
| 10.3 | Clear NPCs | Click **Clear NPC Trackings** | NPC list empties; no dangling effects |
| 10.4 | NPC W&T off | Turn **Enable NPC Wear And Tear** OFF | NPCs no longer accumulate W&T |

---

## 11. Misc effects (aggressive scenes)

Precondition: Misc Effects page.

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 11.1 | Rape anim switch | **Rape Animation Switch Chance** > 0, run a rape scene | Aggressor sometimes switches animation |
| 11.2 | Stage go-back | **Go Back Aggressor Factor** > 0 with high aggressor arousal | Aggressor backs the animation up a stage, capped by **Max Go Backs** |

---

## 12. Maintenance / lifecycle

| # | Use case | Steps | Expected |
|---|----------|-------|----------|
| 12.1 | Enable/Disable | Rebuild/Clean → **Disable System**, run a scene, then **Enable System** | Disabled = no descriptions/hooks; re-enable restores them |
| 12.2 | Refresh Database | Message Preferences → **Refresh Database** | Text/control files reload; no error; new descriptions still fire |
| 12.3 | Anim patchups | Message Preferences → **Run Patchups** | Completes without error |
| 12.4 | Clean System | Rebuild/Clean → **Clean System** | Quests reset & re-setup; tracking cleared; mod still works after |
| 12.5 | Clean JContainers | **Clean JContainers** | Apropos JContainers data released; no CTD |
| 12.6 | Export/Import | **Export Settings** then **Import Settings** | Settings round-trip correctly |
| 12.7 | Restore defaults | **Restore Default Settings** | All MCM options return to defaults |
| 12.8 | Save/reload | Save mid-scene, reload | GameLoaded re-registers events; scene state sane; no orphaned scripts |

---

## Quick regression subset (5-minute smoke)

If short on time, run just these — they touch install, narration, W&T, effects, textures, cleanup:

1. **0.2** Install completes → 9 pages appear
2. **1.1 / 1.4** Description on animation start + orgasm
3. **2.1** Vaginal W&T rises after sex
4. **4.2** Vaginal state ≥ 4 adds debuff spells; **4.5** disabling effects dispels them
5. **5.1** Abuse texture appears (if SlaveTats) and **5.7** clears on heal
6. **12.4** Clean System, then confirm a scene still narrates
