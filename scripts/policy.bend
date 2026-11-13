import Base

def suffixes(choices: List<&2, String>, +file: String) -> Bool:
  match choices:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(String.ends_with(file, h), suffixes(t, file))

def allowed(+file: String) -> Bool:
  Bool.and(Bool.not(Bool.or(String.eq(file, "package.json"), String.ends_with(file, "/package.json"))),
    Bool.or(suffixes([".bend", ".md", ".yml", ".yaml", ".json", ".csv", ".tsv", ".txt"], file),
      List.contains(~String, ~String.eq, [".gitignore", ".gitattributes", ".editorconfig", "LICENSE", "NOTICE"], file)))

def source_entry(file: String) -> Bool:
  Bool.not(String.eq(file, "LAWS.bend"))

def proof_files(+files: List<&2, String>) -> Bool:
  Bool.and(List.contains(~String, ~String.eq, files, "LAWS.bend"),
    List.contains(~String, ~String.eq, files, "PROOF.bend"))

type Scanner is Data:
  Scanner{mode: U32, escaped: Bool, word: String, pending_import: Bool, clean: Bool}

def pending(word: String, previous: Bool) -> Bool:
  match word:
    case SNil{}:
      previous
    case SCon{h, t}:
      String.eq(String.reverse(SCon{h, t}), "import")

def whitespace(+code: U32) -> Bool:
  Bool.or(Bool.or(U32.is_eq(code, 32), Bool.and(U32.is_ge(code, 9), U32.is_le(code, 13))),
    Bool.or(Bool.or(U32.is_eq(code, 160), U32.is_eq(code, 5760)),
      Bool.or(Bool.and(U32.is_ge(code, 8192), U32.is_le(code, 8202)),
        Bool.or(Bool.or(U32.is_eq(code, 8232), U32.is_eq(code, 8233)),
          Bool.or(Bool.or(U32.is_eq(code, 8239), U32.is_eq(code, 8287)),
            Bool.or(U32.is_eq(code, 12288), U32.is_eq(code, 65279)))))))

def classify.other(+c: Char) -> U32:
  Bool.pick(U32, Bool.or(Bool.or(Char.is_alpha(c), Char.is_digit(c)), Bool.or(Char.is_eq(c, '_'), Char.is_eq(c, '.'))),
    0, Bool.pick(U32, whitespace(Char.to_u32(c)), 4, 5))

def classify(c: Char) -> U32:
  match c:
    case '#': 1
    case '"': 2
    case Chr{39}: 3
    case other: classify.other(other)

def code(c: Char, +word: String, old_pending: Bool, clean: Bool, kind: U32) -> Scanner:
  match kind:
    case 0:
      Scanner{0, False{}, SCon{c, word}, False{}, clean}
    case 1:
      Scanner{1, False{}, "", pending(word, old_pending), clean}
    case 2:
      Scanner{2, False{}, "", False{}, Bool.and(clean, Bool.not(pending(word, old_pending)))}
    case 3:
      Scanner{3, False{}, "", False{}, clean}
    case 4:
      Scanner{0, False{}, "", pending(word, old_pending), clean}
    case _:
      Scanner{0, False{}, "", False{}, clean}

def quote.close(mode: U32, clean: Bool, closes: Bool) -> Scanner:
  Scanner{Bool.pick(U32, closes, 0, mode), False{}, "", False{}, clean}

def quote.character(+mode: U32, clean: Bool, character: U32) -> Scanner:
  match character:
    case 92:
      Scanner{mode, True{}, "", False{}, clean}
    case 34:
      quote.close(mode, clean, U32.is_eq(mode, 2))
    case 39:
      quote.close(mode, clean, U32.is_eq(mode, 3))
    case _:
      Scanner{mode, False{}, "", False{}, clean}

def quoted(c: Char, mode: U32, escaped: Bool, clean: Bool) -> Scanner:
  match escaped:
    case True{}:
      Scanner{mode, False{}, "", False{}, clean}
    case False{}:
      quote.character(mode, clean, Char.to_u32(c))

def step(+c: Char, state: Scanner) -> Scanner:
  match state:
    case Scanner{0, escaped, word, pending, clean}:
      code(c, word, pending, clean, classify(c))
    case Scanner{1, escaped, word, pending, clean}:
      Scanner{Bool.pick(U32, Char.is_eq(c, '\n'), 0, 1), False{}, "", pending, clean}
    case Scanner{3, escaped, word, pending, clean}:
      Scanner{Bool.pick(U32, Char.is_eq(c, '\\'), 4, 5), False{}, "", False{}, clean}
    case Scanner{4, escaped, word, pending, clean}:
      Scanner{5, False{}, "", False{}, clean}
    case Scanner{5, escaped, word, pending, clean}:
      quote.close(5, clean, Char.is_eq(c, '\''))
    case Scanner{mode, escaped, word, pending, clean}:
      quoted(c, mode, escaped, clean)

def result(state: Scanner) -> Bool:
  match state:
    case Scanner{mode, escaped, word, pending, clean}:
      clean

def scan(source: String, state: Scanner) -> Bool:
  match source:
    case SNil{}:
      result(state)
    case SCon{h, t}:
      scan(t, step(h, state))

def bend_source(source: String) -> Bool:
  scan(source, Scanner{0, False{}, "", False{}, True{}})
