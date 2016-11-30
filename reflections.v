Module Type Param.
End Param.

Module Theory (P : Param).

Inductive context : Type :=
| ctxempty : context
| ctxextend : context -> type -> context

with type : Type :=
     | Prod : type -> type -> type
     | Id : type -> term -> term -> type
     | Subst : type -> substitution -> type
     | Empty : type
     | Unit : type
     | Bool : type

with term : Type :=
     | var : nat -> term
     | lam : type -> type -> term -> term
     | app : term -> type -> type -> term -> term
     | refl : type -> term -> term
     | subst : term -> substitution -> term
     | exfalso : type -> term -> term
     | unit : term
     | true : term
     | false : term
     | cond : type -> term -> term -> term -> term

with substitution : Type :=
     | sbzero : context -> type -> term -> substitution
     | sbweak : context -> type -> substitution
     | sbshift : context -> type -> substitution -> substitution.

Parameter UIP : type -> type.

Inductive isctx : context -> Type :=
     | CtxEmpty :
         isctx ctxempty

     | CtxExtend :
         forall {G A},
           istype G A -> isctx (ctxextend G A)



with issubst : substitution -> context -> context -> Type :=

     | SubstZero :
         forall {G u A},
           isterm G u A ->
           issubst (sbzero G A u) G (ctxextend G A)

     | SubstWeak :
         forall {G A},
           istype G A ->
           issubst (sbweak G A) (ctxextend G A) G

     | SubstShift :
         forall {G D A sbs},
           issubst sbs G D ->
           istype D A ->
           issubst (sbshift G A sbs) (ctxextend G (Subst A sbs)) (ctxextend D A)



with istype : context -> type -> Type :=

     | TyCtxConv :
         forall {G D A},
           istype G A ->
           eqctx G D ->
           istype D A

     | TySubst :
         forall {G D A sbs},
           issubst sbs G D ->
           istype D A ->
           istype G (Subst A sbs)

     | TyProd :
         forall {G A B},
           istype G A ->
           istype (ctxextend G A) B ->
           istype G (Prod A B)

     | TyId :
         forall {G A u v},
           istype G A ->
           isterm G u A ->
           isterm G v A ->
           istype G (Id A u v)

     | TyEmpty :
         forall {G},
           isctx G ->
           istype G Empty

     | TyUnit :
         forall {G},
           isctx G ->
           istype G Unit

     | TyBool :
         forall {G},
           isctx G ->
           istype G Bool



with isterm : context -> term -> type -> Type :=

     | TermTyConv :
         forall {G A B u},
           isterm G u A ->
           eqtype G A B ->
           isterm G u B

     | TermCtxConv :
         forall {G D A u},
           isterm G u A ->
           eqctx G D ->
           isterm D u A

     | TermSubst :
         forall {G D A u sbs},
           issubst sbs G D ->
           isterm D u A ->
           isterm G (subst u sbs) (Subst A sbs)

     | TermVarZero :
         forall {G A},
           istype G A ->
           isterm (ctxextend G A) (var 0) (Subst A (sbweak G A))

     | TermVarSucc :
         forall {G A B k},
           isterm G (var k) A ->
           istype G B ->
           isterm (ctxextend G B) (var (S k)) (Subst A (sbweak G B))

     | TermAbs :
         forall {G A u B},
           istype G A ->
           isterm (ctxextend G A) u B ->
           isterm G (lam A B u) (Prod A B)

     | TermApp :
         forall {G A B u v},
           istype (ctxextend G A) B ->
           isterm G u (Prod A B) ->
           isterm G v A ->
           isterm G (app u A B v) (Subst B (sbzero G A v))

     | TermRefl :
         forall {G A u},
           isterm G u A ->
           isterm G (refl A u) (Id A u u)

     | TermExfalso :
         forall {G A u},
           istype G A ->
           isterm G u Empty ->
           isterm G (exfalso A u) A

     | TermUnit :
         forall {G},
           isctx G ->
           isterm G unit Unit

     | TermTrue :
         forall {G},
           isctx G ->
           isterm G true Bool

     | TermFalse :
         forall {G},
           isctx G ->
           isterm G false Bool

     | TermCond :
         forall {G C u v w},
           isterm G u Bool ->
           istype (ctxextend G Bool) C ->
           isterm G v (Subst C (sbzero G Bool true)) ->
           isterm G w (Subst C (sbzero G Bool false)) ->
           isterm G
                  (cond C u v w)
                  (Subst C (sbzero G Bool u))



with eqctx : context -> context -> Type :=

     | EqCtxEmpty :
         eqctx ctxempty ctxempty

     | EqCtxExtend :
         forall {G A B},
           eqtype G A B ->
           eqctx (ctxextend G A) (ctxextend G B)



with eqtype : context -> type -> type -> Type :=

     | EqTyCtxConv :
         forall {G D A B},
           eqtype G A B ->
           eqctx G D ->
           eqtype D A B

     | EqTyRefl: forall {G A},
                   istype G A ->
                   eqtype G A A

     | EqTySym :
         forall {G A B},
           eqtype G A B ->
           eqtype G B A

     | EqTyTrans :
         forall {G A B C},
           eqtype G A B ->
           eqtype G B C ->
           eqtype G A C

     | EqTyWeakNat :
         forall {G D A B sbs},
           issubst sbs G D ->
           istype D A ->
           istype D B ->
           eqtype (ctxextend G (Subst A sbs))
                  (Subst (Subst B (sbweak D A)) (sbshift G A sbs))
                  (Subst (Subst B sbs) (sbweak G (Subst A sbs)))

     | EqTyWeakZero :
         forall {G A B u},
           istype G A ->
           isterm G u B ->
           eqtype G (Subst (Subst A (sbweak G B)) (sbzero G B u)) A

     | EqTyShiftZero :
         forall {G D A B v sbs},
           issubst sbs G D ->
           istype (ctxextend D A) B ->
           isterm D v A ->
           eqtype G
                  (Subst (Subst B (sbshift G A sbs)) (sbzero G (Subst A sbs) (subst v sbs)))
                  (Subst (Subst B (sbzero D A v)) sbs)

     | EqTyCongZero :
         forall {G A1 A2 B1 B2 u1 u2},
           eqtype G A1 B1 ->
           eqterm G u1 u2 A1 ->
           eqtype (ctxextend G A1) A2 B2 ->
           eqtype G
                  (Subst A2 (sbzero G A1 u1))
                  (Subst B2 (sbzero G B1 u2))

     | EqTySubstProd :
         forall {G D A B sbs},
           issubst sbs G D ->
           istype D A ->
           istype (ctxextend D A) B ->
           eqtype G
                  (Subst (Prod A B) sbs)
                  (Prod (Subst A sbs) (Subst B (sbshift G A sbs)))

     | EqTySubstId :
         forall {G D A u v sbs},
           issubst sbs G D ->
           istype D A ->
           isterm D u A ->
           isterm D v A ->
           eqtype G
                  (Subst (Id A u v) sbs)
                  (Id (Subst A sbs) (subst u sbs) (subst v sbs))

     | EqTySubstEmpty :
         forall {G D sbs},
           issubst sbs G D ->
           eqtype G
                  (Subst Empty sbs)
                  Empty

     | EqTySubstUnit :
         forall {G D sbs},
           issubst sbs G D ->
           eqtype G
                  (Subst Unit sbs)
                  Unit

     | EqTySubstBool :
         forall {G D sbs},
           issubst sbs G D ->
           eqtype G
                  (Subst Bool sbs)
                  Bool

     | EqTyExfalso :
         forall {G A B u},
           istype G A ->
           istype G B ->
           isterm G u Empty ->
           eqtype G A B

     | CongProd :
         forall {G A1 A2 B1 B2},
           eqtype G A1 B1 ->
           eqtype (ctxextend G A1) A2 B2 ->
           eqtype G (Prod A1 A2) (Prod B1 B2)

     | CongId :
         forall {G A B u1 u2 v1 v2},
           eqtype G A B ->
           eqterm G u1 v1 A ->
           eqterm G u2 v2 A ->
           eqtype G (Id A u1 u2) (Id B v1 v2)

     | CongTySubst :
         forall {G D A B sbs},
           issubst sbs G D ->
           eqtype D A B ->
           eqtype G (Subst A sbs) (Subst B sbs)



with eqterm : context -> term -> term -> type -> Type :=

     | EqTyConv :
         forall {G A B u v},
           eqterm G u v A ->
           eqtype G A B ->
           eqterm G u v B

     | EqCtxConv :
         forall {G D u v A},
           eqterm G u v A ->
           eqctx G D ->
           eqterm D u v A

     | EqRefl :
         forall {G A u},
           isterm G u A ->
           eqterm G u u A

     | EqSym :
         forall {G A u v},
           eqterm G v u A ->
           eqterm G u v A

     | EqTrans :
         forall {G A u v w},
           eqterm G u v A ->
           eqterm G v w A ->
           eqterm G u w A


     | EqSubstWeak :
         forall {G A B k},
           isterm G (var k) A ->
           istype G B ->
           eqterm (ctxextend G B)
                  (subst (var k) (sbweak G B))
                  (var (S k))
                  (Subst A (sbweak G B))


     | EqSubstZeroZero :
         forall {G u A},
           isterm G u A ->
           eqterm G
                  (subst (var 0) (sbzero G A u))
                  u
                  A

     | EqSubstZeroSucc :
         forall {G A B u k},
           isterm G (var k) A ->
           isterm G u B ->
           eqterm G
                  (subst (var (S k)) (sbzero G B u))
                  (var k)
                  A

     | EqSubstShiftZero :
         forall {G D A sbs},
           issubst sbs G D ->
           istype D A ->
           eqterm (ctxextend G (Subst A sbs))
                  (subst (var 0) (sbshift G A sbs))
                  (var 0)
                  (Subst (Subst A sbs) (sbweak G (Subst A sbs)))

     | EqSubstShiftSucc :
         forall { G D A B sbs k },
           issubst sbs G D ->
           isterm D (var k) B ->
           istype D A ->
           eqterm (ctxextend G (Subst A sbs))
                  (subst (var (S k)) (sbshift G A sbs))
                  (subst (subst (var k) sbs) (sbweak G (Subst A sbs)))
                  (Subst (Subst B sbs) (sbweak G (Subst A sbs)))

     | EqSubstAbs :
         forall {G D A B u sbs},
           issubst sbs G D ->
           istype D A ->
           isterm (ctxextend D A) u B ->
           eqterm G
                  (subst (lam A B u) sbs)
                  (lam
                     (Subst A sbs)
                     (Subst B (sbshift G A sbs))
                     (subst u (sbshift G A sbs)))
                  (Prod
                     (Subst A sbs)
                     (Subst B (sbshift G A sbs)))

     | EqSubstApp :
         forall {G D A B u v sbs},
           issubst sbs G D ->
           istype (ctxextend D A) B ->
           isterm D u (Prod A B) ->
           isterm D v A ->
           eqterm G
                  (subst (app u A B v) sbs)
                  (app
                     (subst u sbs)
                     (Subst A sbs)
                     (Subst B (sbshift G A sbs))
                     (subst v sbs))
                  (Subst (Subst B (sbzero D A v)) sbs)

     | EqSubstRefl :
         forall {G D A u sbs},
           issubst sbs G D ->
           isterm D u A ->
           eqterm G
                  (subst (refl A u) sbs)
                  (refl (Subst A sbs) (subst u sbs))
                  (Id (Subst A sbs) (subst u sbs) (subst u sbs))

     | EqSubstExfalso :
         forall {G D A u sbs},
           issubst sbs G D ->
           istype D A ->
           isterm D u Empty ->
           eqterm G
                  (subst (exfalso A u) sbs)
                  (exfalso (Subst A sbs) (subst u sbs))
                  (Subst A sbs)

     | EqSubstUnit :
         forall {G D sbs},
           issubst sbs G D ->
           eqterm G
                  (subst unit sbs)
                  unit
                  Unit

     | EqSubstTrue :
         forall {G D sbs},
           issubst sbs G D ->
           eqterm G
                  (subst true sbs)
                  true
                  Bool

     | EqSubstFalse :
         forall {G D sbs},
           issubst sbs G D ->
           eqterm G
                  (subst false sbs)
                  false
                  Bool

     | EqSubstCond :
         forall {G D C u v w sbs},
           issubst sbs G D ->
           isterm D u Bool ->
           istype (ctxextend D Bool) C ->
           isterm D v (Subst C (sbzero D Bool true)) ->
           isterm D w (Subst C (sbzero D Bool false)) ->
           eqterm G
                  (subst (cond C u v w) sbs)
                  (cond (Subst C (sbshift G Bool sbs))
                        (subst u sbs)
                        (subst v sbs)
                        (subst w sbs))
                  (Subst (Subst C (sbzero D Bool u)) sbs)

     | EqTermExfalso :
         forall {G A u v w},
           istype G A ->
           isterm G u A ->
           isterm G v A ->
           isterm G w Empty ->
           eqterm G u v A

     | UnitEta :
         forall {G u v},
           isterm G u Unit ->
           isterm G v Unit ->
           eqterm G u v Unit

     | EqReflection :
         forall {G A u v w1 w2},
           isterm G w1 (Id A u v) ->
           isterm G w2 (UIP A) ->
           eqterm G u v A

     | ProdBeta :
         forall {G A B u v},
           isterm (ctxextend G A) u B ->
           isterm G v A ->
           eqterm G
                  (app (lam A B u) A B v)
                  (subst u (sbzero G A v))
                  (Subst B (sbzero G A v))

     | CondTrue :
         forall {G C v w},
           istype (ctxextend G Bool) C ->
           isterm G v (Subst C (sbzero G Bool true)) ->
           isterm G w (Subst C (sbzero G Bool false)) ->
           eqterm G
                  (cond C true v w)
                  v
                  (Subst C (sbzero G Bool true))

     | CondFalse :
         forall {G C v w},
           istype (ctxextend G Bool) C ->
           isterm G v (Subst C (sbzero G Bool true)) ->
           isterm G w (Subst C (sbzero G Bool false)) ->
           eqterm G
                  (cond C false v w)
                  w
                  (Subst C (sbzero G Bool false))

     | ProdEta :
         forall {G A B u v},
           isterm G u (Prod A B) ->
           isterm G v (Prod A B) ->
           eqterm (ctxextend G A)
                  (app (subst u (sbweak G A))
                       (Subst A (sbweak G A))
                       (Subst B (sbshift (ctxextend G A) A (sbweak G A)))
                       (var 0))
                  (app (subst v (sbweak G A))
                       (Subst A (sbweak G A))
                       (Subst B (sbshift (ctxextend G A) A (sbweak G A)))
                       (var 0))
                  B ->
           eqterm G u v (Prod A B)

     | CongAbs :
         forall {G A1 A2 B1 B2 u1 u2},
           eqtype G A1 B1 ->
           eqtype (ctxextend G A1) A2 B2 ->
           eqterm (ctxextend G A1) u1 u2 A2 ->
           eqterm G
                  (lam A1 A2 u1)
                  (lam B1 B2 u2)
                  (Prod A1 A2)

     | CongApp :
         forall {G A1 A2 B1 B2 u1 u2 v1 v2},
           eqtype G A1 B1 ->
           eqtype (ctxextend G A1) A2 B2 ->
           eqterm G u1 v1 (Prod A1 A2) ->
           eqterm G u2 v2 A1 ->
           eqterm G
                  (app u1 A1 A2 u2)
                  (app v1 B1 B2 v2)
                  (Subst A2 (sbzero G A1 u2))

     | ConfRefl :
         forall {G u1 u2 A1 A2},
           eqterm G u1 u2 A1 ->
           eqtype G A1 A2 ->
           eqterm G
                  (refl A1 u1)
                  (refl A2 u2)
                  (Id A1 u1 u1)

     (* This rule doesn't seem necessary as subsumed by EqTermexfalso! *)
     (* | CongExfalso : *)
     (*     forall {G A B u v}, *)
     (*       eqtype G A B -> *)
     (*       eqterm G u v Empty -> *)
     (*       eqterm G *)
     (*              (exfalso A u) *)
     (*              (exfalso B v) *)
     (*              A *)

     | CongCond :
         forall {G C1 C2 u1 u2 v1 v2 w1 w2},
           eqterm G u1 u2 Bool ->
           eqtype (ctxextend G Bool) C1 C2 ->
           eqterm G v1 v2 (Subst C1 (sbzero G Bool true)) ->
           eqterm G w1 w2 (Subst C1 (sbzero G Bool false)) ->
           eqterm G
                  (cond C1 u1 v1 w1)
                  (cond C2 u2 v2 w2)
                  (Subst C1 (sbzero G Bool u1))

     | CongTermSubst :
         forall {G D A u1 u2 sbs},
           issubst sbs G D ->
           eqterm D u1 u2 A ->
           eqterm G
                  (subst u1 sbs)
                  (subst u2 sbs)
                  (Subst A sbs).

End Theory.