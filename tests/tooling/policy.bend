import Base
import ../../scripts/assert.bend as Assert
import ../../scripts/policy.bend as Policy

def apostrophe() -> Char:
  '''

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Assert.check("allow Bend source", Policy.allowed("src/core/ema.bend"))
    Unit <- Assert.check("allow Markdown", Policy.allowed("CONTRIBUTING.md"))
    Unit <- Assert.check("allow CI YAML", Policy.allowed(".github/workflows/ci.yml"))
    Unit <- Assert.check("allow CSV data", Policy.allowed("tests/data/prices.csv"))
    Unit <- Assert.check("reject TypeScript", Bool.not(Policy.allowed("scripts/test.ts")))
    Unit <- Assert.check("reject Python", Bool.not(Policy.allowed("scripts/check.py")))
    Unit <- Assert.check("reject extensionless scripts", Bool.not(Policy.allowed("scripts/test")))
    Unit <- Assert.check("reject package manifest", Bool.not(Policy.allowed("package.json")))
    Unit <- Assert.check("reject nested package manifest", Bool.not(Policy.allowed("tools/package.json")))
    Unit <- Assert.check("allow Bend imports", Policy.bend_source("import Base\nimport ./math.bend as Math\n"))
    Unit <- Assert.check("reject foreign import in a function", Bool.not(Policy.bend_source("def f() -> IO(Unit):\n  import \"./f.c\"\n")))
    Unit <- Assert.check("reject import across a comment", Bool.not(Policy.bend_source("import\t# comment\n\"./f.js\"")))
    Unit <- Assert.check("reject import with nonbreaking space", Bool.not(Policy.bend_source("import\u{a0}\"./f.c\"")))
    Unit <- Assert.check("ignore imports inside comments", Policy.bend_source("# import \"./ignored.c\"\n"))
    Unit <- Assert.check("ignore imports inside strings", Policy.bend_source("def text() -> String:\n  \"import \\\"./data.c\\\"\"\n"))
    Unit <- Assert.check("accept raw apostrophe before a string", Policy.bend_source("def quote() -> Char:\n  '''\n\ndef text() -> String:\n  \"'import \"\n"))
    Unit <- Assert.check("reject foreign import after raw apostrophe", Bool.not(Policy.bend_source("def quote() -> Char:\n  '''\n\ndef foreign() -> U32:\n  import \"./f.c\"\n")))
    Unit <- Assert.check("accept escaped apostrophe", Policy.bend_source("def quote() -> Char:\n  '\\''\n\ndef text() -> String:\n  \"'import \"\n"))
    Unit <- Assert.check("accept Unicode escape", Policy.bend_source("def quote() -> Char:\n  '\\u{27}'\n\ndef text() -> String:\n  \"'import \"\n"))
    Unit <- Assert.check("raw apostrophe value", Char.is_eq(apostrophe(), '\''))
    Unit <- Assert.check("check laws through the proof entry point", Bool.not(Policy.source_entry("LAWS.bend")))
    Unit <- Assert.check("check the proof entry point", Policy.source_entry("PROOF.bend"))
    Unit <- Assert.check("check nested laws normally", Policy.source_entry("proofs/LAWS.bend"))
    Unit <- Assert.check("require both proof files", Policy.proof_files(["LAWS.bend", "PROOF.bend"]))
    Unit <- Assert.check("require proof entry", Bool.not(Policy.proof_files(["LAWS.bend"])))
    Assert.check("require laws", Bool.not(Policy.proof_files(["PROOF.bend"])))
