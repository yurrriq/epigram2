\section{Desc}

%if False

> {-# OPTIONS_GHC -F -pgmF she #-}
> {-# LANGUAGE TypeOperators, GADTs, KindSignatures,
>     TypeSynonymInstances, FlexibleInstances, ScopedTypeVariables #-}

> module Desc where

%endif

> import -> CanConstructors where
>   Desc   :: Can t
>   Mu     :: t -> Can t
>   Done   :: Can t
>   Arg    :: t -> t -> Can t
>   Ind    :: t -> t -> Can t

> import -> TraverseCan where
>   traverse _ Desc       = (|Desc|)
>   traverse f (Mu x)     = (|Mu (f x)|)
>   traverse _ Done       = (|Done|)
>   traverse f (Arg x y)  = (|Arg (f x) (f y)|)
>   traverse f (Ind x y)  = (|Ind (f x) (f y)|)

> import -> CanPats where
>   pattern DESC     = C Desc
>   pattern MU x     = C (Mu x)
>   pattern DONE     = C Done
>   pattern ARG x y  = C (Arg x y)
>   pattern IND x y  = C (Ind x y)

> import -> CanTyRules where
>   canTy _ (Set :>: Desc)     = return Desc
>   canTy chev (Set :>: Mu x)     = do
>     xxv@(x :=>: xv) <- chev (DESC :>: x)
>     return $ Mu xxv
>   canTy _ (Desc :>: Done)    = return Done
>   canTy chev (Desc :>: Arg x y) = do
>     xxv@(x :=>: xv) <- chev (SET :>: x)
>     yyv@(y :=>: yv) <- chev (ARR xv DESC :>: y)
>     return $ Arg xxv yyv
>   canTy chev (Desc :>: Ind x y) = do
>     xxv@(x :=>: xv) <- chev (SET :>: x)
>     yyv@(y :=>: yv) <- chev (DESC :>: y)
>     return $ Ind xxv yyv
>   canTy chev (Mu x :>: Con y) = do
>     yyv@(y :=>: yv) <- chev (descOp @@ [x, MU x] :>: y)
>     return $ Con yyv

> import -> ElimTyRules where
>   elimTy chev (_ :<: Mu d) Out = return (Out, descOp @@ [d , MU d])


> import -> OpCode where
>   descOp :: Op
>   descOp = Op
>     { opName = "descOp"
>     , opArity = 2
>     , opTy = dOpTy
>     , opRun = dOpRun
>     } where
>       dOpTy chev [x,y] = do
>                  (x :=>: xv) <- chev (DESC :>: x)
>                  (y :=>: yv) <- chev (SET :>: y)
>                  return $ ([ x :=>: xv
>                            , y :=>: yv ]
>                           , SET)
>       dOpRun :: [VAL] -> Either NEU VAL
>       dOpRun [DONE,y]    = Right UNIT
>       dOpRun [ARG x y,z] = Right $ trustMe (opRunArgType :>: opRunArgTac) $$ A x $$ A y $$ A z
>       dOpRun [IND x y,z] = Right $ trustMe (opRunIndType :>: opRunIndTac) $$ A x $$ A y $$ A z
>       dOpRun [N x,_]     = Left x
>
>       opRunTypeTac arg = arrTac arg
>                                 (arrTac (can Set)
>                                         (can Set))
>       opRunArgType = trustMe (SET :>: opRunArgTypeTac) 
>       opRunArgTypeTac = can $ Pi (can Set)
>                                  (lambda $ \x ->
>                                   opRunTypeTac (arrTac (use x done)
>                                                        (can Desc)))
>       opRunArgTac = lambda $ \x ->
>                     lambda $ \f ->
>                     lambda $ \d ->
>                     can $ Sigma (use x done)
>                                 (lambda $ \a ->
>                                  useOp descOp [ use f . apply (A (use a done)) $ done
>                                               , use d done ] done)
>
>       opRunIndType = trustMe (SET :>: opRunIndTypeTac)
>       opRunIndTypeTac = arrTac (can Set) 
>                                (opRunTypeTac (can Desc))
>       opRunIndTac = lambda $ \h ->
>                     lambda $ \x ->
>                     lambda $ \d ->
>                     timesTac (arrTac (use h done)
>                                      (use d done))
>                              (useOp descOp [ use x done
>                                            , use d done ] done)




>   boxOp :: Op
>   boxOp = Op
>     { opName = "boxOp"
>     , opArity = 4
>     , opTy = boxOpTy
>     , opRun = boxOpRun
>     } where
>       boxOpTy chev [w,x,y,z] = do
>         (w :=>: wv) <- chev (DESC :>: w)
>         (x :=>: xv) <- chev (SET :>: x)
>         (y :=>: yv) <- chev (ARR xv SET :>: y)
>         (z :=>: zv) <- chev (descOp @@ [wv,xv] :>: z)
>         return ([ w :=>: wv
>                 , x :=>: xv
>                 , y :=>: yv
>                 , z :=>: zv ]
>                , SET)
>       boxOpRun :: [VAL] -> Either NEU VAL
>       boxOpRun [DONE   ,d,p,v] = Right UNIT
>       boxOpRun [ARG a f,d,p,v] = Right $ trustMe (opRunArgType :>: opRunArgTac) 
>                                          $$ A a $$ A f $$ A d $$ A p $$ A v
>       boxOpRun [IND h x,d,p,v] = Right $ trustMe (opRunIndType :>: opRunIndTac)
>                                          $$ A h $$ A x $$ A d $$ A p $$ A v
>       boxOpRun [N x    ,_,_,_] = Left x
>
>       opRunTypeTac arg = can $ Pi (can Set)
>                                   (lambda $ \y ->
>                                    can $ Pi (arrTac (use y done)
>                                                     (can Set))
>                                             (lambda $ \z -> 
>                                              arrTac (useOp descOp [ arg
>                                                                   , use y done ] done)
>                                                     (can Set)))
>       opRunArgType = trustMe (SET :>: opRunArgTypeTac)
>       opRunArgTypeTac = can $ Pi (can Set)
>                                  (lambda $ \x ->
>                                   can $ Pi (arrTac (use x done)
>                                                    (can Desc)) 
>                                            (lambda $ \f ->
>                                             opRunTypeTac (can $ Arg (use x done)
>                                                                     (use f done))))
>       opRunArgTac = lambda $ \a ->
>                     lambda $ \f ->
>                     lambda $ \d ->
>                     lambda $ \p ->
>                     lambda $ \v -> 
>                     useOp boxOp [ use f . apply (A (use v . apply Fst $ done)) $ done
>                                 , use d done 
>                                 , use p done
>                                 , use v . apply Snd $ done ] done
>
>       opRunIndType = trustMe (SET :>: opRunIndTypeTac) 
>       opRunIndTypeTac = can $ Pi (can Set)
>                                  (lambda $ \h ->
>                                   can $ Pi (can Desc)
>                                            (lambda $ \x ->
>                                             opRunTypeTac (can $ Ind (use h done)
>                                                                     (use x done))))
>       opRunIndTac = lambda $ \h ->
>                     lambda $ \x ->
>                     lambda $ \d ->
>                     lambda $ \p ->
>                     lambda $ \v ->
>                     timesTac (can $ Pi (use h done)
>                                        (lambda $ \y -> 
>                                         use p . apply (A (use v . apply Fst . 
>                                                                   apply (A $ use y done) $ done)) $ done))
>                              (useOp boxOp [ use x done
>                                           , use d done
>                                           , use p done
>                                           , use v . apply Snd $ done ] done)


>   mapBoxOp :: Op
>   mapBoxOp = Op
>     { opName = "mapBoxOp"
>     , opArity = 5
>     , opTy = mapBoxOpTy
>     , opRun = mapBoxOpRun
>     } where
>       mapBoxOpTy chev [x,d,bp,p,v] = do 
>           (x :=>: xv) <- chev (DESC :>: x)
>           (d :=>: dv) <- chev (SET :>: d)
>           (bp :=>: bpv) <- chev (ARR dv SET :>: bp)
>           (p :=>: pv) <- chev (C (Pi dv (eval [.bpv. L $ "" :. 
>                                                 [.y. N (V bpv :$ A (NV y))]
>                                               ] $ B0 :< bpv))
>                                 :>: p)
>           (v :=>: vv) <- chev (descOp @@ [xv,dv] :>: v)
>           return ([ x :=>: xv
>                   , d :=>: dv
>                   , bp :=>: bpv
>                   , p :=>: pv
>                   , v :=>: vv ]
>                  , boxOp @@ [xv,dv,bpv,vv])
>       mapBoxOpRun :: [VAL] -> Either NEU VAL
>       mapBoxOpRun [DONE,d,bp,p,v] = Right VOID
>       mapBoxOpRun [ARG a f,d,bp,p,v] = Right $ trustMe (mapBoxArgType :>: mapBoxArgTac) 
>                                                $$ A a $$ A f $$ A d $$ A bp $$ A p $$ A v
>       mapBoxOpRun [IND h x,d,bp,p,v] = Right $ trustMe (mapBoxIndType :>: mapBoxIndTac) 
>                                                $$ A h $$ A x $$ A d $$ A bp $$ A p $$ A v
>       mapBoxOpRun [N x    ,_, _,_,_] = Left x
>
>       mapBoxTypeTac arg = can $ Pi (can Set)
>                                    (lambda $ \d ->
>                                     can $ Pi (arrTac (use d done)
>                                                      (can Set))
>                                              (lambda $ \bp ->
>                                               arrTac (can $ Pi (use d done)
>                                                                (lambda $ \y ->
>                                                                 use bp . 
>                                                                 apply (A (use y done)) $
>                                                                 done))
>                                                      (can $ Pi (useOp descOp [ arg
>                                                                              , use d done ] done)
>                                                                (lambda $ \v ->
>                                                                 useOp boxOp [ arg
>                                                                             , use d done
>                                                                             , use bp done
>                                                                             , use v done] done))))
>       mapBoxIndType = trustMe (SET :>: mapBoxIndTypeTac)
>       mapBoxIndTypeTac = can $ Pi (can Set)
>                                   (lambda $ \h ->
>                                    can $ Pi (can Desc)
>                                             (lambda $ \x ->
>                                              mapBoxTypeTac (can $ Ind (use h done)
>                                                                       (use x done))))
>       mapBoxIndTac = lambda $ \h ->
>                      lambda $ \x ->
>                      lambda $ \d ->
>                      lambda $ \bp ->
>                      lambda $ \p ->
>                      lambda $ \v ->
>                      can $ Pair (lambda $ \y ->
>                                  use p . apply (A (use v .
>                                                   apply Fst .
>                                                   apply (A (use y done)) 
>                                                   $ done)) $ done)
>                                 (useOp mapBoxOp [ use x done
>                                                 , use d done
>                                                 , use bp done
>                                                 , use p done
>                                                 , use v . apply Snd $ done ] done)
>       mapBoxArgType = trustMe (SET :>: mapBoxArgTypeTac)
>       mapBoxArgTypeTac = can $ Pi (can Set)
>                                   (lambda $ \a -> 
>                                    can $ Pi (arrTac (use a done)
>                                                     (can Desc))
>                                             (lambda $ \f -> 
>                                              mapBoxTypeTac (can $ Arg (use a done)
>                                                                       (use f done))))
>       mapBoxArgTac = lambda $ \a ->
>                      lambda $ \f ->
>                      lambda $ \d ->
>                      lambda $ \bp ->
>                      lambda $ \p ->
>                      lambda $ \v ->
>                      useOp mapBoxOp [ use f . apply (A (use v . apply Fst $ done)) $ done
>                                     , use d done
>                                     , use bp done
>                                     , use p done
>                                     , use v . apply Snd $ done ] done

 
>   elimOp :: Op
>   elimOp = Op
>     { opName = "elimOp"
>     , opArity = 4
>     , opTy = elimOpTy
>     , opRun = elimOpRun
>     } where
>       elimOpTy chev [d,bp,p,v] = do
>         (d :=>: dv) <- chev (DESC :>: d)
>         (bp :=>: bpv) <- chev (ARR (MU dv) SET :>: bp)
>         (v :=>: vv) <- chev (MU dv :>: v)
>         (p :=>: pv) <- chev (C (Pi (descOp @@ [dv,MU dv]) 
>                     (eval [.d.bp.v. L $ "" :. [.x. 
>                         ARR (N (boxOp :@ [NV d,MU (NV d),NV bp,NV x]))
>                             (N (V bp :$ A (CON (NV x))))]
>                         ] $ B0 :< dv :< bpv :< vv)) :>: p)
>         return ([ d :=>: dv
>                 , bp :=>: bpv
>                 , p :=>: pv
>                 , v :=>: vv ]
>                 , bpv $$ A vv)
>       elimOpRun :: [VAL] -> Either NEU VAL
>       elimOpRun [d,bp,p,CON v] = Right $ trustMe (elimOpType :>: elimOpTac) 
>                                          $$ A d $$ A bp $$ A p $$ A v
>       elimOpRun [_, _,_,N x] = Left x
>       elimOpType = trustMe (SET :>: elimOpTypeTac)
>       elimOpTypeTac = can $ Pi (can Desc)
>                                (lambda $ \d ->
>                                 can $ Pi (arrTac (can $ Mu (use d done))
>                                                  (can Set))
>                                          (lambda $ \bp ->
>                                           arrTac (can $ Pi (useOp descOp [ use d done
>                                                                          , can $ Mu (use d done) ] done)
>                                                            (lambda $ \x ->
>                                                             arrTac (useOp boxOp [ use d done
>                                                                                 , can $ Mu (use d done)
>                                                                                 , use bp done
>                                                                                 , use x done ] done)
>                                                                    (use bp . apply (A (can $ Con (use x done))) $ done)))
>                                                  (can $ Pi (useOp descOp [ use d done
>                                                                          , can $ Mu (use d done) ] done)
>                                                            (lambda $ \v ->
>                                                             use bp . apply (A $ can $ Con $ use v done) $ done))))
>       elimOpTac = lambda $ \d ->  -- Desc
>                   lambda $ \bp -> -- Mu d -> Set
>                   lambda $ \p ->  -- (x : descOp d (Mu d)) -> (boxOp d (Mu d) bp x) -> bp (Con x)
>                   lambda $ \v ->  -- (v : descOp d (Mu d))
>                   use p . 
>                   apply (A $ use v done) .
>                   apply (A $ useOp mapBoxOp [ use d done
>                                             , can $ Mu (use d done)
>                                             , use bp done
>                                             , lambda $ \x ->
>                                               useOp elimOp [ use d done
>                                                            , use bp done
>                                                            , use p done
>                                                            , use x done ] done 
>                                             , use v done ] done) $
>                   done
