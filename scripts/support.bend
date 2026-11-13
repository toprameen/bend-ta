import Base

def done(-A: Type, value: A) -> IO(Result<String, A>):
  IO.pure(Result<String, A>, Done{value})

def fail(-A: Type, message: String) -> IO(Result<String, A>):
  IO.pure(Result<String, A>, Fail{message})

def then(-A: Type, -B: Type, result: Result<String, A>, next: A -> IO(Result<String, B>)) -> IO(Result<String, B>):
  match result:
    case Fail{message}:
      fail(B, message)
    case Done{value}:
      next(value)

def bind(-A: Type, -B: Type, action: IO(Result<String, A>), next: A -> IO(Result<String, B>)) -> IO(Result<String, B>):
  IO.bind(Result<String, A>, Result<String, B>, action, r => then(A, B, r, next))

def command.exit(program: String, code: U32, stdout: String, stderr: String, ok: Bool) -> Result<String, String>:
  match ok:
    case True{}:
      Done{stdout}
    case False{}:
      Fail{program ++ ": exit " ++ U32.show(code) ++ "\n" ++ stdout ++ stderr}

def command.result(program: String, result: Result<&1, &1, U32 & String, U32 & (String & String)>) -> Result<String, String>:
  match result:
    case Fail{(code, message)}:
      Fail{program ++ ": " ++ U32.show(code) ++ " " ++ message}
    case Done{(+code, (stdout, stderr))}:
      command.exit(program, code, stdout, stderr, U32.is_zero(code))

def command.timed(+program: String, args: List<String>, timeout: U32) -> IO(Result<String, String>):
  do IO<Result<String, String>>:
    result : Result<&1, &1, U32 & String, U32 & (String & String)> <- Process.run(program, args, "", 4194304, timeout)
    IO.pure(Result<String, String>, command.result(program, result))

def command(program: String, args: List<String>) -> IO(Result<String, String>):
  command.timed(program, args, 30000)

def env.result(fallback: String, result: Result<&1, &1, U32 & String, String>) -> String:
  match result:
    case Fail{e}:
      fallback
    case Done{SNil{}}:
      fallback
    case Done{SCon{h, t}}:
      SCon{h, t}

def env(name: String, fallback: String) -> IO(String):
  do IO<String>:
    result : Result<&1, &1, U32 & String, String> <- IO.get_env(name)
    IO.pure(String, env.result(fallback, result))

def fields(s: String) -> List<&2, String>:
  List.filter(~String, ~(x => Bool.not(String.is_empty(x))), String.split(s, '\u{0}'))

def root() -> IO(Result<String, String>):
  bind(String, String, command("git", ["rev-parse", "--show-toplevel"]), s => done(String, String.trim(s)))

def files.keep.if(+file: String, rest: List<&2, String>, deleted: Bool) -> List<&2, String>:
  match deleted:
    case True{}:
      rest
    case False{}:
      file <> rest

def files.keep(files: List<&2, String>, +deleted: List<&2, String>) -> List<&2, String>:
  match files:
    case Nil{}:
      Nil{}
    case +h <> t:
      files.keep.if(h, files.keep(t, deleted), List.contains(~String, ~String.eq, deleted, h))

def files.deleted(root: String, files: List<&2, String>) -> IO(Result<String, List<&2, String>>):
  bind(String, List<&2, String>, command("git", ["-C", root, "ls-files", "--deleted", "-z"]), s =>
    done(List<&2, String>, List.sort(~String, ~String.is_le, files.keep(files, fields(s)))))

def files(+root: String) -> IO(Result<String, List<&2, String>>):
  bind(String, List<&2, String>, command("git", ["-C", root, "ls-files", "--cached", "--others", "--exclude-standard", "-z"]), s => files.deleted(root, fields(s)))

def read.closed(result: File & Result<&1, &1, U32 & String, String>) -> IO(Result<String, String>):
  match result:
    case (file, Fail{(code, message)}):
      do IO<Result<String, String>>:
        Unit <- File.close(file)
        fail(String, "read: " ++ U32.show(code) ++ " " ++ message)
    case (file, Done{text}):
      do IO<Result<String, String>>:
        Unit <- File.close(file)
        done(String, text)

def read.bound(file: File, fits: Bool) -> IO(Result<String, String>):
  match fits:
    case False{}:
      do IO<Result<String, String>>:
        Unit <- File.close(file)
        fail(String, "source exceeds the 1 MiB tooling limit")
    case True{}:
      IO.bind(File & Result<&1, &1, U32 & String, String>, Result<String, String>, File.read(file, 1048576), read.closed)

def read.sized(result: File & Result<&1, &1, U32 & String, U32>) -> IO(Result<String, String>):
  match result:
    case (file, Fail{(code, message)}):
      do IO<Result<String, String>>:
        Unit <- File.close(file)
        fail(String, "size: " ++ U32.show(code) ++ " " ++ message)
    case (file, Done{size}):
      read.bound(file, U32.is_le(size, 1048576))

def read.opened(result: Result<&1, &1, U32 & String, File>) -> IO(Result<String, String>):
  match result:
    case Fail{(code, message)}:
      fail(String, "open: " ++ U32.show(code) ++ " " ++ message)
    case Done{file}:
      IO.bind(File & Result<&1, &1, U32 & String, U32>, Result<String, String>, File.size(file), read.sized)

def read(path: String) -> IO(Result<String, String>):
  IO.bind(Result<&1, &1, U32 & String, File>, Result<String, String>, File.open(path, "r"), read.opened)

def finish(result: Result<String, Unit>) -> IO(Unit):
  match result:
    case Fail{message}:
      IO.die(Unit, 1, message)
    case Done{u}:
      IO.pure(Unit, Unit{})
