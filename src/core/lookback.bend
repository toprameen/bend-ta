import Base
import ./parameters.bend as Parameters

def checked(valid: Bool, count: U32) -> Result<&2, &2, Parameters.Error, U32>:
  match valid:
    case False{}: Fail{Parameters.InvalidParameter{}}
    case True{}: Done{count}
