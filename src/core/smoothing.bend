import Base

def ema_step(
  ~N: Data, ~add: N -> N -> N, ~sub: N -> N -> N, ~mul: N -> N -> N,
  alpha: N, +previous: N, price: N
) -> N:
  add(previous, mul(alpha, sub(price, previous)))
