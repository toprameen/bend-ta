import Base

type Runs<-A: Data> is Data:
  Runs{count: Nat, values: List<&2, List<&2, A>>}

def runs(~A: Data, xs: List<&2, A>, count: Nat, acc: List<&2, List<&2, A>>) -> Runs<A>:
  match xs:
    case Nil{}: Runs{count, List.reverse(&2, List<&2, A>, acc)}
    case x <> rest: runs(~A, rest, 1n+count, (x <> Nil{}) <> acc)

def flatten(~A: Data, xs: List<&2, List<&2, A>>, acc: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}: List.reverse(&2, A, acc)
    case x <> rest: flatten(~A, rest, List.reverse.go(&2, A, x, acc))

def pass(~A: Data, ~le: A -> A -> Bool, +count: Nat, xs: List<&2, List<&2, A>>, acc: List<&2, List<&2, A>>) -> List<&2, List<&2, A>>:
  match xs:
    case Nil{}: List.reverse(&2, List<&2, A>, acc)
    case x <> Nil{}: List.reverse(&2, List<&2, A>, x <> acc)
    case x <> y <> rest: pass(~A, ~le, count, rest, List.merge.go(~A, ~le, count, (Nil{}, x, y)) <> acc)

def go(~A: Data, ~le: A -> A -> Bool, fuel: Nat, +count: Nat, xs: List<&2, List<&2, A>>) -> List<&2, A>:
  match fuel xs:
    case 0n _: flatten(~A, xs, Nil{})
    case 1n+rest Nil{}: Nil{}
    case 1n+rest x <> Nil{}: x
    case 1n+rest x <> y <> tail: go(~A, ~le, rest, count, pass(~A, ~le, count, x <> y <> tail, Nil{}))

def finish(~A: Data, ~le: A -> A -> Bool, state: Runs<A>) -> List<&2, A>:
  match state:
    case Runs{+count, values}: go(~A, ~le, count, count, values)

def sort(~A: Data, ~le: A -> A -> Bool, xs: List<&2, A>) -> List<&2, A>:
  finish(~A, ~le, runs(~A, xs, 0n, Nil{}))
