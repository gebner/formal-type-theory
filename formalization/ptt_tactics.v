(* Tactics and auxiliary lemmas for ptt. *)
Require Import syntax ptt myptt.

(* Some tactic to compose substitutions. *)
Lemma eqtype_subst_left :
  forall {G D E A B sbs sbt},
    issubst sbs G D ->
    issubst sbt D E ->
    istype E A ->
    eqtype G (Subst A (sbcomp sbt sbs)) B ->
    istype G B ->
    isctx G ->
    isctx D ->
    isctx E ->
    istype G (Subst (Subst A sbt) sbs) ->
    istype G (Subst A (sbcomp sbt sbs)) ->
    eqtype G (Subst (Subst A sbt) sbs) B.
Proof.
  intros.
  eapply EqTyTrans ; [
    eapply EqTySubstComp ; eassumption
  | assumption ..
  ].
Defined.

Lemma eqterm_subst_left :
  forall {G D E A u v sbs sbt},
    issubst sbs G D ->
    issubst sbt D E ->
    isterm E u A ->
    istype E A ->
    eqterm G (subst u (sbcomp sbt sbs)) v (Subst A (sbcomp sbt sbs)) ->
    isctx G ->
    isctx D ->
    isctx E ->
    istype G (Subst (Subst A sbt) sbs) ->
    istype G (Subst A (sbcomp sbt sbs)) ->
    isterm G (subst (subst u sbt) sbs) (Subst A (sbcomp sbt sbs)) ->
    isterm G (subst u (sbcomp sbt sbs)) (Subst A (sbcomp sbt sbs)) ->
    isterm G v (Subst A (sbcomp sbt sbs)) ->
    eqterm G (subst (subst u sbt) sbs) v (Subst (Subst A sbt) sbs).
Proof.
  intros.
  assert (hh : eqtype G (Subst A (sbcomp sbt sbs)) (Subst (Subst A sbt) sbs)).
  { apply EqTySym ; [
      assumption ..
    | eapply EqTySubstComp ; eassumption
    ].
  }
  assert (h : eqterm G (subst u (sbcomp sbt sbs)) v (Subst (Subst A sbt) sbs)).
  { eapply EqTyConv ; eassumption. }
  eapply EqTrans.
  - eapply EqTyConv.
    + eapply EqSubstComp ; eassumption.
    + apply EqTySym ; [
        assumption ..
      | eapply EqTySubstComp ; eassumption
      ].
    + assumption.
    + assumption.
    + assumption.
    + assumption.
    + assumption.
  - assumption.
  - assumption.
  - assumption.
  - eapply TermTyConv ; eassumption.
  - eapply TermTyConv ; eassumption.
  - eapply TermTyConv ; eassumption.
Defined.

Ltac compsubst1 :=
  match goal with
  | |- eqtype ?G (Subst (Subst ?A ?sbt) ?sbs) ?B =>
    eapply eqtype_subst_left
  | |- eqtype ?G ?A (Subst (Subst ?B ?sbt) ?sbs) =>
    eapply EqTySym ; try eapply eqtype_subst_left
  | |- eqterm ?G (subst (subst ?u ?sbt) ?sbs) ?v (Subst (Subst ?A ?sbt) ?sbs) =>
    eapply eqterm_subst_left
  | |- eqterm ?G ?u (subst (subst ?v ?sbt) ?sbs) (Subst (Subst ?A ?sbt) ?sbs) =>
    eapply EqSym ; try eapply eqterm_subst_left
  | |- eqterm ?G (subst (subst ?u ?sbt) ?sbs) ?v ?A =>
    eapply EqTyConv ; [
      try eapply eqterm_subst_left
    | idtac ..
    ]
  | |- eqterm ?G ?u (subst (subst ?v ?sbt) ?sbs) ?A =>
    eapply EqSym ; [
      idtac ..
    | eapply EqTyConv ; [
        try eapply eqterm_subst_left
      | idtac ..
      ]
    ]
  | _ => fail
  end.


(* Some tactic to push substitutions inside one step. *)
(* Partial for now. *)
Ltac pushsubst1 :=
  match goal with
  | |- eqtype ?G (Subst (Subst ?A ?sbs) ?sbt) ?B =>
    eapply EqTyTrans ; [
      eapply CongTySubst ; [
        eapply SubstRefl
      | pushsubst1
      | idtac ..
      ]
    | idtac ..
    ]
  | |- eqtype ?G (Subst (Id ?A ?u ?v) ?sbs) ?B =>
    eapply EqTyTrans ; [
      eapply EqTySubstId
    | idtac ..
    ]
  | |- eqtype ?G ?A (Subst (Id ?B ?u ?v) ?sbs) =>
    eapply EqTySym ; [
      idtac ..
    | eapply EqTyTrans ; [
        eapply EqTySubstId
      | idtac ..
      ]
    ]
  | |- eqtype ?G (Subst (Prod ?A ?B) ?sbs) ?C =>
    eapply EqTyTrans ; [
      eapply EqTySubstProd
    | idtac ..
    ]
  | |- eqtype ?G ?A (Subst (Prod ?B ?C) ?sbs) =>
    eapply EqTySym ; [
      idtac ..
    | eapply EqTyTrans ; [
        eapply EqTySubstProd
      | idtac ..
      ]
    ]
  (* | |- eqtype ?G (Subst ?E ?sbs) Empty *)
  | |- eqtype ?G (Subst Empty ?sbs) ?A =>
    eapply EqTyTrans ; [
      eapply EqTySubstEmpty
    | idtac ..
    ]
  (* | |- eqtype ?G Empty (Subst ?E ?sbs) *)
  | |- eqtype ?G ?A (Subst Empty ?sbs) =>
    eapply EqTySym ; [
      idtac ..
    | eapply EqTyTrans ; [
        eapply EqTySubstEmpty
      | idtac ..
      ]
    ]
  | |- eqtype ?G (Subst Unit ?sbs) ?A =>
    eapply EqTyTrans ; [
      eapply EqTySubstUnit
    | idtac ..
    ]
  | |- eqtype ?G ?A (Subst Unit ?sbs) =>
    eapply EqTySym ; [
      idtac ..
    | eapply EqTyTrans ; [
        eapply EqTySubstUnit
      | idtac ..
      ]
    ]
  | |- eqtype ?G (Subst Bool ?sbs) ?A =>
    eapply EqTyTrans ; [
      eapply EqTySubstBool
    | idtac ..
    ]
  | |- eqtype ?G ?A (Subst Bool ?sbs) =>
    eapply EqTySym ; [
      idtac ..
    | eapply EqTyTrans ; [
        eapply EqTySubstBool
      | idtac ..
      ]
    ]
  | |- eqterm ?G (subst (refl ?A ?u) ?sbs) ?v ?B =>
    eapply EqTrans ; [
      eapply EqSubstRefl
    | idtac ..
    ]
  | |- eqterm ?G (subst (refl ?A ?u) ?sbs) ?v ?B =>
    eapply EqTyConv ; [
      eapply EqTrans ; [
        eapply EqSubstRefl
      | idtac ..
      ]
    | idtac ..
    ]
  | |- eqterm ?G (subst true ?sbs) ?u ?A =>
    eapply EqTrans ; [
      eapply EqSubstTrue
    | idtac ..
    ]
  | |- eqterm ?G (subst true ?sbs) ?u ?A =>
    eapply EqTyConv ; [
      eapply EqTrans ; [
        eapply EqSubstTrue
      | idtac ..
      ]
    | idtac ..
    ]
  | |- eqterm ?G (subst false ?sbs) ?u ?A =>
    eapply EqTrans ; [
      eapply EqSubstFalse
    | idtac ..
    ]
  | |- eqterm ?G (subst false ?sbs) ?u ?A =>
    eapply EqTyConv ; [
      eapply EqTrans ; [
        eapply EqSubstFalse
      | idtac ..
      ]
    | idtac ..
    ]
  | _ => fail
  end.

Ltac cando token :=
  match token with
  | true => idtac
  | false => fail
  end.

(* Magic Tactic *)
(* It is basically a type checker that doesn't do the smart things,
   namely type and context conversions (and it doesn't rely on reflection
   obviously). *)
Ltac magicn n try :=
  first [
    assumption
  | (* We have several things we need to do to the tactic:
       * Only use assumption on the base cases (not on SubstZero and the like).
       * Remove the _ case.
       * Maybe add a token that states if we can use symmetry or not.
       * Maybe add a token that states if we can shelve or not.
       * Maybe add a token that states if we should allow not to solve the goal.
       * Handle substitutions properly by pushing them in before comparing.
       * Add special rules when dealing with substitution typing this can go
         though special admissibility rules that factorize the number of
         premises that would be needed to prove.
       * Should it be able to use EqTyWeakNat?
       * Add a token to solve equalities with only one side as reflexivity.
         (Maybe shelve them in the meantime?)
       * Maybe shelve only when try token is false.
       * ... *)
    lazymatch goal with
    (*! Contexts !*)
    | |- isctx ctxempty =>
      apply CtxEmpty
    | |- isctx (ctxextend ?G ?A) =>
      eapply CtxExtend ; magicn n try
    | |- isctx ?G =>
      (* And not eassumption so we don't select some random context. *)
      assumption || shelve
    (*! Substitutions !*)
    | |- issubst (sbzero ?u) ?G1 ?G2 =>
      first [
          eapply SubstZero ; magicn n try
        | eassumption
        ]
    | |- issubst sbweak ?G1 ?G2 =>
      first [
          eapply SubstWeak ; magicn n try
        | assumption
        | shelve
        ]
    | |- issubst (sbshift ?sbs) ?G1 ?G2 =>
      first [
          eapply SubstShift ; magicn n try
        | eassumption
        ]
    | |- issubst (sbid) ?G1 ?G2 =>
      first [
          eapply SubstId ; magicn n try
        | eassumption
        ]
    | |- issubst (sbcomp ?sbt ?sbs) ?G1 ?G2 =>
      first [
          eapply SubstComp ; magicn n try
        | eassumption
        ]
    | |- issubst ?sbs ?G1 ?G2 =>
      (* Dangerous I would like to do it only when sbs is a variable. *)
      (* eassumption *)
      is_var sbs ; eassumption
    (*! Types !*)
    | |- istype ?G (Subst ?A ?sbs) =>
      eapply TySubst ; magicn n try
    | |- istype ?G (Prod ?A ?B) =>
      eapply TyProd ; magicn n try
    | |- istype ?G (Id ?A ?u ?v) =>
      eapply TyId ; magicn n try
    | |- istype ?G Empty =>
      eapply TyEmpty ; magicn n try
    | |- istype ?G Unit =>
      eapply TyUnit ; magicn n try
    | |- istype ?G Bool =>
      eapply TyBool ; magicn n try
    | |- istype ?G ?A =>
      first [
        is_var A ; eassumption
      | assumption (* Maybe not necessary? *)
      | shelve
      ]
    (*! Terms !*)
    | |- isterm ?G (subst ?u ?sbs) ?A =>
      eapply TermSubst ; magicn n try
    | |- isterm (ctxextend ?G ?A) (var 0) ?T =>
      eapply TermVarZero ; magicn n try
    | |- isterm (ctxextend ?G ?B) (var (S ?k)) (Subst ?A sbweak) =>
      eapply TermVarSucc ; magicn n try
    | |- isterm ?G (lam ?A ?B ?u) ?C =>
      eapply TermAbs ; magicn n try
    | |- isterm ?G (app ?u ?A ?B ?v) ?C =>
      eapply TermApp ; magicn n try
    | |- isterm ?G (refl ?A ?u) ?B =>
      eapply TermRefl ; magicn n try
    | |- isterm ?G (j ?A ?u ?C ?w ?v ?p) ?T =>
      eapply TermJ ; magicn n try
    | |- isterm ?G (exfalso ?A ?u) _ =>
      eapply TermExfalso ; magicn n try
    | |- isterm ?G unit ?A =>
      first [
          eapply TermUnit ; magicn n try
        | eapply TermTyConv ; [
            eapply TermUnit ; magicn n try
          | magicn n try
          ]
        ]
    | |- isterm ?G true ?A =>
      first [
          eapply TermTrue ; magicn n try
        | eapply TermTyConv ; [
            eapply TermTrue ; magicn n try
          | magicn n try
          ]
        ]
    | |- isterm ?G false ?A =>
      first [
          eapply TermFalse ; magicn n try
        | eapply TermTyConv ; [
            eapply TermFalse ; magicn n try
          | magicn n try
          ]
        ]
    | |- isterm ?G (cond ?C ?u ?v ?w) ?T =>
      eapply TermCond ; magicn n try
    | [ H : isterm ?G ?v ?A, H' : isterm ?G ?v ?B |- isterm ?G ?v ?C ] =>
      (* We have several options so we don't take any risk. *)
      (* Eventually this should go away. I don't want to do the assert thing
         anymore. *)
      first [
        is_var A ; exact H
      | is_var B ; exact H'
      | shelve
      ]
    | |- isterm ?G ?u ?A =>
      first [
        (* If u is an existential variable we don't touch it. *)
        is_evar u ; shelve
      | (* Otherwise, we can try eassumption *)
        eassumption
      ]
    (*! Equality of contexts !*)
    | |- eqctx ctxempty ctxempty =>
      apply EqCtxEmpty
    | |- eqctx (ctxextend ?G ?A) (ctxextend ?D ?B) =>
      first [
          eapply EqCtxExtend ; magicn n try
        | apply CtxSym ; [ eapply EqCtxExtend ; magicn n try | magicn n try .. ]
        ]
    | |- eqctx ?G ?G =>
      apply CtxRefl ; magicn n try
    | |- eqctx ?G ?D =>
      (* When comparing two contexts that are unknown, we either know
       already, or we know the symmetry. *)
      (* assumption *)
      (* In the first case we don't want to use magic in order to avoid symmetry
       again. *)
      (* || apply CtxSym ; [ assumption | magicn n try .. ] *)
      first [ assumption | apply CtxSym ; [ assumption | magicn n try .. ] ]
    (*! Equality of substitutions !*)
    | |- eqsubst (sbcomp sbweak (sbzero ?u)) sbid ?G ?D =>
      eapply WeakZero ; magicn n try
    | |- eqsubst sbid (sbcomp sbweak (sbzero ?u)) ?G ?D =>
      eapply mySubstSym ; [
        eapply WeakZero ; magicn n try
      | magicn n try ..
      ]
    | |- eqsubst (sbzero ?u1) (sbzero ?u2) ?D ?E =>
      eapply CongSubstZero ; magicn n try
    | |- eqsubst sbweak sbweak ?D ?E =>
      eapply CongSubstWeak ; magicn n try
    | |- eqsubst (sbshift ?sbs1) (sbshift ?sbs2) ?D ?E =>
      eapply CongSubstShift ; magicn n try
    (* We should probably avoid using congruence on composition. *)
    (* To be continued... *)
    (*! Equality of types !*)
    | |- eqtype ?g (Subst (Subst ?A ?sbs) ?sbt) ?B =>
      compsubst1 ; magicn n try
    | |- eqtype ?g ?A (Subst (Subst ?B ?sbs) ?sbt) =>
      compsubst1 ; magicn n try
    | |- eqtype ?G (Subst ?A ?sbs) ?B =>
      (* We should push only if it makes sense. *)
      first [
        is_var A ;
        first [
          is_var sbs ;
          first [
            eapply CongTySubst ; magicn n try
          | eassumption
          ]
        | first [
            eapply EqTyIdSubst ; magicn n try
          | eapply CongTySubst ; magicn n try
          ]
        ]
      | pushsubst1 ; magicn n try
      ]
    (* | |- eqtype ?G (Subst ?A (sbid)) ?B => *)
    (*   first [ *)
    (*     eapply EqTyIdSubst ; magicn n try *)
    (*   | eapply CongTySubst ; magicn n try *)
    (*   ] *)
    (* (* EqTySubst* ? *) *)
    (* | |- eqtype ?G (Subst ?A ?sbs) (Subst ?B ?sbt) => *)
    (*   eapply CongTySubst ; magicn n try *)
    (* | |- eqtype _ (Id _ _ _) (Id _ _ _) => *)
    (*   eapply CongId ; magicn n try *)
    (* To be continued... *)
    (*! Equality of terms !*)
    | |- eqterm ?G (subst ?u ?sbs) (subst ?v ?sbt) ?A =>
      eapply CongTermSubst ; magicn n try
    (* To be continues... *)
    (* When all else fails. *)
    (* This part will hopefully be gone at some point. *)
    | _ =>
      match eval compute in n with
      | 0 => assumption
      | S ?n => assumption || (constructor ; magicn n try)
      end
    end
  | cando try
  ].

Ltac magic2 := magicn (S (S 0)) false.
Ltac magic3 := magicn (S (S (S 0))) false.
Ltac magic4 := magicn (S (S (S (S 0)))) false.
Ltac magic5 := magicn (S (S (S (S (S 0))))) false.
Ltac magic := magic2. (* ; Unshelve ; magic2. *)
Ltac trymagic := magicn (S (S 0)) true.

(* With it we improve compsubst1 *)
Ltac gocompsubst := compsubst1 ; try magic.

(* With it we improve pushsubst1 *)
Ltac gopushsubst := pushsubst1 ; try magic.
