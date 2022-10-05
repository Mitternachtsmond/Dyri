%{
  open Ast.Ast

  let loc_pos (loc: Lexing.position * Lexing.position): pos =
    {
      starts = (fst loc).pos_bol;
      line = (snd loc).pos_lnum;
      ends = (snd loc).pos_bol;
    };;

  let to_stmt (desc: desc) (loc: Lexing.position * Lexing.position): stmt =
    {desc = desc; pos = loc_pos loc}
%}

%token <Ast.Ast.value> VALUE
%token <string> NAME
%token LET FOR IF ELSE RBRACE LBRACE RPARENT LPARENT BREAK
%token DOUBLEDOT QUESTION SEMICOLON EQUAL RARROW
%token EOF

%start code

%type <code> code

%%

code: c = list(stmt) EOF { c }

stmt:
  | s = desc { to_stmt s $loc }

desc:
  | e = expr { e }
  | LPARENT e = desc RPARENT { e }
  | v = variable SEMICOLON { v }
  | f = func SEMICOLON { f }

expr:
  | v = VALUE { Const v }
  | n = NAME e = list(desc)
    {
      match e with
      | [] -> Var n
      | l ->
        Apply (n, l)
    }

typ:
  | n1 = NAME?
    {
      match n1 with
      | Some v -> TTyp v
      | None -> TInference
    }

variable:
  | LET n = NAME EQUAL e = desc
    { Let (n, TInference, e) }
  | LET n1 = NAME DOUBLEDOT n2 = typ EQUAL e = desc
    { Let (n1, n2, e) }

params:
  | n = NAME
    { PName n }
  | LPARENT n1 = NAME DOUBLEDOT n2 = typ RPARENT
    { PTyp (n1, n2) }

func:
  | LET n = NAME p = list(params) EQUAL e = desc
    { Fun (n, TInference, p, e) }
  | LET n1 = NAME p = list(params) DOUBLEDOT n2 = typ EQUAL e = desc
    { Fun (n1, n2, p, e) }
