import Base

type Error is Data:
  InvalidParameter{}

def period(+value: U32) -> Bool:
  Bool.and(U32.is_gt(value, 0), U32.is_le(value, 100000))

def periods(values: List<&2, U32>) -> Bool:
  match values:
    case Nil{}: True{}
    case h <> t: Bool.and(period(h), periods(t))
