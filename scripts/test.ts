import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { spawnSync } from "node:child_process";

const root = path.resolve(import.meta.dir, "..");
const bend = process.env.BEND || "bend";
const native = process.argv.slice(2).includes("--native");
const generated = fs.mkdtempSync(path.join(os.tmpdir(), "bend-ta-test-"));

function files(dir: string): string[] {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(dir, entry.name);
    return entry.isDirectory() ? files(file) : file.endsWith(".bend") ? [file] : [];
  }).sort();
}

function run(command: string[], label: string): string {
  const result = spawnSync(command[0], command.slice(1), {
    cwd: root, encoding: "utf8", timeout: 30_000, maxBuffer: 4 * 1024 * 1024,
  });
  if (result.error || result.status !== 0) {
    throw new Error(`${label}: ${result.error?.message || `exit ${result.status}`}`
      + `\n${result.stdout || ""}${result.stderr || ""}`);
  }
  return result.stdout.replace(/\r\n/g, "\n").trim();
}

try {
  console.log(run([bend, "version"], "Bend executable (set BEND if needed)"));
  const fixtures = [...files(path.join(root, "tests")), ...files(path.join(root, "examples"))];
  let checks = 0;
  for (const [index, file] of fixtures.entries()) {
    const name = path.relative(root, file);
    const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
    const expected = lines.filter(line => line.startsWith("#|")).map(line => line.slice(2)).join("\n").trim();
    if (!lines.some(line => line.startsWith("#|"))) {
      throw new Error(`${name}: missing #| expected output`);
    }
    const js = path.join(generated, `${index}.js`);
    const exe = path.join(generated, `${index}.native`);
    run([bend, file, "-o", js, ...native ? ["-o", exe] : []], `${name}: compile`);
    for (const [lane, command] of [
      ["JS", [process.execPath, js]],
      ...native ? [["native", [exe]]] : [],
    ] as [string, string[]][]) {
      const actual = run(command, `${name}: ${lane}`);
      if (actual !== expected) {
        throw new Error(`${name}: ${lane}\nexpected:\n${expected}\nactual:\n${actual}`);
      }
      checks += 1;
    }
    console.log(`PASS ${name}`);
  }
  console.log(`PASS ${fixtures.length} fixtures / ${checks} runtime checks`);
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
} finally {
  fs.rmSync(generated, { recursive: true, force: true });
}
