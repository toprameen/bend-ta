import Base
import ./support.bend as Tool

type Version is Data:
  Version{major: U32, minor: U32, patch: U32}

type Release is Data:
  Release{repo: String, commit: String, previous: String, tag: String, package: String}

def version.text(major: U32, minor: U32, patch: U32) -> String:
  U32.show(major) ++ "." ++ U32.show(minor) ++ "." ++ U32.show(patch)

def version.parts(major: Maybe<&2, U32>, minor: Maybe<&2, U32>, patch: Maybe<&2, U32>) -> Maybe<&2, Version>:
  match major minor patch:
    case Some{a} Some{b} Some{c}: Some{Version{a, b, c}}
    case _ _ _: None{}

def version.parse(parts: List<&2, String>) -> Maybe<&2, Version>:
  match parts:
    case major <> minor <> patch <> Nil{}:
      version.parts(U32.read(major), U32.read(minor), U32.read(patch))
    case _: None{}

def version.bump(major: U32, bump: String, minor: U32, patch: U32) -> Result<String, String>:
  match bump minor patch:
    case "patch" m 4294967295: Fail{"Patch version overflow"}
    case "patch" m p: Done{version.text(major, m, U32.add(p, 1))}
    case "minor" 4294967295 p: Fail{"Minor version overflow"}
    case "minor" m p: Done{version.text(major, U32.add(m, 1), 0)}
    case _ _ _: Fail{"Choose patch or minor"}

def version.checked(tag: String, bump: String, parsed: Maybe<&2, Version>) -> Result<String, String>:
  match parsed:
    case Some{Version{+major, +minor, +patch}}:
      Bool.pick(Result<String, String>, String.eq(tag, "v" ++ version.text(major, minor, patch)),
        version.bump(major, bump, minor, patch), Fail{"Expected a vMAJOR.MINOR.PATCH release tag"})
    case None{}: Fail{"Expected a vMAJOR.MINOR.PATCH release tag"}

def version.from_tag(+tag: String, bump: String) -> Result<String, String>:
  version.checked(tag, bump, version.parse(String.split(String.drop(tag, 1n), '.')))

def file.written(result: File & Result<&1, &1, U32 & String, Unit>) -> IO(Result<String, Unit>):
  match result:
    case (file, Done{u}):
      do IO<Result<String, Unit>>:
        Unit <- File.close(file)
        Tool.done(Unit, Unit{})
    case (file, Fail{(code, message)}):
      do IO<Result<String, Unit>>:
        Unit <- File.close(file)
        Tool.fail(Unit, "write: " ++ message)

def file.opened(text: String, opened: Result<&1, &1, U32 & String, File>) -> IO(Result<String, Unit>):
  match opened:
    case Fail{(code, message)}: Tool.fail(Unit, "open: " ++ message)
    case Done{file}: IO.bind(File & Result<&1, &1, U32 & String, Unit>, Result<String, Unit>, File.write(file, text), file.written)

def file.write(path: String, mode: String, text: String) -> IO(Result<String, Unit>):
  do IO<Result<String, Unit>>:
    opened : Result<&1, &1, U32 & String, File> <- File.open(path, mode)
    file.opened(text, opened)

def package.license(+dir: String) -> IO(Result<String, Unit>):
  Tool.bind(String, Unit, Tool.read(dir ++ "/LICENSE"), license =>
    Tool.bind(String, Unit, Tool.read(dir ++ "/NOTICE"), notice =>
      file.write(dir ++ "/LICENSE", "w", "SPDX-License-Identifier: Apache-2.0 AND BSD-3-Clause\n\n" ++ license ++ "\n" ++ notice)))

def package.readme(repo: String, package: String) -> String:
  "# bend-ta\n\nTechnical analysis indicators for Bend, with batch and streaming APIs.\n\n" ++
  "```bend\nimport " ++ package ++ "/f32.bend as TA\n```\n\n" ++
  "See the [source and examples](https://github.com/" ++ repo ++ ").\n"

def package.hash.checked(hash: String, valid: Bool) -> IO(Result<String, String>):
  match valid:
    case True{}: Tool.done(String, hash)
    case False{}: Tool.fail(String, "BendHub upload did not return a package hash")

def package.hash.lines(lines: List<&2, String>) -> IO(Result<String, String>):
  match lines:
    case +hash <> rest:
      package.hash.checked(hash, Bool.and(String.starts_with(hash, "0x"), Nat.is_eq(String.length(hash), 34n)))
    case Nil{}: Tool.fail(String, "BendHub upload did not return a package hash")

def package.hash(log: String) -> IO(Result<String, String>):
  package.hash.lines(String.split(String.trim(log), '\n'))

def package.stage(repo: String, commit: String, package: String, +dir: String, +archive: String) -> IO(Result<String, Unit>):
  Tool.bind(String, Unit, Tool.command("git", ["archive", "--format=tar", "--output=" ++ archive, commit,
      "f32.bend", "src", "LAWS.bend", "PROOF.bend", "proofs", "LICENSE", "NOTICE"]), out =>
    Tool.bind(String, Unit, Tool.command("tar", ["-xf", archive, "-C", dir]), extracted =>
      Tool.bind(Unit, Unit, package.license(dir), u =>
        file.write(dir ++ "/README.md", "w", package.readme(repo, package)))))

def package.upload(release: Release, bend: String, +dir: String) -> IO(Result<String, String>):
  match release:
    case Release{repo, commit, previous, tag, package}:
      Tool.bind(Unit, String, package.stage(repo, commit, package, dir, dir ++ "/source.tar"), u =>
        Tool.bind(String, String, Tool.command.timed(bend, [dir ++ "/PROOF.bend", "--publish"], 600000), package.hash))

def tag.status(ref: String, commit: String, remote: String) -> Result<String, Bool>:
  match remote:
    case SNil{}: Done{True{}}
    case existing:
      Bool.pick(Result<String, Bool>, String.eq(existing, commit ++ "\t" ++ ref), Done{False{}},
        Fail{"The release tag already points at a different commit"})

def tag.check(+ref: String, commit: String) -> IO(Result<String, Bool>):
  Tool.bind(String, Bool, Tool.command("git", ["ls-remote", "--refs", "origin", ref]), out =>
    IO.pure(Result<String, Bool>, tag.status(ref, commit, String.trim(out))))

def tag.write(repo: String, ref: String, commit: String, missing: Bool) -> IO(Result<String, String>):
  match missing:
    case False{}: Tool.done(String, "")
    case True{}:
      Tool.command("gh", ["api", "--method", "POST", "repos/" ++ repo ++ "/git/refs", "--silent", "-f", "ref=" ++ ref, "-f", "sha=" ++ commit])

def tag.create(repo: String, +ref: String, +commit: String) -> IO(Result<String, String>):
  Tool.bind(Bool, String, tag.check(ref, commit), missing => tag.write(repo, ref, commit, missing))

def report.summary(path: String, command: String, url: String) -> IO(Result<String, Unit>):
  match path:
    case SNil{}: Tool.done(Unit, Unit{})
    case file: file.write(file, "a", String.trim(url) ++ "\n\nLink the named BendHub version while signed in.\n\n```sh\n" ++ command ++ "\n```\n")

def report(package: String, hash: String, +url: String) -> IO(Result<String, Unit>):
  +command = "bend link " ++ package ++ " " ++ hash
  do IO<Result<String, Unit>>:
    Unit <- IO.print(String.trim(url) ++ "\nLink the named BendHub version with:\n" ++ command)
    summary : String <- Tool.env("GITHUB_STEP_SUMMARY", "")
    report.summary(summary, command, url)

def github.publish(release: Release, +hash: String) -> IO(Result<String, Unit>):
  match release:
    case Release{+repo, commit, previous, +tag, package}:
      Tool.bind(String, Unit, tag.create(repo, "refs/tags/" ++ tag, commit), out =>
        Tool.bind(String, Unit, Tool.command.timed("gh", ["release", "create", tag, "--repo", repo, "--verify-tag",
          "--generate-notes", "--notes-start-tag", previous, "--title", "bend-ta " ++ tag,
          "--notes", "BendHub package hash: `" ++ hash ++ "`. Import with `import " ++ hash ++ "/f32.bend as TA`."], 120000),
          url => report(package, hash, url)))

def release.upload(+release: Release, dir: String) -> IO(Result<String, Unit>):
  do IO<Result<String, Unit>>:
    bend : String <- Tool.env("BEND", "bend")
    Tool.bind(String, Unit, package.upload(release, bend, String.trim(dir)), hash => github.publish(release, hash))

def release.start(+release: Release, newer: Bool) -> IO(Result<String, Unit>):
  match release newer:
    case Release{repo, +commit, previous, +tag, package} True{}:
      Tool.bind(Bool, Unit, tag.check("refs/tags/" ++ tag, commit), missing =>
        Tool.bind(String, Unit, Tool.command("mktemp", ["-d"]), dir =>
          release.upload(Release{repo, commit, previous, tag, package}, dir)))
    case _ False{}: Tool.fail(Unit, "This commit already has the latest release")

def release.plan(+repo: String, +commit: String, bump: String, +previous: String) -> IO(Result<String, Unit>):
  Tool.then(String, Unit, version.from_tag(previous, bump), +version =>
    Tool.bind(String, Unit, Tool.command("git", ["rev-parse", "--verify", "refs/tags/" ++ previous ++ "^{commit}"]), +base =>
      Tool.bind(String, Unit, Tool.command("git", ["merge-base", "--is-ancestor", String.trim(base), commit]), out =>
        release.start(Release{repo, commit, previous, "v" ++ version, "bend-ta@" ++ version ++ ".0"},
          Bool.not(String.eq(String.trim(base), commit))))))

def release.commit(+repo: String, +commit: String, bump: String, verified: Bool) -> IO(Result<String, Unit>):
  match verified:
    case False{}: Tool.fail(Unit, "The checkout must match the tested release commit")
    case True{}:
      Tool.bind(String, Unit, Tool.command("gh", ["release", "view", "--repo", repo, "--json", "tagName", "--jq", ".tagName"]),
        out => release.plan(repo, commit, bump, String.trim(out)))

def run.checked(repo: String, +commit: String, bump: String, valid: Bool) -> IO(Result<String, Unit>):
  match valid:
    case False{}: Tool.fail(Unit, "Run the Release workflow from main")
    case True{}:
      Tool.bind(String, Unit, Tool.command("git", ["rev-parse", "HEAD"]), out =>
        release.commit(repo, commit, bump, String.eq(String.trim(out), commit)))

def run(bump: String) -> IO(Result<String, Unit>):
  do IO<Result<String, Unit>>:
    ref : String <- Tool.env("GITHUB_REF", "")
    +repo : String <- Tool.env("GITHUB_REPOSITORY", "")
    commit : String <- Tool.env("GITHUB_SHA", "")
    run.checked(repo, commit, bump, Bool.and(String.eq(ref, "refs/heads/main"), Bool.not(String.is_empty(repo))))

def run.args(args: List<String>) -> IO(Result<String, Unit>):
  match args:
    case program <> "patch" <> Nil{}: run("patch")
    case program <> "minor" <> Nil{}: run("minor")
    case _: Tool.fail(Unit, "Usage: bend scripts/release.bend -- patch|minor")

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    result : Result<String, Unit> <- run.args(args)
    Tool.finish(result)
