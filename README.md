# toki pona, sona pona

*"simple speech, good knowledge"*

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that uses
[Toki Pona](https://tokipona.org/) — a constructed language with only ~130
words — as a complexity linter for AI agent plans.

## The problem

AI coding agents have a tendency to overcomplicate things. They'll propose a
13-section implementation plan with custom abstractions, multiple new classes,
and speculative architecture — when the actual task needs three files changed.
By the time a human reads through the wall of text and spots the overengineering,
the agent may have already started building it.

## The concept

This skill catches overcomplicated plans *before* implementation begins by
running them through lossy semantic compression. If a plan can survive
round-trip translation through a 130-word language and back, its core is clear.
If it can't, the agent is probably overcomplicating things.

The skill works in four steps:

1. The agent produces a plan, architecture, or implementation proposal
2. Claude translates it into Toki Pona, compressing it down to semantic
   primitives
3. A **blind** agent (with zero context about the original) translates the Toki
   Pona back into English
4. Compare the original and reconstruction to see what survived, what
   vanished, and what mutated

This is essentially the "explain it to a five-year-old" test, but mechanized
and repeatable. The forced compression strips away jargon, unnecessary
abstraction, and overcomplicated language, leaving only the core intent.

## What the results tell you

- **Survived** — the essential parts of the plan. Clear, simple,
  well-understood. This is what actually matters.
- **Vanished** — either unnecessary complexity the agent added (good to lose)
  or critical details too specific for the compression (flag these as risk
  areas that need extra attention).
- **Mutated** — places where the agent's language was more complicated than the
  underlying idea. The mutated version may actually be *clearer* than the
  original.

## Example: a clear plan (passes)

Here's a real test run. The input describes a game server's building system:

> The Minecraft server has a schematic system with 2,139 blueprints across 30
> categories. A Python scraping pipeline fetches building designs from GrabCraft,
> converts them to a JSON catalog, and the Java backend loads this catalog at
> startup. When an AI god decides to build something, it picks a schematic from
> the catalog by category and places it block-by-block in the world relative to a
> target player's position. The catalog is cached at module level so changes
> require a backend restart.

**Compressed to Toki Pona:**

> musi pi ma tomo li jo e nasin pali tomo. lipu tomo li mute mute — nanpa 2139
> li lon. ona li kama tan kulupu 30. ilo Python li alasa e lipu tomo ni tan ma
> kulupu GrabCraft. ona li ante e ona tawa lipu sona JSON. ilo suli pi pali musi
> li open e lipu sona ni lon tenpo open taso. jan sewi pi sona suli li wile pali
> e tomo la ona li lukin e lipu sona li alasa e tomo pi kulupu pona. ona li pali
> e tomo ni kepeken kiwen wan wan lon poka pi jan musi. lipu sona li awen lon
> insa ilo. ante li kama la sina wile pini e ilo li open sin.

**Blind reconstruction (by a separate Claude instance with no context):**

> The game server has a building system. There are very many blueprints — 2139
> exist. They come from 30 categories. A Python tool fetches these blueprints
> from the GrabCraft community site. It converts them into JSON data files. The
> main game engine loads this data only once at startup. When a god of great
> knowledge wants to build a structure, it looks through the data and searches
> for a building in the right category. It constructs that building block by
> block near the player. The data stays cached inside the engine. If changes are
> made, you need to restart the engine.

**Results:**

| Category | Details |
|----------|---------|
| Survived | 2,139 blueprints, 30 categories, Python scrapes GrabCraft, converts to JSON, loads at startup, god picks by category, places block-by-block near player, cached, restart required |
| Vanished | "Java backend" → "game engine", "module-level caching" → "cached inside the engine" (implementation detail lost, behavior preserved) |
| Mutated | "Minecraft server" → "game server", "AI god" → "a god of great knowledge" |

**Verdict:** This plan is clear. Every structural element survived. The only
losses were implementation-specific jargon that arguably doesn't belong in a
high-level summary anyway.

## Example: an overcomplicated plan (fails)

Same project, different feature. An AI agent produced a 13-section
implementation plan for a lighting system. The plan went through four major
architectural revisions before shipping — the agent overspecified the *how*
while the *what* stayed the same the entire time. Here's the initial plan,
condensed:

> The lighting system needs a new LightRenderer class that manages OmniLight3D
> nodes and Sprite3D fixture visuals, indexed by chunk position in separate
> dictionaries. Light placement follows the door placement pattern in the
> generator — scanning ceiling tiles, checking edge margins, enforcing minimum
> spacing with a configurable density parameter, and rolling for broken variants.
> Light data is stored in chunk.metadata as an array of dictionaries containing
> tile position, fixture type, broken status, color, energy, and range. The
> LightRenderer hooks into Grid3D's load\_chunk and unload\_chunk lifecycle,
> creating OmniLight3D nodes with tuned attenuation, zero specular for PSX
> aesthetic, and disabled shadows. Fixture sprites are non-billboard Sprite3D
> nodes positioned at the ceiling using empirically determined Y coordinates.
> LevelConfig gets five new exported properties for density, broken chance, color,
> energy, and range. A flicker system uses per-light timer dictionaries with
> randomized intervals driving tween-based energy dips. The GL Compatibility
> renderer's per-object light limit needs a spike test before committing to the
> design, and if the limit is too low we may need shader-based fake lighting
> instead.

**Compressed to Toki Pona:**

> nasin suno li wile e ilo sin pi pali suno. ilo ni li lawa e suno mute kepeken
> lipu tu — lipu nanpa wan li jo e suno, lipu nanpa tu li jo e sitelen pi ilo
> suno. ilo ni li sona e ma pi suno ale.
>
> jan pali li pana e suno sama nasin pi pana lupa. ona li lukin e sewi pi ma
> tomo, li sona e noka pi suno ante, li kepeken nanpa pi pana suno. ken la suno
> li pakala — ni li pimeja.
>
> sona pi suno wan li lon insa pi ma lili. sona ni li kulupu mute: ma pi suno,
> nimi pi ilo suno, pakala anu pakala ala, kule, wawa, suli.
>
> ilo suno li kama lon tenpo pi open ma lili, li weka lon tenpo pi pini ma lili.
> suno li jo ala e len pi pilin suno — ni li pona tawa lukin pi musi lili.
> sitelen pi ilo suno li lon sewi kepeken nanpa Y pi sona lukin.
>
> lipu pi nasin ma li jo e nanpa lili sin: mute pi suno, ken pi pakala, kule,
> wawa, suli. nasin pi suno pipi li kepeken tenpo pi suno wan wan. tenpo li pini
> la suno li kama lili la suno li kama suli sin.
>
> ilo pi lukin pona li ken ala jo e suno mute lon ma wan. ni la mi wile sona e
> ken pi ilo ni. ken la mi wile ante e nasin suno tawa nasin pi sitelen taso.

**Blind reconstruction:**

> The lighting system requires a new light rendering tool. This tool manages many
> lights using two textures — the first texture holds the light data, and the
> second texture holds the light sprite images. This tool knows the positions of
> all the lights.
>
> The worker creates lights following a spawning method. They look at the ceiling
> of the room, know the positions of different lights, and use lighting
> parameters. Sometimes a light can break — this means darkness.
>
> The data for a single light is stored inside a small region. This data has many
> fields: light position, light sprite name, broken or not broken, color,
> intensity, and size.
>
> Lights appear when the small region is created, and disappear when the small
> region is destroyed. Lights have no smoothing — this is good for the look of a
> small game. The light sprite images are positioned above using the Y value of
> the visual data.
>
> The map data file has new small values: number of lights, chance of breaking,
> color, intensity, and size. The flickering light method uses a one-by-one light
> timing cycle. When the cycle ends and the light gets small, the light grows
> large again.
>
> The rendering tool cannot handle many lights in one area. So we need to
> understand the limits of this tool. Perhaps we need to change the lighting
> system to a sprite-only approach.

**Results:**

| Category | What happened |
|----------|---------------|
| Survived | Place lights on ceilings, store per-light fields (position, type, broken, color, energy, range), config properties for density/broken chance/color/energy/range, lights appear/disappear with chunk lifecycle, there's a light limit concern and a possible fallback approach |
| Vanished | "Indexed by chunk position in separate dictionaries," "follows the door placement pattern," "edge margins," "minimum spacing enforcement," "tuned attenuation," "zero specular for PSX aesthetic," "tween-based energy dips," "GL Compatibility" specifics |
| Mutated | "Two dictionaries indexed by chunk position" → "two textures" (data structure lost), "per-light timer dictionaries with randomized intervals" → "one-by-one timing cycle" (mechanism lost, behavior preserved), "shader-based fake lighting" → "sprite-only approach" (fallback misidentified) |

**Verdict: this plan was too complex.** The *what* survived clearly — place
lights on ceilings, store these fields, flicker them, worry about limits. But
the *how* — dictionary indexing, door placement analogy, tween energy dips, GL
Compatibility specifics — all vanished or mutated beyond recognition.

In practice, this plan was thrown out and rewritten three more times before
shipping. The core requirements (the parts that survived compression) stayed the
same through every revision. The implementation details (the parts that
vanished) changed completely. The linter would have flagged this up front: the agent knew *what* it wanted to
build, but the *how* was overspecified and likely wrong.

## Installation

Clone this repo and symlink the skill into your Claude Code skills directory:

```bash
git clone https://github.com/aebrer/toki-pona-sona-pona.git
ln -s /path/to/toki-pona-sona-pona/skills/toki-pona-sona-pona ~/.claude/skills/toki-pona-sona-pona
```

## Usage

In any Claude Code session:

```
/toki-pona-sona-pona
```

Or just describe a plan and say "complexity check" or "is this too
complicated?"

The skill can also be triggered proactively by Claude after it proposes a plan —
to sanity-check its own work before implementation begins.

## Why Toki Pona?

Toki Pona is a philosophical constructed language created by Sonja Lang with the
goal of expressing maximal meaning with minimal complexity. Its vocabulary of
~130 words forces speakers to break concepts down into their most fundamental
components.

This makes it an ideal "lossy compression codec" for ideas. If your idea
survives the round trip, its essence is communicable in basic human concepts. If
it doesn't, you may be overcomplicating things — or you've identified the
specific details that need careful, explicit communication.

## License

MIT
