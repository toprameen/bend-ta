import Base

type HL<-N: Data> is Data:
  HL{high: N, low: N}

type HLC<-N: Data> is Data:
  HLC{high: N, low: N, close: N}

type HLV<-N: Data> is Data:
  HLV{high: N, low: N, volume: N}

type CV<-N: Data> is Data:
  CV{close: N, volume: N}

type HLCV<-N: Data> is Data:
  HLCV{high: N, low: N, close: N, volume: N}

type OHLC<-N: Data> is Data:
  OHLC{open: N, high: N, low: N, close: N}

type OHLCV<-N: Data> is Data:
  OHLCV{prices: OHLC<N>, volume: N}

type Direction is Data:
  Up{}
  Down{}

def range(~N: Data, ~sub: N -> N -> N, bar: HL<N>) -> N:
  match bar:
    case HL{high, low}:
      sub(high, low)

def true_range(~N: Data, ~sub: N -> N -> N, ~abs: N -> N, ~max: N -> N -> N, +previous: N, bar: HLC<N>) -> N:
  match bar:
    case HLC{+high, +low, close}:
      max(sub(high, low), max(abs(sub(high, previous)), abs(sub(low, previous))))

def body(~N: Data, ~sub: N -> N -> N, ~abs: N -> N, bar: OHLC<N>) -> N:
  match bar:
    case OHLC{open, high, low, close}:
      abs(sub(close, open))

def upper_shadow(~N: Data, ~sub: N -> N -> N, ~max: N -> N -> N, bar: OHLC<N>) -> N:
  match bar:
    case OHLC{open, high, low, close}:
      sub(high, max(open, close))

def lower_shadow(~N: Data, ~sub: N -> N -> N, ~min: N -> N -> N, bar: OHLC<N>) -> N:
  match bar:
    case OHLC{open, high, low, close}:
      sub(min(open, close), low)

def shadows(~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~min: N -> N -> N, ~max: N -> N -> N, +bar: OHLC<N>) -> N:
  add(upper_shadow(~N, ~sub, ~max, bar), lower_shadow(~N, ~sub, ~min, bar))

def color(~N: Data, ~ge: N -> N -> Bool, bar: OHLC<N>) -> Direction:
  match bar:
    case OHLC{open, high, low, close}:
      Bool.pick(Direction, ge(close, open), Up{}, Down{})

def body_gap_up(~N: Data, ~min: N -> N -> N, ~max: N -> N -> N, ~gt: N -> N -> Bool, current: OHLC<N>, previous: OHLC<N>) -> Bool:
  match current previous:
    case OHLC{open, high, low, close} OHLC{before_open, h, l, before_close}:
      gt(min(open, close), max(before_open, before_close))

def gap_up(~N: Data, ~gt: N -> N -> Bool, current: OHLC<N>, previous: OHLC<N>) -> Bool:
  match current previous:
    case OHLC{open, high, low, close} OHLC{o, before_high, l, c}:
      gt(low, before_high)

def valid(~N: Data, ~finite: N -> Bool, ~le: N -> N -> Bool, bar: OHLC<N>) -> Bool:
  match bar:
    case OHLC{+open, +high, +low, +close}:
      Bool.and(Bool.and(finite(open), finite(high)),
        Bool.and(Bool.and(finite(low), finite(close)),
          Bool.and(Bool.and(le(low, open), le(open, high)), Bool.and(le(low, close), le(close, high)))))
