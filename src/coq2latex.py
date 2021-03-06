#!/usr/bin/env python
import sys
import re
from string import Template

keywords = {
    'G' : 'Gamma',
    'D' : 'Delta',
    'E' : 'Theta',
    'ctxempty' : 'ctxempty',
    'sb' : 'sigma',
    'sbs' : 'sigma',
    'sbt' : 'tau',
    'sbr' : 'rho',
    'Bool' : 'Bool',
    'Unit' : 'Unit',
    'Empty' : 'Empty',
    'true' : 'true',
    'false' : 'false'
}

macros = {
    'isctx' : (1, 'isctx'),
    'istype' : (2, 'istype'),
    'isterm' : (3, 'isterm'),
    'issubst' : (3, 'issubst'),
    'eqtype' : (3, 'eqtype'),
    'eqterm' : (4, 'eqterm'),
    'eqctx' : (2, 'eqctx'),
    'eqsubst' : (4, 'eqsubst'),
    'ctxextend' : (2, 'ctxextend'),
    'lam' : (3, 'lam'),
    'Prod' : (2, 'Prod'),
    'Id' : (3, 'Id'),
    'refl' : (2, 'refl'),
    'j' : (6, 'J'),
    'Subst' : (2, 'subst'),
    'subst' : (2, 'subst'),
    'sbweak' : (1, 'sbweak'),
    'sbshift' : (2, 'sbshift'),
    'sbid' : (1, 'sbid'),
    'sbcomp' : (2, 'sbcomp'),
    'sbzero' : (2, 'sbzero'),
    'var' : (1, 'var'),
    'S' : (1, 'suc'),
    'cond' : (4, 'cond'),
    'SimProd' : (2, 'SimProd'),
    'U' : (1, 'Uni'),
    'El' : (1, 'El'),
    'pair' : (4, 'pair'),
    'proj1' : (3, 'proj1'),
    'proj2' : (3, 'proj2'),
    'uniProd' : (3, 'uniProd'),
    'uniId' : (4, 'uniId'),
    'uniEmpty' : (1, 'uniEmpty'),
    'uniUnit' : (1, 'uniUnit'),
    'uniBool' : (1, 'uniBool'),
    'uniSimProd' : (3, 'uniSimProd'),
    'uniUni' : (1, 'uniUni')
}

# We're actually going to parse stuff here, so we work with
# a stream of tokens.

class TokenStream():
    def __init__(self, s):
        self.tokens = [t for t in re.split(r'\s+|([()])', s.strip()) if t]

    def __str__(self):
        return " ".join(self.tokens)

    def peek(self):
        return (self.tokens[0] if len(self.tokens) > 0 else None)

    def pop(self):
        if len(self.tokens) > 0:
            t = self.tokens.pop(0)
            return t
        else:
            return None

def die(msg):
    raise SyntaxError(msg)

def embrace(s):
    return '{' + s + '}'

def bk(s):
    return '\\' + s

def subscribe(t, s):
    return "{0}_{{{1}}}".format(t, s) if s else t

class Ident():
    def __init__(self, keyword):
        m = re.match(r'^(.*?)(\d+)$', keyword)
        if m:
            self.keyword = m.group(1)
            self.subscript = m.group(2)
        else:
            self.keyword = keyword
            self.subscript = 0

    def __str__(self):
        if self.keyword in keywords:
            return embrace(subscribe(bk(keywords[self.keyword]), self.subscript))
        elif len(self.keyword) == 1:
            return subscribe(self.keyword, self.subscript)
        else:
            return subscribe(r'\mathtt{{{0}}}'.format(self.keyword), self.subscript)

    def makeApp(self, args):
        if len(args) == 0:
            return self
        else:
            return Application(self, args)

    def is_macro(self):
        return self.keyword in macros

class Application():
    def __init__(self, head, args):
        self.head = head
        self.args = args

    def is_macro(self):
        return False

    def makeApp(self, args):
        return Application(self.head, self.args + args)

    def __str__(self):
        if self.head.is_macro():
            (arity, m) = macros[self.head.keyword]
            if len(self.args) != arity:
                die("macro {0} expects {1} arguments but got {2}".format(m, arity,
                                                                        len(self.args)))
            else:
                return "{0}{1}".format(bk(m), "".join([embrace(str(a)) for a in self.args ]))
        else:
            return "{0}\, {1}".format(str(self.head), "\, ".join(map(str, self.args)))

def parseSimple(tok):
    if tok.peek() == '(':
        tok.pop()
        e = parseApply(tok)
        if tok.pop() != ')':
            die("parsing: expected )".format(c))
        return e
    elif tok.peek() is not None and bool(re.match(r'\w+', tok.peek())):
        t = tok.pop()
        ob =  Ident(t)
        return ob
    else:
        return None

def parseApply(tok):
    head = parseSimple(tok)
    args = []
    t = parseSimple(tok)
    while t is not None:
        args.append(t)
        t = parseSimple(tok)
    return head.makeApp(args)

def parseExpr(tok):
    e = parseApply(tok)
    if tok.pop() is not None:
        die ("premature end")
    return e

def ruleTag(prefix, rulename):
    return prefix + "-" + "-".join((w.lower() for w in re.findall(r'[A-Z][a-z]*', rulename)))

def rule2latex(prefix, name, premises, conclusion):
    premises = [str(parseExpr(TokenStream(premise))) for premise in premises]
    conclusion = str(parseExpr(TokenStream(conclusion)))
    return Template(
r"""\newcommand{\rl$Prefix$name}{\referTo{$name}{rul:$name}}
\newcommand{\show$Prefix$name}{%
    \infer
    { $premises}
    {$conclusion}
}
""").substitute({"name" : name,
                 "Prefix" : prefix.capitalize(),
                 "premises" : " \\\\\n".join(premises),
                 "conclusion" : conclusion})


def section(title, prefix, src):
    """Process one inductive definition."""

    print ('\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    print ('% {0}\n'.format(title))

    rules = re.findall(
            r'^\s*\|\s+'                   # the beginning of a rule
            r'(?P<rulename>\w+)\s*:\s*$'   # rule name
            r'\s*rule\s*'                  # header
            r'(?P<rulebody>.*?)'           # rule body
            r'endrule',                    # footer
            src,
            re.DOTALL + re.MULTILINE)

    for rule in rules:
        rulename = rule[0]
        rulebody = rule[1]
        m = re.match(
            r'^(\s*parameters:.*?,)?'                 # optional parameters
            r'(?P<premises>.*?)'                      # premises
            r'conclusion:\s*(?P<conclusion>.*)\s*$',  # the rest is the rule
            rulebody,
            re.DOTALL)
        if not m:
            die ("Failed to parse rule {0} whose body is:\n{1}".format(rulename, rulebody))
        premises = re.split(r'\s*(?:premise|precond):\s*', m.group('premises'))
        if len(premises) > 0 and not premises[0]: premises.pop(0)
        conclusion = m.group('conclusion')
        print (rule2latex(prefix, rulename, premises, conclusion))

    print (Template(r"\newcommand{\show${Prefix}${Title}Rules}{").substitute({
        'Prefix' : prefix.capitalize(),
        'Title' : title.capitalize()
    }))

    for rule in rules:
        rulename = rule[0]
        print(Template(r"""\begin{equation}
                           \show$Prefix$name
                           \tag{\textsc{$ruleTag}}
                           \end{equation}"""
        ).substitute({
            'Prefix' : prefix.capitalize(),
            'ruleTag' : ruleTag(prefix, rulename),
            'name' : rulename}
        ))

    print (r'}')


### MAIN PROGRAM

# load the source file
filename = sys.argv[1]

# prefix = re.match('^(\w+)\.v$', filename).group(1)
prefix = ""

with open(filename, "r") as f:
    src = f.read()

# remove prelude
sections = re.split(r'Inductive', src, 1)[1]

sections = re.split(r'Inductive|with\b', sections)
for sect in sections:
    # print sect
    m = re.match(r'^\s+(\w+)\s+:', sect) or die ("Could not find section title")
    title = m.group(1)
    section(title, prefix, sect)
