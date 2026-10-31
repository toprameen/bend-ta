import Base
import ./support.bend as Tool

type Mode is Data:
  Native{}
  Both{}
  Help{}

type Context is Data:
  Context{root: String, bend: String, js: Bool, runtime: String}

def usage() -> String:
  "Usage: bend scripts/test.bend [-- --js|--help]\nNative tests run by default; --js also tests emitted JavaScript.\nBEND selects the compiler; BEND_JS selects the JS runtime (default: node)."

def options(args: List<String>) -> Result<String, Mode>:
  match args:
    case Nil{}:
      Done{Native{}}
    case "--js" <> Nil{}:
      Done{Both{}}
    case "--help" <> Nil{}:
      Done{Help{}}
    case rest:
      Fail{usage()}

def fixture(+file: String) -> Bool:
  Bool.and(String.ends_with(file, ".bend"), Bool.or(String.starts_with(file, "tests/"), String.starts_with(file, "examples/")))

def expected.strip(lines: List<&2, String>) -> List<&2, String>:
  match lines:
    case Nil{}:
      Nil{}
    case h <> t:
      String.drop(h, 2n) <> expected.strip(t)

def expected.finish(lines: List<&2, String>) -> Result<String, String>:
  match lines:
    case Nil{}:
      Fail{"missing #| expected output"}
    case h <> t:
      Done{Tool.normalize(String.join(expected.strip(h <> t), "\n"))}

def expected.lines(source: String, line: String, lines: List<&2, String>) -> List<&2, String>:
  match source:
    case SNil{}:
      List.reverse(&2, String, String.reverse(line) <> lines)
    case SCon{'\n', rest}:
      expected.lines(rest, SNil{}, String.reverse(line) <> lines)
    case SCon{char, rest}:
      expected.lines(rest, SCon{char, line}, lines)

def expected(source: String) -> Result<String, String>:
  expected.finish(List.filter(~String, ~(s => String.starts_with(s, "#|")), expected.lines(source, SNil{}, Nil{})))

def check.if(label: String, expected: String, actual: String, equal: Bool) -> IO(Result<String, Unit>):
  match equal:
    case True{}:
      Tool.done(Unit, Unit{})
    case False{}:
      Tool.fail(Unit, label ++ "\nexpected:\n" ++ expected ++ "\nactual:\n" ++ actual)

def check(label: String, +expected: String, got: String) -> IO(Result<String, Unit>):
  +actual = Tool.normalize(got)
  check.if(label, expected, actual, String.eq(expected, actual))

def run_js(enabled: Bool, runtime: String, file: String, js: String, expected: String) -> IO(Result<String, Unit>):
  match enabled:
    case False{}:
      Tool.done(Unit, Unit{})
    case True{}:
      Tool.bind(String, Unit, Tool.command(runtime, [js]), got => check(file ++ ": JS", expected, got))

def execute(js: Bool, runtime: String, +file: String, exe: String, output_js: String, +expected: String) -> IO(Result<String, Unit>):
  Tool.bind(String, Unit, Tool.command(exe, []), got =>
    Tool.bind(Unit, Unit, check(file ++ ": native", expected, got), u => run_js(js, runtime, file, output_js, expected)))

def outputs(js: Bool, exe: String, output_js: String) -> List<String>:
  match js:
    case False{}:
      ["-o", exe]
    case True{}:
      ["-o", exe, "-o", output_js]

def build(context: Context, +file: String, +dir: String, +index: U32, expected: String) -> IO(Result<String, Unit>):
  match context:
    case Context{root, bend, +js, runtime}:
      +exe = dir ++ "/" ++ U32.show(index) ++ ".native"
      +output_js = dir ++ "/" ++ U32.show(index) ++ ".js"
      Tool.bind(String, Unit, Tool.command(bend, (root ++ "/" ++ file) <> outputs(js, exe, output_js)), out =>
        execute(js, runtime, file, exe, output_js, expected))

def run_file(+context: Context, +file: String, dir: String, index: U32) -> IO(Result<String, Unit>):
  match context:
    case Context{+root, bend, js, runtime}:
      Tool.bind(String, Unit, Tool.read(root ++ "/" ++ file), source =>
        Tool.then(String, Unit, expected(source), want => build(Context{root, bend, js, runtime}, file, dir, index, want)))

def loop(files: List<&2, String>, +context: Context, +dir: String, +count: U32) -> IO(Result<String, U32>):
  match files:
    case Nil{}:
      Tool.done(U32, count)
    case +file <> rest:
      Tool.bind(Unit, U32, run_file(context, file, dir, count), u =>
        do IO<Result<String, U32>>:
          Unit <- IO.print("PASS " ++ file)
          loop(rest, context, dir, U32.add(count, 1)))

def cleanup.result(result: Result<String, U32>, removed: Result<String, String>) -> IO(Result<String, U32>):
  match result removed:
    case Fail{error} Fail{cleanup_error}:
      Tool.fail(U32, error ++ "\ncleanup: " ++ cleanup_error)
    case Fail{error} Done{out}:
      Tool.fail(U32, error)
    case Done{count} Fail{error}:
      Tool.fail(U32, "cleanup: " ++ error)
    case Done{count} Done{out}:
      Tool.done(U32, count)

def cleanup(dir: String, result: Result<String, U32>) -> IO(Result<String, U32>):
  do IO<Result<String, U32>>:
    removed : Result<String, String> <- Tool.command("rm", ["-rf", "--", dir])
    cleanup.result(result, removed)

def temporary(context: Context, files: List<&2, String>, +dir: String, empty: Bool) -> IO(Result<String, U32>):
  match empty:
    case True{}:
      Tool.fail(U32, "mktemp returned an empty path")
    case False{}:
      IO.bind(Result<String, U32>, Result<String, U32>, loop(files, context, dir, 0), result => cleanup(dir, result))

def report(js: Bool, +count: U32) -> IO(Result<String, Unit>):
  do IO<Result<String, Unit>>:
    Unit <- IO.print("PASS " ++ U32.show(count) ++ " fixtures / " ++ U32.show(U32.mul(count, Bool.pick(U32, js, 2, 1))) ++ " runtime checks")
    Tool.done(Unit, Unit{})

def temporary.prepare(context: Context, files: List<&2, String>, text: String) -> IO(Result<String, U32>):
  +dir = String.trim(text)
  temporary(context, files, dir, String.is_empty(dir))

def run(context: Context, files: List<&2, String>) -> IO(Result<String, Unit>):
  match context files:
    case Context{root, bend, js, runtime} Nil{}:
      Tool.fail(Unit, "no test fixtures found")
    case Context{root, +bend, +js, runtime} h <> t:
      Tool.bind(String, Unit, Tool.command(bend, ["version"]), version =>
        do IO<Result<String, Unit>>:
          Unit <- IO.print(Tool.normalize(version))
          Tool.bind(String, Unit, Tool.command("mktemp", ["-d"]), text =>
            Tool.bind(U32, Unit, temporary.prepare(Context{root, bend, js, runtime}, h <> t, text), count => report(js, count))))

def start.root(js: Bool, bend: String, runtime: String, +root: String) -> IO(Result<String, Unit>):
  Tool.bind(List<&2, String>, Unit, Tool.files(root), files => run(Context{root, bend, js, runtime}, List.filter(~String, ~(f => fixture(f)), files)))

def start.config(js: Bool, bend: String, runtime: String) -> IO(Result<String, Unit>):
  Tool.bind(String, Unit, Tool.root(), root => start.root(js, bend, runtime, root))

def start(js: Bool) -> IO(Result<String, Unit>):
  do IO<Result<String, Unit>>:
    bend : String <- Tool.env("BEND", "bend")
    runtime : String <- Tool.env("BEND_JS", "node")
    start.config(js, bend, runtime)

def selected(mode: Mode) -> IO(Result<String, Unit>):
  match mode:
    case Native{}:
      start(False{})
    case Both{}:
      start(True{})
    case Help{}:
      do IO<Result<String, Unit>>:
        Unit <- IO.print(usage())
        Tool.done(Unit, Unit{})

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    result : Result<String, Unit> <- Tool.then(Mode, Unit, options(List.tail(&1, String, args)), selected)
    Tool.finish(result)
