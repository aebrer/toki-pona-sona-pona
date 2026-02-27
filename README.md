# toki pona, sona pona

*"simple speech, good knowledge"*

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that uses
[Toki Pona](https://tokipona.org/) — a constructed language with only ~130
words — as a complexity linter for plans and ideas.

## The concept

If a plan can survive round-trip translation through a 130-word language and
back, its core is clear. If it can't, something is overcomplicated or unclear.

The skill works in four steps:

1. You describe a plan, architecture, or idea
2. Claude translates it into Toki Pona, compressing it down to semantic
   primitives
3. A **blind** agent (with zero context about the original) translates the Toki
   Pona back into English
4. You compare the original and reconstruction to see what survived, what
   vanished, and what mutated

This is essentially the "explain it to a five-year-old" test, but mechanized
and repeatable. The forced compression strips away jargon, unnecessary
abstraction, and overcomplicated language, leaving only the core intent.

## What the results tell you

- **Survived** — the essential parts of your plan. Clear, simple,
  well-understood.
- **Vanished** — either unnecessary fluff (good to lose) or critical details
  too specific for the compression (flag these as risk areas that need extra
  attention when communicating the plan to others).
- **Mutated** — places where your language was more complicated than the
  underlying idea. The mutated version may actually be *clearer* than the
  original.

## Live example

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

The skill can also be triggered proactively by Claude after you've
collaboratively arrived at a plan — to sanity-check it before implementation.

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
