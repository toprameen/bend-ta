import Base
import ./bar.bend as Bar
import ./volatility.bend as Volatility

type McGinley<-N: Data> is Data:
  McGinley{period: U32, seen: U32, previous: Maybe<&2, N>}


type Bands<-N: Data> is Data:
  Bands{upper: N, lower: N, close: N, up: Bool}


type Supertrend<-N: Data> is Data:
  Supertrend{atr: Volatility.Atr<N>, multiplier: N, bands: Maybe<&2, Bands<N>>}


type TrendValue<-N: Data> is Data:
  TrendValue{line: N, direction: Bar.Direction}


type SarConfig<-N: Data> is Data:
  SarConfig{start: N, offset: N, long_init: N, long_step: N, long_max: N, short_init: N, short_step: N, short_max: N, signed: Bool}


type SarLive<-N: Data> is Data:
  SarLive{up: Bool, sar: N, extreme: N, af: N, previous: Bar.HL<N>}


type Sar<-N: Data> is Data:
  Sar{config: SarConfig<N>, first: Maybe<&2, Bar.HL<N>>, live: Maybe<&2, SarLive<N>>}


def mcgd.init(~N: Data, period: U32) -> McGinley<N>:
  McGinley{period, 0, None{}}


def mcgd.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~finite: N -> Bool, state: McGinley<N>, +price: N) -> McGinley<N> & Maybe<&2, N>:
  match state:
    case McGinley{+period, seen, None{}}: (McGinley{period, 1, Some{price}}, None{})
    case McGinley{+period, +seen, Some{+previous}}:
      +ratio = div(price, previous)
      +square = mul(ratio, ratio)
      +candidate = add(previous, div(sub(price, previous), mul(from(period), mul(square, square))))
      +value = Bool.pick(N, finite(candidate), candidate, previous)
      +count = U32.min(period, U32.add(seen, 1))
      (McGinley{period, count, Some{value}}, Bool.pick(Maybe<&2, N>, U32.is_eq(count, period), Some{value}, None{}))


def supertrend.init(~N: Data, ~from: U32 -> N, ~div: N -> N -> N, period: U32, multiplier: N) -> Supertrend<N>:
  Supertrend{Volatility.atr.init(~N, ~from, ~div, period), multiplier, None{}}


def supertrend.bands(~N: Data, ~lt: N -> N -> Bool, +upper: N, +lower: N, +close: N, before: Maybe<&2, Bands<N>>) -> Bands<N>:
  match before:
    case None{}: Bands{upper, lower, close, True{}}
    case Some{Bands{+old_upper, +old_lower, +old_close, +up}}:
      +u = Bool.pick(N, Bool.or(lt(upper, old_upper), lt(old_upper, old_close)), upper, old_upper)
      +l = Bool.pick(N, Bool.or(lt(old_lower, lower), lt(old_close, old_lower)), lower, old_lower)
      +direction = Bool.pick(Bool, up, Bool.not(lt(close, l)), lt(u, close))
      Bands{u, l, close, direction}


def supertrend.emit(~N: Data, atr: Volatility.Atr<N>, multiplier: N, bands: Bands<N>) -> Supertrend<N> & Maybe<&2, TrendValue<N>>:
  match bands:
    case Bands{+upper, +lower, close, +up}: (Supertrend{atr, multiplier, Some{Bands{upper, lower, close, up}}}, Some{TrendValue{Bool.pick(N, up, lower, upper), Bool.pick(Bar.Direction, up, Bar.Up{}, Bar.Down{})}})


def supertrend.banded(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, +multiplier: N, bands: Maybe<&2, Bands<N>>, atr: Volatility.Atr<N>, value: N, bar: Bar.HLC<N>) -> Supertrend<N> & Maybe<&2, TrendValue<N>>:
  match bar:
    case Bar.HLC{high, low, +close}:
      +mid = div(add(high, low), from(2))
      +width = mul(multiplier, value)
      supertrend.emit(~N, atr, multiplier, supertrend.bands(~N, ~lt, add(mid, width), sub(mid, width), close, bands))


def supertrend.atr(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~lt: N -> N -> Bool, +multiplier: N, bands: Maybe<&2, Bands<N>>, bar: Bar.HLC<N>, result: Volatility.Atr<N> & Maybe<&2, N>) -> Supertrend<N> & Maybe<&2, TrendValue<N>>:
  match result:
    case (atr, None{}): (Supertrend{atr, multiplier, bands}, None{})
    case (atr, Some{value}): supertrend.banded(~N, ~from, ~add, ~sub, ~mul, ~div, ~lt, multiplier, bands, atr, value, bar)


def supertrend.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, state: Supertrend<N>, +bar: Bar.HLC<N>) -> Supertrend<N> & Maybe<&2, TrendValue<N>>:
  match state:
    case Supertrend{atr, multiplier, bands}: supertrend.atr(~N, ~from, ~add, ~sub, ~mul, ~div, ~lt, multiplier, bands, bar, Volatility.atr.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~max, atr, bar))


def sar.init(~N: Data, ~min: N -> N -> N, start: N, offset: N, +li: N, +ls: N, +lm: N, +si: N, +ss: N, +sm: N, signed: Bool) -> Sar<N>:
  Sar{SarConfig{start, offset, min(li, lm), min(ls, lm), lm, min(si, sm), min(ss, sm), sm, signed}, None{}, None{}}


def sar.advance(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, +config: SarConfig<N>, live: SarLive<N>, +bar: Bar.HL<N>) -> Sar<N> & Maybe<&2, N>:
  match config live bar:
    case SarConfig{start, +offset, +li, +ls, +lm, +si, +ss, +sm, +signed} SarLive{+up, +sar, +ep, +af, Bar.HL{+ph, +pl}} Bar.HL{+high, +low}:
      +reverse = Bool.pick(Bool, up, le(low, sar), le(sar, high))
      +direction = Bool.pick(Bool, reverse, Bool.not(up), up)
      +over = Bool.pick(N, up, max(ep, max(ph, high)), min(ep, min(pl, low)))
      +stop = Bool.pick(N, reverse, Bool.pick(N, up, add(over, mul(over, offset)), sub(over, mul(over, offset))), sar)
      +new_ep = Bool.pick(N, reverse, Bool.pick(N, direction, high, low), Bool.pick(N, direction, max(ep, high), min(ep, low)))
      +new_extreme = Bool.pick(Bool, up, lt(ep, high), lt(low, ep))
      +next_af = Bool.pick(N, reverse, Bool.pick(N, direction, li, si), Bool.pick(N, new_extreme, Bool.pick(N, up, min(lm, add(af, ls)), min(sm, add(af, ss))), af))
      +candidate = add(stop, mul(next_af, sub(new_ep, stop)))
      +next_sar = Bool.pick(N, direction, min(candidate, min(pl, low)), max(candidate, max(ph, high)))
      +output = Bool.pick(N, Bool.and(signed, Bool.not(direction)), sub(from(0), stop), stop)
      (Sar{config, None{}, Some{SarLive{direction, next_sar, new_ep, next_af, bar}}}, Some{output})


def sar.seed(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, ~eq: N -> N -> Bool, ~abs: N -> N, +config: SarConfig<N>, first: Bar.HL<N>, +bar: Bar.HL<N>) -> Sar<N> & Maybe<&2, N>:
  match config first bar:
    case SarConfig{+start, offset, +li, ls, lm, +si, ss, sm, signed} Bar.HL{+ph, +pl} Bar.HL{+high, +low}:
      +down = sub(pl, low)
      +automatic = Bool.not(Bool.and(lt(from(0), down), lt(sub(high, ph), down)))
      +up = Bool.pick(Bool, eq(start, from(0)), automatic, lt(from(0), start))
      +stop = Bool.pick(N, eq(start, from(0)), Bool.pick(N, up, pl, ph), abs(start))
      sar.advance(~N, ~from, ~add, ~sub, ~mul, ~min, ~max, ~le, ~lt, config, SarLive{up, stop, Bool.pick(N, up, high, low), Bool.pick(N, up, li, si), bar}, bar)


def sar.next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~le: N -> N -> Bool, ~lt: N -> N -> Bool, ~eq: N -> N -> Bool, ~abs: N -> N, state: Sar<N>, +bar: Bar.HL<N>) -> Sar<N> & Maybe<&2, N>:
  match state:
    case Sar{config, None{}, None{}}: (Sar{config, Some{bar}, None{}}, None{})
    case Sar{config, Some{first}, None{}}: sar.seed(~N, ~from, ~add, ~sub, ~mul, ~min, ~max, ~le, ~lt, ~eq, ~abs, config, first, bar)
    case Sar{config, first, Some{live}}: sar.advance(~N, ~from, ~add, ~sub, ~mul, ~min, ~max, ~le, ~lt, config, live, bar)
