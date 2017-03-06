(* The target type theory, economic itensional type theory *)

Require config.
Require Import tt.

Section Eitt.

Local Instance hasPrecond : config.Precond
  := {| config.precondFlag := config.No |}.
Local Instance hasReflection : config.Reflection
  := {| config.reflectionFlag := config.No |}.

Definition isctx := isctx.
Definition issubst := issubst.
Definition istype := istype.
Definition isterm := isterm.
Definition eqctx := eqctx.
Definition eqsubst := eqsubst.
Definition eqtype := eqtype.
Definition eqterm := eqterm.

End Eitt.