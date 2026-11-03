import Base
import ../../scripts/policy.bend as Policy
import ../../scripts/support.bend as Tool
import ../../scripts/test.bend as Test

def apostrophe() -> Char:
  '''

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(Policy.allowed("src/core/ema.bend")))
    IO.print(Bool.show(Policy.allowed("CONTRIBUTING.md")))
    IO.print(Bool.show(Policy.allowed(".github/workflows/ci.yml")))
    IO.print(Bool.show(Policy.allowed("tests/data/prices.csv")))
    IO.print(Bool.show(Policy.allowed("scripts/test.ts")))
    IO.print(Bool.show(Policy.allowed("scripts/check.py")))
    IO.print(Bool.show(Policy.allowed("scripts/test")))
    IO.print(Bool.show(Policy.allowed("package.json")))
    IO.print(Bool.show(Policy.allowed("tools/package.json")))
    IO.print(Bool.show(Policy.bend_source("import Base\nimport ./math.bend as Math\n")))
    IO.print(Bool.show(Policy.bend_source("def f() -> IO(Unit):\n  import \"./f.c\"\n")))
    IO.print(Bool.show(Policy.bend_source("import\t# comment\n\"./f.js\"")))
    IO.print(Bool.show(Policy.bend_source("import\u{a0}\"./f.c\"")))
    IO.print(Bool.show(Policy.bend_source("# import \"./ignored.c\"\n")))
    IO.print(Bool.show(Policy.bend_source("def text() -> String:\n  \"import \\\"./data.c\\\"\"\n")))
    IO.print(Bool.show(Policy.bend_source("def quote() -> Char:\n  '''\n\ndef text() -> String:\n  \"'import \"\n")))
    IO.print(Bool.show(Policy.bend_source("def quote() -> Char:\n  '''\n\ndef foreign() -> U32:\n  import \"./f.c\"\n")))
    IO.print(Bool.show(Policy.bend_source("def quote() -> Char:\n  '\\''\n\ndef text() -> String:\n  \"'import \"\n")))
    IO.print(Bool.show(Policy.bend_source("def quote() -> Char:\n  '\\u{27}'\n\ndef text() -> String:\n  \"'import \"\n")))
    IO.print(Bool.show(Char.is_eq(apostrophe(), '\'')))
    IO.print(Bool.show(String.eq(Tool.normalize("\r\n  a\r\nb  \r\n"), "a\nb")))
    IO.print(Bool.show(String.eq(Tool.normalize("a\rb"), "a\rb")))
    IO.print(Bool.show(Test.fixture("tests/reference/ema.bend")))
    IO.print(Bool.show(Test.fixture("scripts/support.bend")))
    IO.print(Bool.show(Policy.source_entry("LAWS.bend")))
    IO.print(Bool.show(Policy.source_entry("PROOF.bend")))
    IO.print(Bool.show(Policy.source_entry("proofs/LAWS.bend")))
    IO.print(Bool.show(Policy.proof_files(["LAWS.bend", "PROOF.bend"])))
    IO.print(Bool.show(Policy.proof_files(["LAWS.bend"])))
    IO.print(Bool.show(Policy.proof_files(["PROOF.bend"])))

#|True
#|True
#|True
#|True
#|False
#|False
#|False
#|False
#|False
#|True
#|False
#|False
#|False
#|True
#|True
#|True
#|False
#|True
#|True
#|True
#|True
#|True
#|True
#|False
#|False
#|True
#|True
#|True
#|False
#|False
