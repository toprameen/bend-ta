import Base

type Error is Data:
  InvalidPeriod{}

type Config is Data:
  Config{period: U32, depth: Nat}

# A power-of-two capacity that fits either a one-word or two-word element
# within Bend's block-class limit. Allocation still depends on available RAM.
def max_period() -> U32:
  1073741824

def depth.go(fuel: Nat, +period: U32, +size: U32, depth: Nat, done: Bool) -> Nat:
  match fuel done:
    case 0n _:
      depth
    case 1n+rest True{}:
      depth
    case 1n+rest False{}:
      +next = U32.mul(size, 2)
      depth.go(rest, period, next, 1n+depth, U32.is_ge(next, period))

def make.if(+period: U32, valid: Bool) -> Result<&2, &2, Error, Config>:
  match valid:
    case False{}:
      Fail{InvalidPeriod{}}
    case True{}:
      Done{Config{period, depth.go(30n, period, 1, 0n, U32.is_le(period, 1))}}

def make(+period: U32) -> Result<&2, &2, Error, Config>:
  make.if(period, Bool.and(U32.is_gt(period, 0), U32.is_le(period, max_period())))
