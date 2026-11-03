import Base

type Tree<-A: Data> is Data:
  Leaf{value: A}
  Node{left: Tree<A>, right: Tree<A>}

def array(~A: Data, tree: Tree<A>) -> Array<A>:
  match tree:
    case Leaf{value}:
      ALeaf{value}
    case Node{left, right}:
      ANode{array(~A, left), array(~A, right)}

def capacity(~A: Data, a: Tree<A>) -> U32:
  match a:
    case Leaf{x}:
      1
    case Node{xs, ys}:
      U32.shl(capacity(~A, xs))

law size_preserves:
  for ~A: Data
  for +a: Tree<A>
  {(array(~A, a), capacity(~A, a)) == Array.size(A, array(~A, a)) : Array<A> & U32}

def size_preserves(A, a):
  match a:
    case Leaf{x}:
      {==}
    case Node{xs, ys}:
      %size_preserves(~A, xs) : {(array(~A, Node{xs, ys}), U32.shl(capacity(~A, xs))) == Array.size.node(A, array(~A, ys), _) : Array<A> & U32}
      {==}

def cell_go(~A: Data, a: Tree<A>, n: U32, +i: U32, z: Bool) -> A:
  match a z:
    case Leaf{x} _:
      x
    case Node{xs, ys} True{}:
      +h = U32.shr(n)
      cell_go(~A, xs, h, i, U32.is_lt(i, U32.shr(h)))
    case Node{xs, ys} False{}:
      +h = U32.shr(n)
      +j = U32.sub(i, h)
      cell_go(~A, ys, h, j, U32.is_lt(j, U32.shr(h)))

def put_go(~A: Data, a: Tree<A>, n: U32, +i: U32, value: A, z: Bool) -> Tree<A>:
  match a z:
    case Leaf{x} _:
      Leaf{value}
    case Node{xs, ys} True{}:
      +h = U32.shr(n)
      Node{put_go(~A, xs, h, i, value, U32.is_lt(i, U32.shr(h))), ys}
    case Node{xs, ys} False{}:
      +h = U32.shr(n)
      +j = U32.sub(i, h)
      Node{xs, put_go(~A, ys, h, j, value, U32.is_lt(j, U32.shr(h)))}

law get_go_contents:
  for ~A: Data
  for +a: Tree<A>
  for +n: U32
  for +i: U32
  for +z: Bool
  {(array(~A, a), cell_go(~A, a, n, i, z)) == Array.get.go(A, array(~A, a), n, i, z) : Array<A> & A}

def get_go_contents(A, a, n, i, z):
  match a z:
    case Leaf{x} _:
      {==}
    case Node{xs, ys} True{}:
      %get_go_contents(~A, xs, U32.shr(n), i, U32.is_lt(i, U32.shr(U32.shr(n)))) : {(array(~A, Node{xs, ys}), cell_go(~A, xs, U32.shr(n), i, U32.is_lt(i, U32.shr(U32.shr(n))))) == Array.swap.lo(A, array(~A, ys), _) : Array<A> & A}
      {==}
    case Node{xs, ys} False{}:
      %get_go_contents(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n)))) : {(array(~A, Node{xs, ys}), cell_go(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))))) == Array.swap.hi(A, array(~A, xs), _) : Array<A> & A}
      {==}

law swap_go_contents:
  for ~A: Data
  for +a: Tree<A>
  for +n: U32
  for +i: U32
  for value: A
  for +z: Bool
  {(array(~A, put_go(~A, a, n, i, value, z)), cell_go(~A, a, n, i, z)) == Array.swap.go(A, array(~A, a), n, i, value, z) : Array<A> & A}

def swap_go_contents(A, a, n, i, value, z):
  match a z:
    case Leaf{x} _:
      {==}
    case Node{xs, ys} True{}:
      %swap_go_contents(~A, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n)))) : {(array(~A, Node{put_go(~A, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n)))), ys}), cell_go(~A, xs, U32.shr(n), i, U32.is_lt(i, U32.shr(U32.shr(n))))) == Array.swap.lo(A, array(~A, ys), _) : Array<A> & A}
      {==}
    case Node{xs, ys} False{}:
      %swap_go_contents(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), value, U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n)))) : {(array(~A, Node{xs, put_go(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), value, U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))))}), cell_go(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))))) == Array.swap.hi(A, array(~A, xs), _) : Array<A> & A}
      {==}

def wrapped_index(+n: U32, i: U32) -> U32:
  U32.and(i, U32.sub(n, 1))

law put_go_capacity:
  for ~A: Data
  for +a: Tree<A>
  for +n: U32
  for +i: U32
  for value: A
  for +z: Bool
  {capacity(~A, put_go(~A, a, n, i, value, z)) == capacity(~A, a) : U32}

def put_go_capacity(A, a, n, i, value, z):
  match a z:
    case Leaf{x} _:
      {==}
    case Node{xs, ys} True{}:
      %put_go_capacity(~A, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n)))) : {U32.shl(capacity(~A, put_go(~A, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n)))))) == U32.shl(_) : U32}
      {==}
    case Node{xs, ys} False{}:
      {==}

law cell_put_go:
  for ~A: Data
  for +a: Tree<A>
  for +n: U32
  for +i: U32
  for +value: A
  for +z: Bool
  {cell_go(~A, put_go(~A, a, n, i, value, z), n, i, z) == value : A}

def cell_put_go(A, a, n, i, value, z):
  match a z:
    case Leaf{x} _:
      {==}
    case Node{xs, ys} True{}:
      cell_put_go(~A, xs, U32.shr(n), i, value, U32.is_lt(i, U32.shr(U32.shr(n))))
    case Node{xs, ys} False{}:
      cell_put_go(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), value, U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))))

def cell_at(~A: Data, a: Tree<A>, +n: U32, i: U32) -> A:
  +j = wrapped_index(n, i)
  cell_go(~A, a, n, j, U32.is_lt(j, U32.shr(n)))

def cell(~A: Data, +a: Tree<A>, i: U32) -> A:
  cell_at(~A, a, capacity(~A, a), i)

def put(~A: Data, +a: Tree<A>, i: U32, value: A) -> Tree<A>:
  +n = capacity(~A, a)
  +j = wrapped_index(n, i)
  put_go(~A, a, n, j, value, U32.is_lt(j, U32.shr(n)))

law get_contents:
  for ~A: Data
  for +a: Tree<A>
  for +i: U32
  {(array(~A, a), cell(~A, a, i)) == Array.get(A, array(~A, a), i) : Array<A> & A}

def get_contents(A, a, i):
  %size_preserves(~A, a) : {(array(~A, a), cell(~A, a, i)) == Array.get.at(A, i, _) : Array<A> & A}
  get_go_contents(~A, a, capacity(~A, a), wrapped_index(capacity(~A, a), i), U32.is_lt(wrapped_index(capacity(~A, a), i), U32.shr(capacity(~A, a))))

law swap_contents:
  for ~A: Data
  for +a: Tree<A>
  for +i: U32
  for +value: A
  {(array(~A, put(~A, a, i, value)), cell(~A, a, i)) == Array.swap(A, array(~A, a), i, value) : Array<A> & A}

def swap_contents(A, a, i, value):
  %size_preserves(~A, a) : {(array(~A, put(~A, a, i, value)), cell(~A, a, i)) == Array.swap.at(A, i, value, _) : Array<A> & A}
  swap_go_contents(~A, a, capacity(~A, a), wrapped_index(capacity(~A, a), i), value, U32.is_lt(wrapped_index(capacity(~A, a), i), U32.shr(capacity(~A, a))))

law put_capacity:
  for ~A: Data
  for +a: Tree<A>
  for +i: U32
  for value: A
  {capacity(~A, put(~A, a, i, value)) == capacity(~A, a) : U32}

def put_capacity(A, a, i, value):
  put_go_capacity(~A, a, capacity(~A, a), wrapped_index(capacity(~A, a), i), value, U32.is_lt(wrapped_index(capacity(~A, a), i), U32.shr(capacity(~A, a))))

law cell_put:
  for ~A: Data
  for +a: Tree<A>
  for +i: U32
  for +value: A
  {cell(~A, put(~A, a, i, value), i) == value : A}

def cell_put(A, a, i, value):
  %Equal.sym(U32, capacity(~A, put(~A, a, i, value)), capacity(~A, a), put_capacity(~A, a, i, value)) : {cell_at(~A, put(~A, a, i, value), _, i) == value : A}
  cell_put_go(~A, a, capacity(~A, a), wrapped_index(capacity(~A, a), i), value, U32.is_lt(wrapped_index(capacity(~A, a), i), U32.shr(capacity(~A, a))))

def same_go(~A: Data, a: Tree<A>, n: U32, +i: U32, z: Bool, +j: U32, w: Bool) -> Bool:
  match a z w:
    case Leaf{x} _ _:
      True{}
    case Node{xs, ys} True{} True{}:
      +h = U32.shr(n)
      same_go(~A, xs, h, i, U32.is_lt(i, U32.shr(h)), j, U32.is_lt(j, U32.shr(h)))
    case Node{xs, ys} False{} False{}:
      +h = U32.shr(n)
      +k = U32.sub(i, h)
      +l = U32.sub(j, h)
      same_go(~A, ys, h, k, U32.is_lt(k, U32.shr(h)), l, U32.is_lt(l, U32.shr(h)))
    case Node{xs, ys} _ _:
      False{}

law cell_put_frame_go:
  for ~A: Data
  for +a: Tree<A>
  for +n: U32
  for +i: U32
  for +z: Bool
  for +j: U32
  for +w: Bool
  for +value: A
  {cell_go(~A, put_go(~A, a, n, i, value, z), n, j, w) == Bool.pick(A, same_go(~A, a, n, i, z, j, w), value, cell_go(~A, a, n, j, w)) : A}

def cell_put_frame_go(A, a, n, i, z, j, w, value):
  match a z w:
    case Leaf{x} _ _:
      {==}
    case Node{xs, ys} True{} True{}:
      cell_put_frame_go(~A, xs, U32.shr(n), i, U32.is_lt(i, U32.shr(U32.shr(n))), j, U32.is_lt(j, U32.shr(U32.shr(n))), value)
    case Node{xs, ys} False{} False{}:
      cell_put_frame_go(~A, ys, U32.shr(n), U32.sub(i, U32.shr(n)), U32.is_lt(U32.sub(i, U32.shr(n)), U32.shr(U32.shr(n))), U32.sub(j, U32.shr(n)), U32.is_lt(U32.sub(j, U32.shr(n)), U32.shr(U32.shr(n))), value)
    case Node{xs, ys} True{} False{}:
      {==}
    case Node{xs, ys} False{} True{}:
      {==}

def read(~A: Data, a: Tree<A>, +n: U32, +i: U32) -> A:
  cell_go(~A, a, n, i, U32.is_lt(i, U32.shr(n)))

def write(~A: Data, a: Tree<A>, +n: U32, +i: U32, value: A) -> Tree<A>:
  put_go(~A, a, n, i, value, U32.is_lt(i, U32.shr(n)))
