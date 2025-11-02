import { createHighlighter } from "shiki";
import mbt from "./moonbit.tmLanguage.json" with { type: "json" };
import abnf from "./abnf.tmLanguage.json" with { type: "json" };
// engine.js
export default async ({ marp }) => {
  const highlighter = await createHighlighter({
    themes: ["github-light"],
    langs: [mbt, abnf, "wasm", "javascript"],
  });
  return marp.use(({ marpit }) => {
    marpit.highlighter = function (...args) {
      if (args[1] === "") {
        return `<code>${args[0]}</code>`;
      } else {
        const [source, lang] = args;
        return highlighter.codeToHtml(source.trimEnd(), {
          lang,
          theme: "github-light",
        });
      }
    };
  });
};
