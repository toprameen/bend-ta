import Base
import ./support.bend as Tool
import ./policy.bend as Policy

def paths(files: List<&2, String>, +root: String) -> List<String>:
  match files:
    case Nil{}:
      Nil{}
    case h <> t:
      (root ++ "/" ++ h) <> paths(t, root)

def validate.path(file: String, rest: Unit -> Result<String, Unit>, allowed: Bool) -> Result<String, Unit>:
  match allowed:
    case False{}:
      Fail{"Bend-only policy: disallowed file " ++ file}
    case True{}:
      rest(Unit{})

def validate.paths(files: List<&2, String>) -> Result<String, Unit>:
  match files:
    case Nil{}:
      Done{Unit{}}
    case +file <> rest:
      validate.path(file, u => validate.paths(rest), Policy.allowed(file))

def special.files(output: String, empty: Bool) -> IO(Result<String, Unit>):
  match empty:
    case True{}:
      Tool.done(Unit, Unit{})
    case False{}:
      Tool.fail(Unit, "Bend-only policy: symlink or executable non-Bend file\n" ++ output)

def special.result(+output: String) -> IO(Result<String, Unit>):
  special.files(output, String.is_empty(output))

def ordinary(+root: String, files: List<&2, String>) -> IO(Result<String, Unit>):
  Tool.bind(String, Unit, Tool.command("find", List.append(&1, String, paths(files, root),
    ["(", "-type", "l", "-o", "(", "-type", "f", "!", "-name", "*.bend", "(", "-perm", "-100", "-o", "-perm", "-010", "-o", "-perm", "-001", ")", ")", ")", "-print0"])),
    out => special.result(out))

def source.entry(bend: String, path: String, standalone: Bool) -> IO(Result<String, Unit>):
  match standalone:
    case False{}:
      Tool.done(Unit, Unit{})
    case True{}:
      Tool.bind(String, Unit, Tool.command(bend, [path, "--check-only"]), out => Tool.done(Unit, Unit{}))

def source.check(bend: String, path: String, +file: String, clean: Bool) -> IO(Result<String, Unit>):
  match clean:
    case False{}:
      Tool.fail(Unit, "Bend-only policy: quoted foreign import in " ++ file)
    case True{}:
      source.entry(bend, path, Policy.source_entry(file))

def source(+root: String, bend: String, +file: String) -> IO(Result<String, Unit>):
  +path = root ++ "/" ++ file
  Tool.bind(String, Unit, Tool.read(path), text => source.check(bend, path, file, Policy.bend_source(text)))

def inspect.file(root: String, bend: String, file: String, is_bend: Bool) -> IO(Result<String, Unit>):
  match is_bend:
    case False{}:
      Tool.done(Unit, Unit{})
    case True{}:
      source(root, bend, file)

def inspect(files: List<&2, String>, +root: String, +bend: String) -> IO(Result<String, Unit>):
  match files:
    case Nil{}:
      Tool.done(Unit, Unit{})
    case +file <> rest:
      Tool.bind(Unit, Unit, inspect.file(root, bend, file, String.ends_with(file, ".bend")), u => inspect(rest, root, bend))

def modules.result(present: Bool) -> IO(Result<String, Unit>):
  match present:
    case True{}:
      Tool.fail(Unit, "Bend-only policy: Git submodules are not allowed")
    case False{}:
      Tool.done(Unit, Unit{})

def modules(root: String) -> IO(Result<String, Unit>):
  Tool.bind(String, Unit, Tool.command("git", ["-C", root, "ls-files", "--stage", "-z"]), out =>
    modules.result(List.any(~&2, ~String, ~(s => String.starts_with(s, "160000 ")), Tool.fields(out))))

def check.files(+root: String, bend: String, +files: List<&2, String>, proofs: Bool) -> IO(Result<String, Unit>):
  match proofs:
    case False{}:
      Tool.fail(Unit, "Bend proof policy: LAWS.bend and PROOF.bend are required")
    case True{}:
      Tool.then(Unit, Unit, validate.paths(files), u =>
        Tool.bind(Unit, Unit, modules(root), v =>
          Tool.bind(Unit, Unit, ordinary(root, files), w => inspect(files, root, bend))))

def check(root: String, bend: String, +files: List<&2, String>) -> IO(Result<String, Unit>):
  check.files(root, bend, files, Policy.proof_files(files))

def start.root(bend: String, +root: String) -> IO(Result<String, Unit>):
  Tool.bind(List<&2, String>, Unit, Tool.files(root), files => check(root, bend, files))

def report(result: Result<String, Unit>) -> IO(Unit):
  match result:
    case Fail{message}:
      IO.die(Unit, 1, message)
    case Done{u}:
      IO.print("PASS Bend-only repository policy")

def main() -> IO(Unit):
  do IO<Unit>:
    bend : String <- Tool.env("BEND", "bend")
    result : Result<String, Unit> <- Tool.bind(String, Unit, Tool.root(), root => start.root(bend, root))
    report(result)
