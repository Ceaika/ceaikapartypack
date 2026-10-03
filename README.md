# Ceaika's Partypack

alright so this is my party pack for titanfall 2 (northstar / ion). it's a bunch of custom modes + a party lobby where u vote on what we play next, all tied together with transitions, a custom loading screen and some lobby stuff.

modes:
- **juggernaut** - one guy is a massive titan, everyone else hunts him
- **hot potato** - someone's holding a ticking potato, melee someone to pass it before it blows
- **prop hunt** - props hide as objects, hunters gotta find them
- **body swap** - every few seconds u swap bodies with a random enemy
- plus the stock ones in rotation (ffa, the hidden, one in the chamber, gun game, infection)

this repo is the **client side only**. the server logic (round flow, scoring, spawning, all that) isn't in here, it runs on my server. u need this to join and see everything properly.

---

## installing

1. close the game
2. if u had an older version, **delete** your old `mods/ceaikapartypack` folder completely. don't unzip over it, old files stick around and break stuff
3. drop the `ceaikapartypack` folder from this repo into your `R2Northstar/mods` folder (or your profile's `mods` folder if u use one)
4. it should look like `R2Northstar/mods/ceaikapartypack/mod.json`
5. launch and join the server

the mod is `RequiredOnClient`, so your version has to match the server's or it won't let u in. if it says version mismatch just pull the latest.

### separate profile (optional)

if u don't wanna mess with your normal mods, make a profile. make a folder next to `R2Northstar` (call it whatever, like `notamodprofile`), give it a `mods` folder, copy `Northstar.Client`, `Northstar.Custom` and `Northstar.CustomServers` into it from `R2Northstar/mods`, copy `R2Northstar/plugins` over too if u have it, then put this mod in there.

launch with:
```
NorthstarLauncher.exe -profile=notamodprofile
```
or through steam/ea launch options: `-northstar -profile=woof`

### prop hunt keybinds

settings > mod settings > prop hunt. u can rebind reroll, decoy, rotation lock, freeze and taunt for keyboard and controller there.

---

## how it works

quick rundown of how each thing is put together, in case u wanna poke around. everything lives in `ceaikapartypack/mod/scripts/vscripts/gamemodes/`. naming is the usual respawn stuff: `cl_` client, `sh_` shared (client + server), `ui_` menu.

### how the server talks to the client

the server mostly drives things through three channels:
- **networked vars** registered in the `sh_` files (`RegisterNetworkedVariable`). stuff like `juggPhase`, `hpCarrier`, `phPhase`, `plVotes0`... the client just reads them every frame and draws the hud from them
- **remote functions** (`Remote_RegisterFunction` in the `sh_` files) for one-off events like hit feedback or a hack starting
- **string commands** for anything with text in it, since remote functions can't send strings. `cl_party_ui.nut` listens for `party_banner`, `party_feed` and `party_popup`, `cl_party_intro.nut` for `party_next` and `cl_party_statue.nut` for `party_leader`

### the party ui (banners, feed, popups)

`cl_party_ui.nut` is the shared hud kit every mode uses: the big banner across the middle, the kill-feed style lines and the small popups. the server sends `party_banner <args>` etc and `PartyUI_BannerCommand` / `PartyUI_FeedCommand` / `PartyUI_PopupCommand` draw them. `PartyUI_BannerShowing()` is used by the intro so it doesn't cover a mode's title banner.

### intro, transitions and the loading screen

`cl_party_intro.nut` is the big one.
- **match intro** (`PartyIntro_Run` -> `PartyIntro_Sequence`): the orange card with the spinning re-45 in the corner, the title flies out, the gun comes to the middle, "Ceaika's" slides out of the barrel, "Partypack" slams in, then the gun fires (actual re-45 shot sound) and the screen splits open along the bullet line (`PartyCard_Reveal`)
- **lobby arrival** (`PartyTransition_Arrive`) is the same thing faster but opens with a circle from the muzzle instead (`PartyCard_IrisReveal`)
- **leaving a map** (`PartyTransition_Show`): the curtain drops (end of match) or sweeps in (lobby launching), then the card settles into the exact loading screen layout so the actual loading screen takes over without a jump. the server sends `party_next <mode> <map>` right before so the card already shows where we're going
- the animations run on their own clock (`PartyIntro_Clock`) that never jumps more than 1/30 s a frame, and `PartyIntro_WaitSmooth` holds the card until the game stops stuttering after loading in. that's what keeps it from skipping on a real server
- everything is drawn with `ui/basic_image.rpak` ruis on hud topologies and placed by hand every frame (`PartyIntro_Place`, `PartyIntro_PlaceTurned` for rotation)

the **loading screen** itself is vgui, not script: `mod/resource/ui/basemodui/loadingprogress.res` lays it out (orange card, title image, map + mode labels, tip), `mod/resource/basemodui_scheme.res` has the fonts, the spinning re-45 is `mod/materials/vgui/spinner.vtf` replacing the stock spinner (36 frames), and the tips are `TIP_001...` in `mod/resource/ceaikapartypack_localisation_english.txt`.

two engine limits to know about:
- vgui text caps at about 128px tall no matter what u ask for, so the map/mode names are sized to stay under that up to 1600p, and the intro card copies the capped size (`PartyCorner_MapH`) so nothing jumps
- the client only gets **64 rui topologies** total, so the card frees its planes after the reveal (`PartyCard_Destroy`) and everything else that makes planes retries instead of erroring when it's full

### images

all the custom images (intro pieces, map/mode names in the intro font, digits, credits rows, hologram pieces) are packed into one atlas, `paks/ceaika_ui.rpak`, loaded through `paks/rpak.json`. one atlas on purpose, the game only allows 20 ui atlases loaded at once. `cl_party_names.nut` maps a map/playlist name to its name image (`PartyName_Image`, `PartyName_Aspect`).

### party lobby

`cl_party_lobby.nut` is the lobby hud: the round card top right (votes, countdown, ready count), the ready list and the hold-to-ready bar. the vote counts come in as `plVotes0..8`, your own vote as `plVote`.

it also plays the timeshift elevator bossa nova the whole time you're in the lobby (`PartyLobby_Music`, loops off `GetSoundDuration`).

the holograms:
- **vote screens** (`cl_party_votes.nut`): every mode's name floats over its screen, facing u, orange or green if u voted for it. walk up and one shared card unfolds over the screen: projector beam, corner brackets snapping in, scanline glass, a vote counter that counts up and a description that types itself out. one card for all nine screens so it doesn't eat the 64 topologies. world text is `ui/cockpit_console_text_top_left.rpak` on a world plane, which works fine as long as the plane is 16:9
- **credits board** (`cl_party_credits.nut`): floating "CREDITS" near the middle of coliseum, unfolds into a leaderboard when u get close
- **session titan** (`cl_party_statue.nut`): the server keeps track of who won the most this session and puts their titan in the middle of the arena. the client just floats "SESSION TITAN", the name and the win count over it, from `party_leader <wins> <name>`

world planes only render from one side and draw their image from the top-left corner going right and down, so every quad is built facing the viewer (`VB_Quad`, `Credits_Quad`, `ST_Quad`).

heads up: `kv.modelscale` doesn't scale animated models properly in this engine (the upper body stays small), that's why the session titan is life size.

### juggernaut

- `sh_gamemode_jugg.nut` registers all the networked state (phase, round, the juggernaut's hull/shield split into two ints each because of the netvar range, aegis tier, your boost...) and the remote functions
- `cl_gamemode_jugg.nut` is the hud: the juggernaut's health bar with your damage flying off it (`JuggDamageFlyout`), the round card with your promotion progress and the boost you're holding (`JuggBoostLine`), aegis tiers, the doomed outline
- `cl_jugg_hack.nut` is the terminal hacking minigame: the server sends a 5-step direction code (`JuggHackBegin`), u punch it in with wasd or arrow keys (`RegisterButtonPressedCallback`), every press goes back to the server as `jugg_hack_input` and the server checks it
- `sh_jugg_input.gnut` is the sabotage battery effect, it flips your look inversion for a bit and always puts it back
- `party_weapon_callbacks.nut` exists because the game looks up weapon callbacks even in the main menu, where the jugg scripts aren't loaded. so this file loads everywhere and the modes plug their handlers into it (`Party_SetWeaponHandler`) when they load

### hot potato

- `sh_gamemode_hotpotato.nut`: who has it (`hpCarrier`), when it blows (`hpFuseEnd`), round number, pilots alive, supply drops
- `cl_gamemode_hotpotato.nut`: the fuse timer, the carrier marker, drop markers and pass/explode feedback (`HP_Feedback`)
- passing is a melee hit, the server cancels the melee damage and moves the potato instead. there's a 2 second no-tag-back rule (`hp_tagback_seconds`)

### prop hunt

- `sh_prophunt.nut`: the prop side. each prop model has its own health, hull and clearance (`PH_ModelHealth`, `PH_ModelHull`...) so u actually fit where the model fits
- `sh_ph_maps.nut`: which props each supported map uses, and the composite props built from the map's own placements
- `sh_ph_arena.nut`: the play area. some maps get a polygon boundary, some get walls (`PH_ArenaMap`, `PH_WallMap`, `PH_ArenaNearEdge`), shared so the client can draw it and warn u before the server does
- `cl_ph_arena.nut`: draws the red boundary walls as world planes
- `cl_prophunt.nut`: the hud (disguise panel, health, taunt meter, reroll/decoy counts), the hunter waiting screen and the "missed, 10 seconds off" toast
- `cl_ph_announcements.nut`: the round announcements and the whistle hints that point hunters at a prop
- `sh_ph_controls.nut` + `ui_ph_settings.nut`: the rebindable keys, saved as convars (`ph_bind_*`) through mod settings
- hunters stuck waiting while the props hide get a subway surfers clip lol. it's `mod/media/ceaika_ph_wait.bik` played with `playvideo_nointerrupt`. the game's video panel always draws from the top-left and ignores alpha, so the clip is 2:1 with the text baked in and the countdown sits under it

### body swap

- `sh_gamemode_bodyswap.nut`: `bsNextSwap`, when the next swap happens
- `cl_gamemode_bodyswap.nut`: the 3, 2, 1 countdown in the intro font before every swap

### tuning

most numbers are playlist vars in `keyvalues/playlists_v2.txt`, so they can be changed without touching code: fuse times and tag-backs for hot potato (`hp_*`), hide/hunt time and the miss penalty for prop hunt (`ph_hide_seconds`, `ph_hunt_seconds`, `ph_miss_penalty`), promotion damage for juggernaut (`jugg_veteran_share`, `jugg_vanguard_share`), swap timing for body swap (`bs_window`, `bs_pit_window`, `bs_cross_chance`).

---

## credits

made by me, **Ceaika**.

huge thanks to the playtesters: Patrick_RR, fedamark, drachenfruchl, KrwawyMietek, furrypawsmeller, KNOS and Nidorine.
