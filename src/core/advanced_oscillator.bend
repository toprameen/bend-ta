import Base
import ./bar.bend as Bar
import ./window.bend as Window
import ./ma.bend as Ma
import ./ema.bend as Ema
import ./statistics.bend as Stats
import ./momentum.bend as Mom
import ./momentum_window.bend as Box
import ./momentum_smooth.bend as Smooth
import ./momentum_init.bend as Init
import ./parameters.bend as Params

type Double<-N: Data> is Data:
  Double{first: Ema.State<N>, second: Ema.State<N>}


type Smi<-N: Data> is Type:
  Smi{box: Box.Box<N>, numerator: Double<N>, denominator: Double<N>, signal: Ema.State<N>}


type Crsi<-N: Data> is Type:
  Crsi{price_rsi: Mom.RSI<N>, streak_rsi: Mom.RSI<N>, rank: Window.State<N>, previous: Maybe<&2, N>, streak: N}


type Wave<-N: Data> is Type:
  Wave{center: Ema.State<N>, deviation: Ema.State<N>, average: Ema.State<N>, signal: Window.State<N>, previous: Maybe<&2, Smooth.Lines<N>>}


type Cycle<-N: Data> is Type:
  Cycle{box: Box.Box<N>, fraction: N, value: Maybe<&2, N>}


type Stc<-N: Data> is Type:
  Stc{macd: Smooth.Dual<N>, first: Cycle<N>, second: Cycle<N>}


def double.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, slow: U32, fast: U32) -> Double<N>:
  Double{Ema.init(~N, ~from, ~div, slow), Ema.init(~N, ~from, ~div, fast)}


def double.emit(~N: Data, first: Ema.State<N>, result: Ema.State<N> & Maybe<&2, N>) -> Double<N> & Maybe<&2, N>:
  match result:
    case (second, value): (Double{first, second}, value)


def double.first(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, second: Ema.State<N>, result: Ema.State<N> & Maybe<&2, N>) -> Double<N> & Maybe<&2, N>:
  match result:
    case (first, None{}): (Double{first, second}, None{})
    case (first, Some{value}): double.emit(~N, first, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, second, value))


def double.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, state: Double<N>, price: N) -> Double<N> & Maybe<&2, N>:
  match state:
    case Double{first, second}: double.first(~N, ~from, ~add, ~sub, ~mul, ~div, second, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, first, price))


def smi.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +period: U32, +fast: U32, +slow: U32, signal: U32) -> Smi<N>:
  Smi{Box.box.init(~N, ~from, period, Ma.buffer_depth(period)), double.init(~N, ~from, ~div, slow, fast), double.init(~N, ~from, ~div, slow, fast), Ema.init(~N, ~from, ~div, signal)}


def smi.signal(~N: Data, box: Box.Box<N>, numerator: Double<N>, denominator: Double<N>, +line: N, result: Ema.State<N> & Maybe<&2, N>) -> Smi<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (signal, None{}): (Smi{box, numerator, denominator, signal}, None{})
    case (signal, Some{value}): (Smi{box, numerator, denominator, signal}, Some{Smooth.Lines{line, value}})


def smi.denominator(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, box: Box.Box<N>, numerator: Double<N>, signal: Ema.State<N>, result: Double<N> & Maybe<&2, N>, num: Maybe<&2, N>) -> Smi<N> & Maybe<&2, Smooth.Lines<N>>:
  match result num:
    case (denominator, Some{+den}) Some{value}:
      +half = div(den, from(2))
      +line = Bool.pick(N, eq(half, from(0)), from(0), div(mul(from(100), value), half))
      smi.signal(~N, box, numerator, denominator, line, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, signal, line))
    case (denominator, _) None{}: (Smi{box, numerator, denominator, signal}, None{})
    case (denominator, None{}) Some{value}: (Smi{box, numerator, denominator, signal}, None{})


def smi.numerator(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, box: Box.Box<N>, denominator: Double<N>, signal: Ema.State<N>, range: N, result: Double<N> & Maybe<&2, N>) -> Smi<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (numerator, value): smi.denominator(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, box, numerator, signal, double.next(~N, ~from, ~add, ~sub, ~mul, ~div, denominator, range), value)


def smi.box(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, numerator: Double<N>, denominator: Double<N>, signal: Ema.State<N>, result: Box.Box<N> & Maybe<&2, Box.Bounds<N>>) -> Smi<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (box, None{}): (Smi{box, numerator, denominator, signal}, None{})
    case (box, Some{Box.Bounds{size, +high, +low, up, down, close}}): smi.numerator(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, box, denominator, signal, sub(high, low), double.next(~N, ~from, ~add, ~sub, ~mul, ~div, numerator, sub(close, div(add(high, low), from(2)))))


def smi.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~le: N -> N -> Bool, state: Smi<N>, bar: Bar.HLC<N>) -> Smi<N> & Maybe<&2, Smooth.Lines<N>>:
  match state:
    case Smi{box, numerator, denominator, signal}: smi.box(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, numerator, denominator, signal, Box.box.next(~N, ~(x => y => le(y, x)), ~le, box, bar))


def crsi.init(~N: Data, ~from: U32 -> N, period: U32, streak: U32, +rank: U32) -> Crsi<N>:
  Crsi{Mom.rsi.init(~N, ~from, period), Mom.rsi.init(~N, ~from, streak), Window.init(~N, rank, Ma.buffer_depth(rank), from(0)), None{}, from(0)}


def crsi.finish(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~div: N -> N -> N, price_rsi: Mom.RSI<N>, streak_rsi: Mom.RSI<N>, price: N, streak: N, result: Window.State<N> & Maybe<&2, N>, a: Maybe<&2, N>, b: Maybe<&2, N>) -> Crsi<N> & Maybe<&2, N>:
  match result a b:
    case (rank, Some{z}) Some{x} Some{y}: (Crsi{price_rsi, streak_rsi, rank, Some{price}, streak}, Some{div(add(add(x, y), z), from(3))})
    case (rank, _) _ _: (Crsi{price_rsi, streak_rsi, rank, Some{price}, streak}, None{})


def crsi.streak(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, price_rsi: Mom.RSI<N>, rank: Window.State<N>, +price: N, streak: N, roc: N, a: Maybe<&2, N>, result: Mom.RSI<N> & Maybe<&2, N>) -> Crsi<N> & Maybe<&2, N>:
  match result:
    case (streak_rsi, b): crsi.finish(~N, ~from, ~add, ~div, price_rsi, streak_rsi, price, streak, Stats.rank.next(~N, ~from, ~mul, ~div, ~lt, rank, roc), a, b)


def crsi.price(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~eq: N -> N -> Bool, streak_rsi: Mom.RSI<N>, rank: Window.State<N>, +streak: N, +price: N, result: Mom.RSI<N> & Maybe<&2, N>, previous: Maybe<&2, N>) -> Crsi<N> & Maybe<&2, N>:
  match result previous:
    case (price_rsi, a) None{}: (Crsi{price_rsi, streak_rsi, rank, Some{price}, streak}, None{})
    case (price_rsi, a) Some{+old}:
      +next = Bool.pick(N, lt(old, price), add(max(streak, from(0)), from(1)), Bool.pick(N, lt(price, old), sub(sub(from(0), max(sub(from(0), streak), from(0))), from(1)), from(0)))
      +roc = Bool.pick(N, eq(old, from(0)), from(0), div(sub(price, old), old))
      crsi.streak(~N, ~from, ~add, ~mul, ~div, ~lt, price_rsi, rank, price, next, roc, a, Mom.rsi.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~max, ~(x => y => lt(y, x)), streak_rsi, next, False{}))


def crsi.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~eq: N -> N -> Bool, state: Crsi<N>, +price: N) -> Crsi<N> & Maybe<&2, N>:
  match state:
    case Crsi{price_rsi, streak_rsi, rank, previous, streak}: crsi.price(~N, ~from, ~add, ~sub, ~mul, ~div, ~max, ~lt, ~eq, streak_rsi, rank, streak, price, Mom.rsi.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~max, ~(x => y => lt(y, x)), price_rsi, price, False{}), previous)


def wave.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, +channel: U32, average: U32, +signal: U32) -> Wave<N>:
  Wave{Ema.init(~N, ~from, ~div, channel), Ema.init(~N, ~from, ~div, channel), Ema.init(~N, ~from, ~div, average), Window.init(~N, signal, Ma.buffer_depth(signal), from(0)), None{}}


def wave.signal(~N: Data, center: Ema.State<N>, deviation: Ema.State<N>, average: Ema.State<N>, previous: Maybe<&2, Smooth.Lines<N>>, +line: N, result: Window.State<N> & Maybe<&2, N>) -> Wave<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (signal, None{}): (Wave{center, deviation, average, signal, previous}, None{})
    case (signal, Some{value}): (Wave{center, deviation, average, signal, previous}, Some{Smooth.Lines{line, value}})


def wave.average(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, center: Ema.State<N>, deviation: Ema.State<N>, signal: Window.State<N>, previous: Maybe<&2, Smooth.Lines<N>>, result: Ema.State<N> & Maybe<&2, N>) -> Wave<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (average, None{}): (Wave{center, deviation, average, signal, previous}, None{})
    case (average, Some{+line}): wave.signal(~N, center, deviation, average, previous, line, Ma.mean.next(~N, ~from, ~add, ~sub, ~div, signal, line))


def wave.deviation(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, center: Ema.State<N>, average: Ema.State<N>, signal: Window.State<N>, previous: Maybe<&2, Smooth.Lines<N>>, +num: N, result: Ema.State<N> & Maybe<&2, N>) -> Wave<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (deviation, None{}): (Wave{center, deviation, average, signal, previous}, None{})
    case (deviation, Some{value}):
      +den = mul(div(from(15), from(1000)), value)
      +ci = Bool.pick(N, eq(den, from(0)), from(0), div(num, den))
      wave.average(~N, ~from, ~add, ~sub, ~div, center, deviation, signal, previous, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, average, ci))


def wave.gap(~N: Data, ~from: U32 -> N, ~sub: N -> N -> N, ~eq: N -> N -> Bool, +price: N, +value: N, previous: Maybe<&2, Smooth.Lines<N>>) -> N:
  match previous:
    case None{}: sub(price, value)
    case Some{Smooth.Lines{ap, esa}}: Bool.pick(N, Bool.and(eq(price, ap), eq(value, esa)), from(0), sub(price, value))


def wave.center(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, deviation: Ema.State<N>, average: Ema.State<N>, signal: Window.State<N>, previous: Maybe<&2, Smooth.Lines<N>>, +price: N, result: Ema.State<N> & Maybe<&2, N>) -> Wave<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (center, None{}): (Wave{center, deviation, average, signal, previous}, None{})
    case (center, Some{+value}):
      +num = wave.gap(~N, ~from, ~sub, ~eq, price, value, previous)
      wave.deviation(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, center, average, signal, Some{Smooth.Lines{price, value}}, num, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, deviation, abs(num)))


def wave.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, state: Wave<N>, bar: Bar.HLC<N>) -> Wave<N> & Maybe<&2, Smooth.Lines<N>>:
  match state bar:
    case Wave{center, deviation, average, signal, previous} Bar.HLC{high, low, close}:
      +price = div(add(add(high, low), close), from(3))
      wave.center(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~eq, deviation, average, signal, previous, price, Ema.next(~N, ~from, ~add, ~sub, ~mul, ~div, center, price))


def cycle.init(~N: Data, ~from: U32 -> N, +period: U32) -> Cycle<N>:
  Cycle{Box.box.init(~N, ~from, period, Ma.buffer_depth(period)), from(0), None{}}


def cycle.smooth(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~div: N -> N -> N, box: Box.Box<N>, +fraction: N, value: Maybe<&2, N>) -> Cycle<N> & Maybe<&2, N>:
  match value:
    case None{}: (Cycle{box, fraction, Some{fraction}}, Some{fraction})
    case Some{+old}:
      +next = add(old, div(sub(fraction, old), from(2)))
      (Cycle{box, fraction, Some{next}}, Some{next})


def cycle.ready(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, +fraction: N, value: Maybe<&2, N>, result: Box.Box<N> & Maybe<&2, Box.Bounds<N>>) -> Cycle<N> & Maybe<&2, N>:
  match result:
    case (box, None{}): (Cycle{box, fraction, value}, None{})
    case (box, Some{Box.Bounds{size, high, +low, up, down, close}}):
      +range = sub(high, low)
      +frac = Bool.pick(N, eq(range, from(0)), fraction, div(mul(from(100), sub(close, low)), range))
      cycle.smooth(~N, ~from, ~add, ~sub, ~div, box, frac, value)


def cycle.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~le: N -> N -> Bool, state: Cycle<N>, +price: N) -> Cycle<N> & Maybe<&2, N>:
  match state:
    case Cycle{box, fraction, value}: cycle.ready(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, fraction, value, Box.box.next(~N, ~(x => y => le(y, x)), ~le, box, Bar.HLC{price, price, price}))


def stc.created(~N: Data, first: Cycle<N>, second: Cycle<N>, result: Result<&2, &1, Params.Error, Smooth.Dual<N>>) -> Result<&2, &1, Params.Error, Stc<N>>:
  match result:
    case Fail{e}: Fail{e}
    case Done{macd}: Done{Stc{macd, first, second}}


def stc.init(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Params.Error, Ma.State<N>>, +fast: U32, +slow: U32, +cycle: U32) -> Result<&2, &1, Params.Error, Stc<N>>:
  stc.created(~N, cycle.init(~N, ~from, cycle), cycle.init(~N, ~from, cycle), Init.dual(~N, ~from, ~make, U32.min(fast, slow), U32.max(fast, slow), 1, U32.sub(U32.max(fast, slow), U32.min(fast, slow))))


def stc.second(~N: Data, macd: Smooth.Dual<N>, first: Cycle<N>, result: Cycle<N> & Maybe<&2, N>) -> Stc<N> & Maybe<&2, N>:
  match result:
    case (second, value): (Stc{macd, first, second}, value)


def stc.first(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~le: N -> N -> Bool, macd: Smooth.Dual<N>, second: Cycle<N>, result: Cycle<N> & Maybe<&2, N>) -> Stc<N> & Maybe<&2, N>:
  match result:
    case (first, None{}): (Stc{macd, first, second}, None{})
    case (first, Some{value}): stc.second(~N, macd, first, cycle.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, ~le, second, value))


def stc.macd(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~eq: N -> N -> Bool, ~le: N -> N -> Bool, first: Cycle<N>, second: Cycle<N>, result: Smooth.Dual<N> & Maybe<&2, Smooth.SpreadValue<N>>) -> Stc<N> & Maybe<&2, N>:
  match result:
    case (macd, None{}): (Stc{macd, first, second}, None{})
    case (macd, Some{Smooth.SpreadValue{a, b, origin}}): stc.first(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, ~le, macd, second, cycle.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, ~le, first, sub(a, b)))


def stc.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~eq: N -> N -> Bool, ~le: N -> N -> Bool, ~atan: N -> N, state: Stc<N>, price: N) -> Stc<N> & Maybe<&2, N>:
  match state:
    case Stc{macd, first, second}: stc.macd(~N, ~from, ~add, ~sub, ~mul, ~div, ~eq, ~le, first, second, Smooth.dual.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, macd, price))
