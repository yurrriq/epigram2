\section{Developments}
\label{sec:developments}

%if False

> {-# OPTIONS_GHC -F -pgmF she #-}
> {-# LANGUAGE FlexibleInstances, TypeOperators, GADTs , StandaloneDeriving #-}

> module ProofState.Structure.Developments where

> import Data.Foldable
> import Data.List
> import Data.Traversable

> import Kit.BwdFwd

> import NameSupply.NameSupply

> import Evidences.Tm

> import Elaboration.ElabMonad

> import DisplayLang.Scheme

%endif


\subsection{The |Dev| data-structure}


A |Dev|elopment is a structure containing entries, some of which may
have their own developments, creating a nested tree-like
structure. Developments can be of different nature: this is indicated
by the |Tip|. A development also keeps a |NameSupply| at hand, for
namespace handling purposes. Initially we had the following
definition:

< type Dev = (Bwd Entry, Tip, NameSupply)

but generalised this to allow other |Traversable| functors |f| in
place of |Bwd|, and to store a |SuspendState|, giving:

> data Dev f = Dev  {  devEntries       :: f (Entry f)
>                   ,  devTip           :: Tip
>                   ,  devNSupply       :: NameSupply
>                   ,  devSuspendState  :: SuspendState
>                   }

%if False

> deriving instance Show (Dev Fwd)
> deriving instance Show (Dev Bwd)

%endif


\subsubsection{|Tip|}

Let us review the different kind of Developments available. The first
kind is a |Module|. A module is a development that cannot have a type
or value. It simply packs up some other developments. 

A development can also be an |Unknown| term of a given type -- the
type being presented both as a term and as a value (for performance
purposes). This is a typical case of \emph{development}: we are
currently building an unknown satisfying the given type.

Finally, a development can be finalised, in which case it is
|Defined|: it has built a term satisfying the given type.

\pierre{What about |Suspended|?}

> data Tip
>   = Module
>   | Unknown (INTM :=>: TY)
>   | Suspended (INTM :=>: TY) EProb
>   | Defined INTM (INTM :=>: TY)
>   deriving Show


\subsubsection{|Entry|}
\label{sec:developments_entry}

As mentionned above, a |Dev| is a kind of tree. The branches are
introduced by the container |f (Entry f)| where |f| is Traversable,
typically a backward list. 

An |Entry| leaves a choice of shape for the branches. Indeed, it can
either be:

\begin{itemize}

\item an |Entity| with a |REF|, the last component of its |Name|
(playing the role of a cache, for performance reasons), and the term
representation of its type, or

\item a module, ie. a |Name| associated with a |Dev| that has no type
or value

\end{itemize}

> data Traversable f => Entry f
>   =  E REF (String, Int) (Entity f) INTM
>   |  M Name (Dev f)

In the Module case, we have already tied the knot, by defining |M|
with a sub-development. In the Entity case, we give yet another choice
of shape, thanks to the |Entity f| constructor. This constructor is
defined in the next section.

Typically, we work with developments that use backwards lists, hence
|f| is |Bwd|:

> type Entries = Bwd (Entry Bwd)


%if False

> instance Show (Entry Bwd) where
>     show (E ref xn e t) = intercalate " " ["E", show ref, show xn, show e, show t]
>     show (M n d) = intercalate " " ["M", show n, show d]
> instance Show (Entry Fwd) where
>     show (E ref xn e t) = intercalate " " ["E", show ref, show xn, show e, show t]
>     show (M n d) = intercalate " " ["M", show n, show d]

%endif

\begin{danger}[Name caching]

We have mentionned above that an Entity |E| caches the last component
of its |Name| in the |(String, Int)| field. Indeed, grabing that
information asks for traversing the whole |Name| up to the last
element:

> lastName :: REF -> (String, Int)
> lastName (n := _) = last n

As we will need it quite frequently for display purposes, we extract
it once and for all with |lastName| and later rely on the cached version.

\end{danger}

\subsubsection{|Entity|}

An |Entity| is gendered: it can either be a |Boy| or a |Girl|. A
|Girl| can have children, that is sub-developments, whereas a |Boy|
cannot. 

> data Traversable f => Entity f
>   =  Boy   BoyKind
>   |  Girl  GirlKind (Dev f)


\paragraph{Girls for definitions:}

A |Girl| represents a \emph{definition}, with a (possibly empty)
development of sub-objects. The |Tip| of this sub-development will
either be of |Unknown| or |Defined| kind. \pierre{Can the Tip be
|Suspended|? I suspect so.}

A programming problem is a special kind of |Girl|: it follows a type
|Scheme| (Section~\ref{sec:display-scheme}), the high-level type of
the function we are implementing.

> data GirlKind = LETG |  PROG (Scheme INTM)

%if False

> instance Show GirlKind where
>     show LETG = "LETG"
>     show (PROG _) = "PROG"

%endif


\paragraph{Boys for parameters:}

A |Boy| represents a parameter (either a $\lambda$, $\forall$ or $\Pi$
abstraction), which scopes over all following entries and the
definitions (if any) in the enclosing development.

> data BoyKind = LAMB | ALAB | PIB deriving (Show, Eq)


%if False

> instance Show (Entity Bwd) where
>     show (Boy k) = "Boy " ++ show k
>     show (Girl k d) = "Girl " ++ show k ++ " " ++ show d

> instance Show (Entity Fwd) where
>     show (Boy k) = "Boy " ++ show k
>     show (Girl k d) = "Girl " ++ show k ++ " " ++ show d 

%endif

We often need to turn the sequence of boys (parameters) under which we
work into the argument spine of a \(\lambda\)-lifted definition:

> boySpine :: Entries -> Spine {TT} REF
> boySpine = foldMap boy where
>   boy :: Entry Bwd -> Spine {TT} REF
>   boy (E r _ (Boy _) _)  = [A (N (P r))]
>   boy _                  = []

> boyREFs :: Entries -> [REF]
> boyREFs = foldMap boy where
>   boy :: Entry Bwd -> [REF]
>   boy (E r _ (Boy _) _)  = [r]
>   boy _                  = []



\subsubsection{Suspension states}

Girls may have suspended elaboration processes attached, indicated by a
|Suspended| tip. These may be stable or unstable. For efficiency in the
scheduler, each development stores the state of its least stable child.

> data SuspendState = SuspendUnstable | SuspendStable | SuspendNone
>   deriving (Eq, Show, Enum, Ord)



\subsection{Manipulating an |Entry|}

In the following, we define a handful of functions which are quite
handy, yet not grandiose. This section can be skipped on a first
reading.

We sometimes wish to determine whether an entry is a |Boy|:

> isBoy :: Traversable f => Entry f -> Bool
> isBoy (E _ _ (Boy _) _)  = True
> isBoy _                  = False

> entryREF :: Traversable f => Entry f -> Maybe REF
> entryREF (E r _ _ _)  = Just r
> entryREF (M _ _)      = Nothing

Given an |Entry|, a natural operation is to extract its
sub-developments. This works for girls and modules, but will not for
boys.

> entryDev :: Traversable f => Entry f -> Maybe (Dev f)
> entryDev (E _ _ (Boy _) _)          = Nothing
> entryDev (E _ _ (Girl _ d) _)       = Just d
> entryDev (M _ d)                    = Just d

For display purposes, we often ask the last name or the whole name of
an |Entry|:

> entryLastName :: Traversable f => Entry f -> (String, Int)
> entryLastName (E _ xn _ _)  = xn
> entryLastName (M n _)       = last n
>
> entryName :: Traversable f => Entry f -> Name
> entryName (E (n := _) _ _ _)  = n
> entryName (M n _)             = n

Some girls have |Scheme|s, and we can extract them thus:

> kindScheme :: GirlKind -> Maybe (Scheme INTM)
> kindScheme LETG        = Nothing
> kindScheme (PROG sch)  = Just sch
>
> entryScheme :: Traversable f => Entry f -> Maybe (Scheme INTM)
> entryScheme (E _ _ (Girl k _) _)     = kindScheme k
> entryScheme _                        = Nothing

The |entryCoerce| function is quite a thing. When defining |Dev|, we
have been picky in letting any Traversable |f| be the carrier of the
|f (Entry f)|. As shown in Section~\ref{sec:proof_context}, we
sometimes need to jump from one Traversable |f| to another Traversable
|g|. In this example, we jump from a |NewsyFwd| -- a |Fwd| list -- to
some |Entries| -- a |Bwd| list.

Changing the type of the carrier is possible for boys, in which case
we return a |Right entry|. It is not possible for girls and modules,
in which case we return an unchanged |Left dev|.

> entryCoerce ::  (Traversable f, Traversable g) => 
>                 Entry f -> Either (Dev f) (Entry g)
> entryCoerce (E ref  xn  (Boy k)       ty)      = Right $ E ref xn (Boy k) ty
> entryCoerce (E _    _   (Girl _ dev)  _)       = Left dev
> entryCoerce (M _    dev)                       = Left dev

We can extract the |SuspendState| from an entry, noting that boys do not have
children so cannot contain suspended elaboration processes.

> entrySuspendState :: Traversable f => Entry f -> SuspendState
> entrySuspendState e = case entryDev e of
>     Just dev  -> devSuspendState dev
>     Nothing   -> SuspendNone


Finally, we can compare entities for equality by comparing their
names.

> instance Traversable f => Eq (Entry f) where
>     e1 == e2 = entryName e1 == entryName e2
