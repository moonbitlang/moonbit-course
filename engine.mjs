import { getHighlighter } from "shiki";
import mbt from "./moonbit.tmLanguage.json" with { type: "json" };
import abnf from "./abnf.tmLanguage.json" with { type: "json" };
// engine.js
export default async ({ marp }) => {
  const highlighter = await getHighlighter({
    themes: ["github-light"],
    langs: [mbt, abnf],
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
