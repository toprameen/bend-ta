import Base
import ./window.bend as Window
import ./ma.bend as Ma
import ./parameters.bend as Params
import ./momentum_smooth.bend as Smooth
import ./momentum_composite.bend as Composite

type Delayed<-N: Data> is Type:
  Delayed{skip: U32, average: Ma.State<N>}


type Macd<-N: Data> is Type:
  Macd{fast: Delayed<N>, slow: Delayed<N>, signal: Ma.State<N>}


type Leg<-N: Data> is Type:
  Leg{skip: U32, state: Composite.RocLeg<N>}


type Kst<-N: Data> is Type:
  Kst{legs: List<&1, Leg<N>>, signal: Ma.State<N>}


def delayed.emit(~N: Data, result: Ma.State<N> & Maybe<&2, N>) -> Delayed<N> & Maybe<&2, N>:
  match result:
    case (average, value): (Delayed{0, average}, value)


def delayed.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Delayed<N>, price: N) -> Delayed<N> & Maybe<&2, N>:
  match state:
    case Delayed{0, average}: delayed.emit(~N, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, average, price))
    case Delayed{skip, average}: (Delayed{U32.sub(skip, 1), average}, None{})


def macd.created(~N: Data, +fast_skip: U32, +slow_skip: U32, fast: Result<&2, &1, Params.Error, Ma.State<N>>, slow: Result<&2, &1, Params.Error, Ma.State<N>>, signal: Result<&2, &1, Params.Error, Ma.State<N>>) -> Result<&2, &1, Params.Error, Macd<N>>:
  match fast slow signal:
    case Done{fast} Done{slow} Done{signal}: Done{Macd{Delayed{fast_skip, fast}, Delayed{slow_skip, slow}, signal}}
    case _ _ _: Fail{Params.InvalidParameter{}}


def macd.sorted(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Params.Error, Ma.State<N>>, +fast: U32, +ftype: U32, +slow: U32, +stype: U32, signal: U32, sigtype: U32) -> Result<&2, &1, Params.Error, Macd<N>>:
  +f = Ma.lookback(fast, ftype)
  +s = Ma.lookback(slow, stype)
  +longest = U32.max(f, s)
  macd.created(~N, U32.sub(longest, f), U32.sub(longest, s), make(fast, ftype), make(slow, stype), make(signal, sigtype))


def macd.init(~N: Data, ~make: U32 -> U32 -> Result<&2, &1, Params.Error, Ma.State<N>>, +fast: U32, +ftype: U32, +slow: U32, +stype: U32, signal: U32, sigtype: U32) -> Result<&2, &1, Params.Error, Macd<N>>:
  macd.sorted(~N, ~make, U32.min(fast, slow), Bool.pick(U32, U32.is_le(fast, slow), ftype, stype), U32.max(fast, slow), Bool.pick(U32, U32.is_le(fast, slow), stype, ftype), signal, sigtype)


def macd.signal(~N: Data, ~sub: N -> N -> N, fast: Delayed<N>, slow: Delayed<N>, +line: N, result: Ma.State<N> & Maybe<&2, N>) -> Macd<N> & Maybe<&2, Smooth.MACDValue<N>>:
  match result:
    case (signal, None{}): (Macd{fast, slow, signal}, None{})
    case (signal, Some{+value}): (Macd{fast, slow, signal}, Some{Smooth.MACDValue{line, value, sub(line, value)}})


def macd.slow(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, fast: Delayed<N>, signal: Ma.State<N>, result: Delayed<N> & Maybe<&2, N>, a: Maybe<&2, N>) -> Macd<N> & Maybe<&2, Smooth.MACDValue<N>>:
  match result a:
    case (slow, Some{b}) Some{x}:
      +line = sub(x, b)
      macd.signal(~N, ~sub, fast, slow, line, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, line))
    case (slow, _) _: (Macd{fast, slow, signal}, None{})


def macd.fast(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, slow: Delayed<N>, signal: Ma.State<N>, price: N, result: Delayed<N> & Maybe<&2, N>) -> Macd<N> & Maybe<&2, Smooth.MACDValue<N>>:
  match result:
    case (fast, a): macd.slow(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, fast, signal, delayed.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, slow, price), a)


def macd.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, state: Macd<N>, +price: N) -> Macd<N> & Maybe<&2, Smooth.MACDValue<N>>:
  match state:
    case Macd{fast, slow, signal}: macd.fast(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, slow, signal, price, delayed.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, fast, price))


def kst.average(~N: Data, longest: U32, +roc: U32, lookback: U32, +weight: N, average: Result<&2, &1, Params.Error, Ma.State<N>>, result: Result<&2, &1, Params.Error, Kst<N>>) -> Result<&2, &1, Params.Error, Kst<N>>:
  match average result:
    case Done{average} Done{Kst{legs, signal}}: Done{Kst{Leg{U32.sub(longest, U32.add(roc, lookback)), Composite.RocLeg{Window.init(~N, roc, Ma.buffer_depth(roc), weight), average, weight}} <> legs, signal}}
    case _ _: Fail{Params.InvalidParameter{}}


def kst.leg(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Params.Error, Ma.State<N>>, +longest: U32, +roc: U32, +period: U32, +kind: U32, weight: U32, result: Result<&2, &1, Params.Error, Kst<N>>) -> Result<&2, &1, Params.Error, Kst<N>>:
  kst.average(~N, longest, roc, Ma.lookback(period, kind), from(weight), make(period, kind), result)


def kst.signal.init(~N: Data, result: Result<&2, &1, Params.Error, Ma.State<N>>) -> Result<&2, &1, Params.Error, Kst<N>>:
  match result:
    case Done{signal}: Done{Kst{Nil{}, signal}}
    case Fail{e}: Fail{e}


def kst.init(~N: Data, ~from: U32 -> N, ~make: U32 -> U32 -> Result<&2, &1, Params.Error, Ma.State<N>>, +r1: U32, +r2: U32, +r3: U32, +r4: U32, +m1: U32, +m2: U32, +m3: U32, +m4: U32, signal: U32, +kind: U32, sigtype: U32) -> Result<&2, &1, Params.Error, Kst<N>>:
  +longest = U32.max(U32.max(U32.add(r1, Ma.lookback(m1, kind)), U32.add(r2, Ma.lookback(m2, kind))), U32.max(U32.add(r3, Ma.lookback(m3, kind)), U32.add(r4, Ma.lookback(m4, kind))))
  kst.leg(~N, ~from, ~make, longest, r1, m1, kind, 1, kst.leg(~N, ~from, ~make, longest, r2, m2, kind, 2, kst.leg(~N, ~from, ~make, longest, r3, m3, kind, 3, kst.leg(~N, ~from, ~make, longest, r4, m4, kind, 4, kst.signal.init(~N, make(signal, sigtype))))))


def leg.emit(~N: Data, result: Composite.RocLeg<N> & Maybe<&2, N>) -> Leg<N> & Maybe<&2, N>:
  match result:
    case (state, value): (Leg{0, state}, value)


def leg.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, state: Leg<N>, price: N) -> Leg<N> & Maybe<&2, N>:
  match state:
    case Leg{0, state}: leg.emit(~N, Composite.roc.step(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, state, price))
    case Leg{skip, state}: (Leg{U32.sub(skip, 1), state}, None{})


def kst.walk.finish(~N: Data, leg: Leg<N>, result: List<&1, Leg<N>> & Maybe<&2, N>) -> List<&1, Leg<N>> & Maybe<&2, N>:
  match result:
    case (rest, value): (leg <> rest, value)


def kst.walk.read(~N: Data, ~add: N -> N -> N, rest: List<&1, Leg<N>>, sum: Maybe<&2, N>, result: Leg<N> & Maybe<&2, N>, continue: List<&1, Leg<N>> -> Maybe<&2, N> -> List<&1, Leg<N>> & Maybe<&2, N>) -> List<&1, Leg<N>> & Maybe<&2, N>:
  match result:
    case (leg, value): kst.walk.finish(~N, leg, continue(rest, Composite.roc.total(~N, ~add, sum, value)))


def kst.walk(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, fuel: Nat, legs: List<&1, Leg<N>>, +price: N, sum: Maybe<&2, N>) -> List<&1, Leg<N>> & Maybe<&2, N>:
  match fuel legs:
    case 0n _: (legs, sum)
    case 1n+fuel Nil{}: (Nil{}, sum)
    case 1n+fuel leg <> rest: kst.walk.read(~N, ~add, rest, sum, leg.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, leg, price), legs => total => kst.walk(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, fuel, legs, price, total))


def kst.signal(~N: Data, legs: List<&1, Leg<N>>, +line: N, result: Ma.State<N> & Maybe<&2, N>) -> Kst<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (signal, None{}): (Kst{legs, signal}, None{})
    case (signal, Some{value}): (Kst{legs, signal}, Some{Smooth.Lines{line, value}})


def kst.legs(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~atan: N -> N, signal: Ma.State<N>, result: List<&1, Leg<N>> & Maybe<&2, N>) -> Kst<N> & Maybe<&2, Smooth.Lines<N>>:
  match result:
    case (legs, None{}): (Kst{legs, signal}, None{})
    case (legs, Some{+line}): kst.signal(~N, legs, line, Ma.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, line))


def kst.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~le: N -> N -> Bool, ~eq: N -> N -> Bool, ~atan: N -> N, state: Kst<N>, price: N) -> Kst<N> & Maybe<&2, Smooth.Lines<N>>:
  match state:
    case Kst{legs, signal}: kst.legs(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~atan, signal, kst.walk(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~le, ~eq, ~atan, 4n, legs, price, Some{from(0)}))
