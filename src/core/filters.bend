import Base

type Coefficients<-N: Data> is Data:
  Coefficients{input: N, first: N, second: N}

type State<-N: Data> is Data:
  State{kind: U32, coefficients: Coefficients<N>, started: Bool, x1: N, x2: N, y1: N, y2: N}

def two_pole(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~sin: N -> N, ~sqrt: N -> N, +kind: U32, period: U32, pi: N
) -> Coefficients<N>:
  +one = from_u32(1)
  +two = from_u32(2)
  +s = sin(div(pi, from_u32(period)))
  +b = mul(div(from_u32(2415), from_u32(1000)), mul(mul(two, s), s))
  +alpha = sub(sqrt(add(mul(b, b), mul(two, b))), b)
  +om = sub(one, alpha)
  +base = Bool.pick(N, U32.is_eq(kind, 2), sub(one, div(alpha, two)), alpha)
  +square = mul(base, base)
  Coefficients{Bool.pick(N, U32.is_zero(kind), div(square, from_u32(4)), square), mul(two, om), sub(from_u32(0), mul(om, om))}

def coefficients(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~sin: N -> N, ~cos: N -> N, ~sqrt: N -> N, ~atan: N -> N, +kind: U32, +period: U32, delta: N
) -> Coefficients<N>:
  match kind:
    case 3:
      +one = from_u32(1)
      +two = from_u32(2)
      +pi = mul(from_u32(4), atan(one))
      +p = from_u32(period)
      +w = div(mul(two, pi), p)
      +t = div(mul(mul(from_u32(4), pi), delta), p)
      +alpha = div(sub(one, sin(t)), cos(t))
      Coefficients{div(sub(one, alpha), two), mul(cos(w), add(one, alpha)), sub(from_u32(0), alpha)}
    case 4:
      +one = from_u32(1)
      +two = from_u32(2)
      +h = div(mul(from_u32(4), atan(one)), from_u32(period))
      +s = sin(h)
      +alpha = div(mul(mul(two, s), sub(cos(h), s)), sub(one, mul(mul(two, s), s)))
      Coefficients{sub(one, div(alpha, two)), sub(one, alpha), from_u32(0)}
    case _:
      two_pole(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~sin, ~sqrt, kind, period, mul(from_u32(4), atan(from_u32(1))))

def init(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N,
  ~sin: N -> N, ~cos: N -> N, ~sqrt: N -> N, ~atan: N -> N, +kind: U32, period: U32, delta: N
) -> State<N>:
  +zero = from_u32(0)
  State{kind, coefficients(~N, ~from_u32, ~add, ~sub, ~mul, ~div, ~sin, ~cos, ~sqrt, ~atan, kind, period, delta), False{}, zero, zero, zero, zero}

def numerator(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  kind: U32, x: N, x1: N, x2: N
) -> N:
  match kind:
    case 0: add(add(x, mul(from_u32(2), x1)), x2)
    case 1: x
    case 2: add(sub(x, mul(from_u32(2), x1)), x2)
    case 3: sub(x, x2)
    case _: sub(x, x1)

def step(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  +kind: U32, coefficients: Coefficients<N>, +x1: N, x2: N, +y1: N, y2: N, +x: N
) -> State<N> & Maybe<&2, N>:
  match coefficients:
    case Coefficients{+input, +first, +second}:
      +y = add(mul(first, y1), add(mul(second, y2), mul(input, numerator(~N, ~from_u32, ~add, ~sub, ~mul, kind, x, x1, x2))))
      (State{kind, Coefficients{input, first, second}, True{}, x, x1, y, y1}, Some{y})

def next(
  ~N: Data, ~from_u32: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  state: State<N>, +x: N
) -> State<N> & Maybe<&2, N>:
  match state:
    case State{+kind, coefficients, False{}, x1, x2, y1, y2}:
      +seed = Bool.pick(N, U32.is_lt(kind, 2), x, from_u32(0))
      step(~N, ~from_u32, ~add, ~sub, ~mul, kind, coefficients, x, x, seed, seed, x)
    case State{kind, coefficients, True{}, x1, x2, y1, y2}:
      step(~N, ~from_u32, ~add, ~sub, ~mul, kind, coefficients, x1, x2, y1, y2, x)
