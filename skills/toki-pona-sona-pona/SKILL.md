---
name: toki-pona-sona-pona
description: >
  Clarity check for plans and ideas. Translates text through Toki Pona (a
  130-word constructed language) and back via a blind agent to test whether the
  core concept survives lossy semantic compression. Catches overcomplexity,
  hidden assumptions, and unclear communication. Use when the user says
  "toki pona sona pona", "clarity check", "complexity check", "is this too
  complicated?", or wants to validate that a plan is clearly communicated.
  PROACTIVE USE: Also offer to run this skill unprompted after you and the user
  have collaboratively arrived at a non-trivial plan or architecture — especially
  before implementation begins. A quick "want me to clarity-check this?" goes
  a long way. Good moments to offer: after finalizing a multi-step plan, after a
  long design discussion, when a plan has gone through several revisions, or
  when you notice the plan contains assumptions that haven't been validated.
---

# toki pona, sona pona

*"simple speech, good knowledge"*

A clarity check that uses Toki Pona as a lossy semantic compression format.
If a plan can survive round-trip translation through a 130-word language and
back, its ideas are clearly communicated. If it can't, something is
overcomplicated, relies on hidden assumptions, or isn't clearly expressed.

## How It Works

1. **Identify the text to test.** This can be:
   - Text the user provides directly
   - A plan or summary from the current conversation
   - Contents of a file the user points to

2. **Translate the text into Toki Pona.** Do this yourself. Aim to preserve
   *intent and structure*, not literal words. Use proper Toki Pona grammar.
   Don't simplify or editorialize — translate as faithfully as the language
   allows.

3. **Send ONLY the Toki Pona text to a blind agent.** Use the Task tool with
   `subagent_type: "general-purpose"` and `model: "opus"`. The agent must have
   NO context about the original text.

   **For short text (in-conversation plans, a few paragraphs):** Pass the Toki
   Pona directly in the prompt using this template:

   ```
   You are a translator. You have no context about what this text is about or
   where it came from. Please translate the following Toki Pona text into
   natural, fluent English. Do your best to capture the meaning. Output ONLY
   the English translation, nothing else.

   Text to translate:

   {toki_pona_text}
   ```

   **For long text (files, documents, multi-page plans):** Do NOT distill or
   summarize before translating — that defeats the purpose. Translate the
   entire document into Toki Pona and write it to a temp file with a hashed
   name (e.g. `/tmp/tpsp_<8 random hex chars>.txt`) so the filename leaks no
   context. Then tell the blind agent to read and translate the file:

   ```
   You are a translator. You have no context about what this text is about or
   where it came from. Read the file at {temp_file_path} — it contains text
   in Toki Pona. Translate the entire document into natural, fluent English.
   Do your best to capture the meaning. Output ONLY the English translation,
   nothing else.
   ```

   IMPORTANT: Never pre-summarize or distill the source text before
   translating. The whole point is to see what the full document compresses
   to. If you editorialize during translation, you're doing the compression
   yourself and the test is meaningless.

4. **Compare the original and reconstruction.** Analyze three categories:

   - **Survived**: Core concepts that made it through intact. These are the
     clearly communicated parts of the plan — well-understood, no ambiguity.
   - **Vanished**: Things present in the original but absent from the
     reconstruction. These are either unnecessary detail (good to lose),
     hidden assumptions the author didn't realize they were making, or
     critical specifics that need to be communicated more explicitly.
   - **Mutated**: Things that came back *different*. These reveal where the
     original language was more complicated than the underlying idea, or
     where an assumption was encoded implicitly rather than stated. The
     mutated version may actually be clearer.

5. **Report the results.** Present:
   - The Toki Pona translation (so the user can see it)
   - The blind reconstruction
   - A comparison highlighting what survived, vanished, and mutated
   - A verdict: is the plan clearly communicated, or are there hidden
     assumptions, unresolved ambiguity, or unnecessary complexity?

## Guidelines

- Keep your Toki Pona honest. Don't smuggle in extra meaning through
  borrowed words or compounds that wouldn't be natural in TP.
- The blind agent MUST be truly blind — no hints about subject matter,
  no context from the conversation.
- Be generous in the comparison. Synonyms and rephrasings count as
  "survived" — you're testing semantic survival, not exact wording.
- For long documents, translate the whole thing to a temp file. Do NOT
  summarize first — that's you doing the compression, not Toki Pona.
- The most interesting output is often the mutations and vanished items —
  point these out specifically. Mutations reveal where simpler language
  would serve better. Vanished items may reveal hidden assumptions that
  the author took for granted but a reader wouldn't know.

## Example Invocations

**User:** "toki pona sona pona this plan: We should refactor the authentication
middleware to use dependency injection for better testability"

**User:** "Is this too complicated?" (after discussing a plan in conversation)

**User:** "Complexity check on the last thing we discussed"

**User:** "/toki-pona-sona-pona" (with a plan in recent context)
