// @ts-types="npm:@types/markdown-it@14.1.0"
import MarkdownIt from "npm:markdown-it@14.1.0";
import { parseArgs } from "jsr:@std/cli@1.0.20/parse-args";
import { basename } from "jsr:@std/path@1.1.1/basename";
import { extname } from "jsr:@std/path@1.1.1/extname";

// Handle arguments
const args = parseArgs(Deno.args, {
    boolean: ["help", "h", "test"],
    string: ["complementary"],
});

if (args.h || args.help) {
    console.log(
        "Usage: deno run -A ./code-check.ts [--help|-h] [--test] [--complementary dir] file1.mbt.md",
    );
    Deno.exit(0);
}

const files = args._;

const markdown_files = files.filter((file): file is string =>
    typeof file === "string" && file.endsWith(".mbt.md")
);

const moonbit_files = [];
if (args.complementary) {
    const dir = args.complementary;
    for await (const entry of Deno.readDir(dir)) {
        if (entry.isFile && extname(entry.name) === ".mbt") {
            moonbit_files.push(`${dir}/${entry.name}`);
        }
    }
}

console.group(`Start to check files`);
console.log("Markdown files", markdown_files);
console.log("Moonbit files", moonbit_files);
console.groupEnd();

// Create temporary environment
try {
    await Deno.remove("target/moonbit-check", { recursive: true });
} catch (e) {
    if (e instanceof Deno.errors.NotFound) {
        // Directory does not exist, which is fine
    } else {
        console.error("Failed to remove existing target directory:", e);
        Deno.exit(1);
    }
}
await Deno.mkdir("target/moonbit-check", { recursive: true });
const tempDir = "target/moonbit-check";

// Extract the code from markdown files
type CodeBlock = {
    file: string;
    code: string;
    line: [number, number] | null;
};

const md = new MarkdownIt({});

const codeBlocks: Record<string, CodeBlock[]> = {};

for (const file of markdown_files) {
    const content = await Deno.readTextFile(file);
    const tokens = md.parse(content, {});

    tokens.forEach((token) => {
        const codeInfo = token.info.trim();
        if (
            token.type === "fence" && (
                codeInfo.toLowerCase().startsWith("moonbit") ||
                codeInfo.toLowerCase().startsWith("mbt")
            )
        ) {
            const info = codeInfo.split(/\s+/);
            const codeBlock = {
                file,
                code: token.content,
                line: token.map,
            };
            let targets = ["_"];
            for (const arg of info.slice(1)) {
                if (arg === "skip" || arg === "no-check") {
                    return;
                }
                if (arg.startsWith("unless=")) {
                    targets = arg.slice("unless=".length).split(",");
                }
                if (arg === "test") {
                    codeBlock.code = `test {\n${
                        codeBlock.code.replace(/^/mg, "  ")
                    }\n}`;
                }
            }
            for (const cond of targets) {
                if (!codeBlocks[cond]) {
                    codeBlocks[cond] = [];
                }
                codeBlocks[cond].push(codeBlock);
            }
        }
    });
}

// Process each category of code blocks
for (const [key, blocks] of Object.entries(codeBlocks)) {
    // Create subdirectory for each key
    const keyDir = `${tempDir}/${key}`;
    await Deno.mkdir(keyDir, { recursive: true });
    let blks = blocks;
    if (key !== "_") {
        blks = blocks.concat(codeBlocks["_"]);
    }

    // Process each code block in this category
    for (const codeBlock of blks) {
        const fileName = basename(codeBlock.file, ".mbt.md");
        await Deno.writeTextFile(
            `${keyDir}/${fileName}.md.mbt`,
            `
// ${codeBlock.file}${codeBlock.line ? `:${codeBlock.line[0]}:1` : ""}
${codeBlock.code}
`,
            {
                "create": true,
                "append": true,
            },
        );
    }
    await Deno.writeTextFile(
        `${keyDir}/moon.pkg.json`,
        JSON.stringify(
            {
                "warn-list": "-15+15", // unpromote the warnings
            },
            null,
            2,
        ),
    );
    // Copy the complementary file from the original location
    for (
        const file of moonbit_files
    ) {
        if (basename(file, ".mbt") === key || basename(file, ".mbt") === "_") {
            await Deno.copyFile(file, `${keyDir}/${basename(file)}`);
        }
    }
}

// Generate a temporary project
const project = {
    name: "moonbit-check",
    version: "0.1.0",
};

await Deno.writeTextFile(
    `${tempDir}/moon.mod.json`,
    JSON.stringify(project, null, 2),
);

// Run moonbit check
console.log("Running moonbit check...");
const check_command = new Deno.Command("moon", {
    args: ["check"],
    cwd: tempDir,
    stdout: "piped",
    stderr: "piped",
}).spawn();

if ((await check_command.status).code != 0) {
    console.error("Moonbit check failed");
    Deno.stderr.write((await check_command.output()).stderr);
    Deno.exit(1);
}
console.log("Moonbit check completed successfully.");

if (args.test) {
    console.log("Running moonbit test...");
    const check_command = new Deno.Command("moon", {
        args: ["test"],
        cwd: tempDir,
        stdout: "piped",
        stderr: "piped",
    }).spawn();

    if ((await check_command.status).code != 0) {
        console.error("Moonbit check failed");
        Deno.stderr.write((await check_command.output()).stderr);
        Deno.exit(1);
    }
    console.log("Moonbit test completed successfully.");
}

// Clean up temporary directory
// await Deno.remove(tempDir, { recursive: true });
