import Base

type Error is Data:
  InvalidPeriod{}

type Config is Data:
  Config{period: U32, depth: Nat}

# Bend caps array depth plus log2(words per element) at 31, leaving depth 30
# for two-word elements.
def max_period() -> U32:
  1073741824

def depth(+period: U32) -> Nat:
  U32.log2(U32.sub(U32.mul(period, 2), 1))

def valid(+period: U32) -> Bool:
  Bool.and(U32.is_gt(period, 0), U32.is_le(period, max_period()))

def make.if(+period: U32, valid: Bool) -> Result<&2, &2, Error, Config>:
  match valid:
    case False{}:
      Fail{InvalidPeriod{}}
    case True{}:
      Done{Config{period, depth(period)}}

def make(+period: U32) -> Result<&2, &2, Error, Config>:
  make.if(period, valid(period))
