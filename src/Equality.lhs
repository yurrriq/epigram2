\section{Equality}

%if False

> {-# OPTIONS_GHC -F -pgmF she #-}
> {-# LANGUAGE TypeOperators, GADTs #-}

> module Equality where

%endif

\question{Do the Formation/Introduction/\ldots names make sense?}
\question{How to handle the eliminators?}
\question{Computational behavior of eqGreen and coe?}
\question{Relation with Con, Prf, and Green?}

Introduction rules:

\begin{prooftree}
\AxiomC{|Set :>: y0|}
\noLine
\UnaryInfC{|y0 :>: t0|}
\AxiomC{|Set :>: y1|}
\noLine
\UnaryInfC{|y1 :>: t1|}
\RightLabel{Prop-intro-5}
\BinaryInfC{|Prop :>: EqBlue (y0 :>: t0) (y1 :>: t1)|}
\end{prooftree}

\question{What is the role of Con below?}

\begin{prooftree}
\AxiomC{|Prf eqGreen(y0,t0,y1,t1) :>: p|}
\RightLabel{Prf-intro-2}
\UnaryInfC{|Prf EqBlue(y0 :>: t0) (y1 :>: t1) :>: Con p|}
\end{prooftree}

Elimination rules:

\begin{prooftree}
\AxiomC{|Set :>: y0|}
\noLine
\UnaryInfC{|y0 :>: t0|}
\AxiomC{|Set :>: y1|}
\noLine
\UnaryInfC{|y1 :>: t1|}
\RightLabel{eqGreen-elim}
\BinaryInfC{|Prop :>: eqGreen(y0,t0,y1,t1)|}
\end{prooftree}

With some computational behavior:

< eqGreen(Set, C t0, Set, C t1) :-> {- $\wedge_{(t0',t1') \in [t0,t1]}$ -} eqGreen(canTy t0', t0', canTy t0', t1')
< eqGreen(Pi s1 t1, f1, Pi s2 t2, f2) :-> All s1 (\x1 -> All s2 (\x2 ->
<                                         Imp (EqBlue(s1 :>: x1) (s2 :>: x2))
<                                             (eqGreen(t1 x1, f1 x1, t2 x2, f2 x2))))
< eqGreen(...) :-> (...) -- defined by aspect OpRunEqGreen

\begin{prooftree}
\AxiomC{|Set :>: x|}
\AxiomC{|Set :>: y|}
\AxiomC{|x :>: s|}
\noLine
\TrinaryInfC{|Prf EqBlue (Set :>: x) (Set :>: y) :>: q|}
\RightLabel{coe-elim}
\UnaryInfC{|y :>: coe(x,y,q,s)|}
\end{prooftree}

With some computational behavior:

< coe(C x, C y, q, s) :-> Absurd -- if x and y of distinct arity
< coe(Pi x1 y1, Pi x2 y2, q, f) :-> \s1 -> coe( y2 s2, y1 s1, q s2 s1 q2, f s2)
<     where  s2 = coe(x2, x1, fst q, s1)
<            q2 = coh(x2, x1, fst q, s1)
< coe(...) = (...) -- defined by the aspect Coerce

\begin{prooftree}
\AxiomC{|Set :>: x|}
\AxiomC{|Set :>: y|}
\AxiomC{|x :>: s|}
\noLine
\TrinaryInfC{|Prf EqBlue (Set :>: x) (Set :>: y) :>: q|}
\RightLabel{coh-elim}
\UnaryInfC{|Prf EqBlue (x :>: s) (y :>: coe(x,y,q,s)) :>: coh(x,y,q,s)|}
\end{prooftree}

With no computational behavior.

> import -> CanConstructors where
>   EqBlue :: (t :>: t) -> (t :>: t) -> Can t

> import -> CanPats where
>   pattern EQBLUE p q = C (EqBlue p q)

> import -> SugarTactics where
>     eqBlueTac p q = can $ EqBlue p q

> import -> TraverseCan where
>   traverse f (EqBlue (pty :>: p) (qty :>: q)) =
>     (|EqBlue (|(:>:) (f pty) (f p)|) (|(:>:) (f qty) (f q)|)|)

> import -> CanPretty where
>   prettyCan (EqBlue (y0 :>: t0) (y1 :>: t1)) = parens (
>       parens (pretty t0 <+> text ":" <+> pretty y0) <+> text "=="
>       <+> parens (pretty t1 <+> text ":" <+> pretty y1))

> import -> CanTyRules where
>   canTy chev (Prop :>: EqBlue (y0 :>: t0) (y1 :>: t1)) = do
>     y0y0v@(y0 :=>: y0v) <- chev (SET :>: y0)
>     t0t0v@(t0 :=>: t0v) <- chev (y0v :>: t0)
>     y1y1v@(y1 :=>: y1v) <- chev (SET :>: y1)
>     t1t1v@(t1 :=>: t1v) <- chev (y1v :>: t1)
>     return $ EqBlue (y0y0v :>: t0t0v) (y1y1v :>: t1t1v)
>   canTy chev (Prf (EQBLUE (y0 :>: t0) (y1 :>: t1)) :>: Con p) = do
>     ppv@(p :=>: pv) <- chev (PRF (eqGreen @@ [y0, t0, y1, t1]) :>: p)
>     return $ Con ppv

> import -> ElimConstructors where
>  Sym :: Elim t 

> import -> ElimComputation where
>   VOID $$ Sym = VOID
>   (PAIR a b) $$ Sym = PAIR (a $$ Sym) (b $$ Sym)
>   L body $$ Sym = eval [.f.
>                         (L $ "" :. [.y. 
>                          (L $ "" :. [.x.
>                           (L $ "" :. [.q.
>                             N $ V f :$ (A $ NV x)
>                                     :$ (A $ NV y) 
>                                     :$ (A $ N $ V q :$ Sym) 
>                                     :$ Sym  ])])])] $ 
>                         B0 :< (L body)
>   

> import -> ElimTyRules where
>   elimTy chev (_ :<: Prf (EQBLUE (t0 :>: x0) (t1 :>: x1))) Out = return (Out, PRF (eqGreen @@ [t0 , x0 , t1 , x1]))

> import -> OpCode where
>   eqGreen = Op { opName = "eqGreen"
>                , opArity = 4
>                , opTy = opty
>                , opRun = opRunEqGreen
>                , opSimp = \_ _ -> empty
>                } where
>                opty chev [y0,t0,y1,t1] = do
>                    (y0 :=>: y0v) <- chev (SET :>: y0)
>                    (t0 :=>: t0v) <- chev (y0v :>: t0)
>                    (y1 :=>: y1v) <- chev (SET :>: y1)
>                    (t1 :=>: t1v) <- chev (y1v :>: t1)
>                    return ([ y0 :=>: y0v
>                            , t0 :=>: t0v
>                            , y1 :=>: y1v
>                            , t1 :=>: t1v ]
>                           , PROP)
>                opty _  _             = throwError' "eqGreen: invalid arguments."

>   coe = Op { opName = "coe"
>            , opArity = 4
>            , opTy = opty
>            , opRun = oprun
>            , opSimp = \_ _ -> empty
>            } where
>            opty chev [x,y,q,s] = do
>              (x :=>: xv) <- chev (SET :>: x)
>              (y :=>: yv) <- chev (SET :>: y)
>              (q :=>: qv) <- chev (PRF (EQBLUE (SET :>: xv) (SET :>: yv)) :>: q)
>              (s :=>: sv) <- chev (xv :>: s)
>              return ([ x :=>: xv
>                      , y :=>: yv
>                      , q :=>: qv
>                      , s :=>: sv ]
>                     , yv)
>            oprun :: [VAL] -> Either NEU VAL
>            oprun [C x,C y,q,s] = Right $ case halfZip x y of
>              Nothing  -> ABSURD
>              Just fxy -> coerce fxy q s
>            oprun [N x,y,q,s] = Left x
>            oprun [x,N y,q,s] = Left y
>            oprun _ = undefined

> import -> Operators where
>   eqGreen :
>   coe :

> import -> AxCode where
>   coh = [("Axiom",0),("coh",0)] := (DECL :<: cohType) where
>     cohType = trustMe (SET :>: cohTypeTac)
>     cohTypeTac = prfTac $
>       allTac setTac $ \ x ->
>       allTac setTac $ \ y ->
>       allTac
>         (prfTac (eqBlueTac (setTac :>: var x) (setTac :>: var y))) $ \ q ->
>       allTac (var x) $ \ s ->
>       eqBlueTac (var x :>: var s)
>         (var y :>: useOp coe [var x, var y, var q, var s] done)
>   refl = [("Axiom",0),("refl",0)] := (DECL :<: reflType) where
>     reflType = trustMe (SET :>: reflTypeTac)
>     reflTypeTac = prfTac $
>       allTac setTac $ \s ->
>       allTac (var s) $ \x ->
>       eqBlueTac (var s :>: var x) (var s :>: var x)

> import -> Axioms where
>   ("coh", coh) :
>   ("refl", refl) :
