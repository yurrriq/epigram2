[ f
    [ \ x : Set ->
      G1 := ? : Set ;
    ] G1 : Set ;
  g
    [ \ x : Set ->
      \ y : Set ->
      G2 := ? : Set ;
    ] G2 : Set ;
  h := ? : Set -> Set -> Set ;
  h2 := ? : (Set -> Set) -> Set ;
  h3 := ? : Set -> (Set -> Set) -> Set ;
  h4 := ? : (Set -> Set -> Set) -> Set ;
  h5 := ? : (Set -> Set) -> Set -> Set ;
  h6 := ? : ((Set -> Set) -> Set) -> Set ;
  A := Enum ['a 'b] : Set ;
  a := ? : Set ;
  P := a == a : Prop ;
  G := ? : :- P ;
  k
    [ h
        [ \ x : Set ->
          h
            [ \ y : Set ->
            ] :- x == y -> Set : Set ;
        ] Pi Set h : Set ;
    ] ? : Pi Set h ;
  B
    [ h
        [ \ x : Set ->
        ] x -> Set : Set ;
    ] Sig Set h : Set ;
  y := [Set , f] : B ;
  C
    [ h
        [ \ x : Set ->
        ] Sig (Set ; Set ;) : Set ;
    ] Sig Set h : Set ;
  z := [Set Set Set] : C ;
]
show state ;