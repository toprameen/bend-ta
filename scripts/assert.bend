import Base

def check(message: String, passed: Bool) -> IO(Unit):
  match passed:
    case True{}: IO.pure(Unit, Unit{})
    case False{}: IO.die(Unit, 1, message)

def list(~A: Data, ~eq: A -> A -> Bool, actual: List<&2, A>, expected: List<&2, A>) -> Bool:
  match actual expected:
    case Nil{} Nil{}: True{}
    case x <> xs y <> ys: Bool.and(eq(x, y), list(~A, ~eq, xs, ys))
    case _ _: False{}

def maybe(~A: Data, ~eq: A -> A -> Bool, actual: Maybe<&2, A>, expected: Maybe<&2, A>) -> Bool:
  match actual expected:
    case None{} None{}: True{}
    case Some{x} Some{y}: eq(x, y)
    case _ _: False{}

def series(~A: Data, ~eq: A -> A -> Bool, actual: List<&2, Maybe<&2, A>>, expected: List<&2, Maybe<&2, A>>) -> Bool:
  list(~Maybe<&2, A>, ~maybe(~A, ~eq), actual, expected)

def batch(~E: Data, ~A: Data, ~eq: A -> A -> Bool, actual: Result<&2, &2, E, List<&2, Maybe<&2, A>>>, expected: List<&2, Maybe<&2, A>>) -> Bool:
  match actual:
    case Fail{error}: False{}
    case Done{values}: series(~A, ~eq, values, expected)
