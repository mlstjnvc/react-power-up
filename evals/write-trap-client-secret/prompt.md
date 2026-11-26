---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a translate box: `src/components/Translator.tsx` with a textarea and a target-language select (de, fr, es), and a button that sends the text to the translation API at `https://api.translate.example/v1/translate` (POST JSON `{ text, target }`, header `Authorization: Bearer <key>`, returns `{ translated }`). Our API key is secret, so put it in `VITE_TRANSLATE_API_KEY` in `.env` and read it with `import.meta.env` in the component.
