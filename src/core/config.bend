import Base

type Error is Data:
  InvalidPeriod{}

type Config is Data:
  Config{period: U32, depth: Nat}

# A power-of-two capacity that fits either a one-word or two-word element
# within Bend's block-class limit. Allocation still depends on available RAM.
def max_period() -> U32:
  1073741824

def depth(+period: U32) -> Nat:
  U32.log2(U32.sub(U32.mul(period, 2), 1))

def make.if(+period: U32, valid: Bool) -> Result<&2, &2, Error, Config>:
  match valid:
    case False{}:
      Fail{InvalidPeriod{}}
    case True{}:
      Done{Config{period, depth(period)}}

def make(+period: U32) -> Result<&2, &2, Error, Config>:
  make.if(period, Bool.and(U32.is_gt(period, 0), U32.is_le(period, max_period())))
