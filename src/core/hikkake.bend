import Base
import ./bar.bend as Bar
import ./candle.bend as Candle
import ./patterns.bend as Pattern

type Frame<-N: Data> is Data:
  Frame{bar: Bar.OHLC<N>, near: Maybe<&2, N>}

type History<-N: Data> is Data:
  History{size: U32, one: Frame<N>, two: Frame<N>, three: Frame<N>}

type Pending<-N: Data> is Data:
  Pending{count: U32, negative: Bool, high: N, low: N}

type State<-N: Data> is Type:
  State{modified: Bool, remaining: U32, near: Candle.State<N>, history: History<N>, pending: Pending<N>}

def init(~N: Data, ~from: U32 -> N, +modified: Bool, +setting: Candle.Setting<N>, depth: Nat) -> State<N>:
  match setting:
    case Candle.Setting{kind, +period, factor}:
      +zero = from(0)
      +frame : Frame<N> = Frame{Bar.OHLC{zero, zero, zero, zero}, None{}}
      State{modified, Bool.pick(U32, modified, U32.add(U32.max(period, 1), 5), 5), Candle.init(~N, ~from, setting, U32.max(period, 1), depth), History{0, frame, frame, frame}, Pending{0, False{}, zero, zero}}

def inside(~N: Data, ~lt: N -> N -> Bool, inner: Bar.OHLC<N>, outer: Bar.OHLC<N>) -> Bool:
  match inner outer:
    case Bar.OHLC{o, high, low, c} Bar.OHLC{a, h, l, b}: Bool.and(lt(high, h), lt(l, low))

def close.near(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~le: N -> N -> Bool, negative: Bool, frame: Frame<N>) -> Bool:
  match frame:
    case Frame{bar, None{}}: False{}
    case Frame{Bar.OHLC{o, high, low, +close}, Some{+distance}}:
      Bool.pick(Bool, negative, le(sub(high, distance), close), le(close, add(low, distance)))

def detect.if(~N: Data, negative: Bool, high: N, low: N, found: Bool) -> Maybe<&2, Pending<N>>:
  match found:
    case False{}: None{}
    case True{}: Some{Pending{3, negative, high, low}}

def detect.frames(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, +modified: Bool, +size: U32, +high: N, +low: N, +one: Bar.OHLC<N>, +two: Frame<N>, three: Bar.OHLC<N>) -> Maybe<&2, Pending<N>>:
  match one two:
    case Bar.OHLC{a, +h, +l, b} Frame{+second, near}:
      +bull = Bool.and(lt(high, h), lt(low, l))
      +bear = Bool.and(lt(h, high), lt(l, low))
      +negative = Bool.not(bull)
      +base = Bool.and(U32.is_ge(size, 2), Bool.and(inside(~N, ~lt, one, second), Bool.or(bull, bear)))
      +extra = Bool.and(U32.is_ge(size, 3), Bool.and(inside(~N, ~lt, second, three), close.near(~N, ~add, ~sub, ~le, negative, two)))
      detect.if(~N, negative, h, l, Bool.and(base, Bool.or(Bool.not(modified), extra)))

def detect(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, +modified: Bool, history: History<N>, current: Bar.OHLC<N>) -> Maybe<&2, Pending<N>>:
  match history current:
    case History{+size, Frame{+one, n1}, +two, Frame{three, n3}} Bar.OHLC{o, +high, +low, c}:
      detect.frames(~N, ~add, ~sub, ~lt, ~le, modified, size, high, low, one, two, three)

def confirm(~N: Data, ~lt: N -> N -> Bool, pending: Pending<N>, bar: Bar.OHLC<N>) -> Bool:
  match pending bar:
    case Pending{count, +negative, high, low} Bar.OHLC{o, h, l, +close}:
      Bool.and(U32.is_gt(count, 0), Bool.pick(Bool, negative, lt(close, low), lt(high, close)))

def countdown(~N: Data, pending: Pending<N>) -> Pending<N>:
  match pending:
    case Pending{+count, negative, high, low}: Pending{U32.sub(count, Bool.pick(U32, U32.is_zero(count), 0, 1)), negative, high, low}

def result.confirmed(~N: Data, +pending: Pending<N>, confirmed: Bool) -> Pending<N> & Pattern.Signal:
  match pending confirmed:
    case Pending{count, negative, high, low} True{}: (Pending{0, negative, high, low}, Pattern.Signal{negative, 200})
    case pending False{}: (countdown(~N, pending), Pattern.Signal{False{}, 0})

def result.stale(~N: Data, ~lt: N -> N -> Bool, +pending: Pending<N>, bar: Bar.OHLC<N>) -> Pending<N> & Pattern.Signal:
  result.confirmed(~N, pending, confirm(~N, ~lt, pending, bar))

def result(~N: Data, ~lt: N -> N -> Bool, pending: Pending<N>, bar: Bar.OHLC<N>, detection: Maybe<&2, Pending<N>>) -> Pending<N> & Pattern.Signal:
  match detection:
    case Some{+fresh}:
      match fresh:
        case Pending{count, negative, high, low}: (fresh, Pattern.Signal{negative, 100})
    case None{}: result.stale(~N, ~lt, pending, bar)

def emit(~N: Data, modified: Bool, +remaining: U32, near: Candle.State<N>, history: History<N>, result: Pending<N> & Pattern.Signal) -> State<N> & Maybe<&2, Pattern.Signal>:
  match result:
    case (pending, signal): (State{modified, U32.sub(remaining, Bool.pick(U32, U32.is_zero(remaining), 0, 1)), near, history, pending}, Bool.pick(Maybe<&2, Pattern.Signal>, U32.is_zero(remaining), Some{signal}, None{}))

def advanced(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, +modified: Bool, remaining: U32, +history: History<N>, pending: Pending<N>, +bar: Bar.OHLC<N>, nearr: Candle.State<N> & Maybe<&2, N>) -> State<N> & Maybe<&2, Pattern.Signal>:
  match history nearr:
    case History{size, one, two, three} Tuple{near, threshold}: emit(~N, modified, remaining, near, History{U32.min(U32.add(size, 1), 3), Frame{bar, threshold}, one, two}, result(~N, ~lt, pending, bar, detect(~N, ~add, ~sub, ~lt, ~le, modified, history, bar)))

def next(~N: Data, ~from: U32 -> N, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N, ~div: N -> N -> N, ~abs: N -> N, ~min: N -> N -> N, ~max: N -> N -> N, ~lt: N -> N -> Bool, ~le: N -> N -> Bool, state: State<N>, +bar: Bar.OHLC<N>) -> State<N> & Maybe<&2, Pattern.Signal>:
  match state:
    case State{modified, remaining, near, history, pending}: advanced(~N, ~add, ~sub, ~lt, ~le, modified, remaining, history, pending, bar, Candle.next(~N, ~from, ~add, ~sub, ~mul, ~div, ~abs, ~min, ~max, near, bar))
