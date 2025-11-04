def fold(cond; update):
  def _fold: . as $old | update | if cond then _fold else $old end;
  if cond then _fold end;
def skip(cond; update):
  def _skip: if cond then update | _skip end;
  _skip;
def find(cond; update): skip(cond | not; update);
def pipe($n; f): if $n > 0 then f | pipe($n-1; f) end;
def repeat: repeat(.);
def repeat(exp; $n): foreach range($n) as $_ (.; .; exp);
def add(gen): reduce gen as $n (null; .+$n);
def sum: add;
def sum(gen): add(gen);
def str: tostring;
def str($s): $s | tostring;
def num: tonumber;
def num($n): $n | tonumber;
def len: length;
def len($x): $x | length;
def mod($n): ($n+.%$n)%$n;
def mod($m; $n): $m|mod($n);
def modf($n): .-(./$n|floor)*$n;
def modf($m; $n): $m|modf($n);
def pow($p): pow($p; .);
def pow2: pow(2; .);
def pow10: pow(10; .);
def pow2($n): pow(2; $n);
def pow10($n): pow(10; $n);
def rec: recurse;
def rec(a): recurse(a);
def rec(a; b): recurse(a; b);
def chr: [.] | implode;
def chr(chs): [chs] | implode;
def ord: explode[];
def ord($strs): $strs | explode[];
def str: tostring;
def str($s): $s | tostring;
def bool: if . then true else false end;
def bool($x): $x | bool;
def isnull: . == null;
def isnull($x): $x == null;
def nonull: . != null;
def nonull($x): $x != null;
def nullor(default): if isnull then default end;
def nullor($val; default): $val | if isnull then default end;
def andmap(f): if nonull then f end;
def andmap($val; f): $val | if nonull then f end;
def repack(f): .[] |= f;
def update(f): .[] |= f;
def sort($arr): $arr | sort;
def sort_by($arr; f): $arr | sort_by(f);
def map_keys(f): with_entries(.key |= f);
def round($d): pow(10; $d) as $p | .*$p | round/$p;
def reduce2(gen; f):
  reduce gen as $i (null;
    if not then [$i] else [.+[$i] | f] end
  ) | first;
def prod(gen):
  reduce gen as $i (null;
    if not then [$i] else first *= $i end
  ) | first;
def prod: prod(.[]);
def mul(gen): prod(gen);
def mul: prod;
def comb: combinations;
def comb($n): combinations($n);
def exclude(predicate): select(predicate | not);
def filter(predicate): select(predicate);
def find(predicate): filter(predicate);
def take($n; gen):
  label $x | foreach gen as $i (0; if .<$n then
    .+1
  else
    break $x
  end; $i);
def skipn($n; gen):
  foreach gen as $i (0; .+1; if .<=$n then
    empty
  end | $i)
  ;
def issorted(gen; predicate):
  (
    label $x |
    reduce2(gen; if predicate | not then
      break $x
    end | last) | true
  ) // false;
def issorted(predicate): issorted(.[]; predicate);
def issorted: issorted(first <= last);
def min($a; $b): if $a <= $b then $a else $b end;
def max($a; $b): if $a >= $b then $a else $b end;
def zip($a; $b): range(min($a | length; $b | length)) | [$a[.], $b[.]];
def zip($b): zip(.; $b);
def dbg: debug;
def dbg(msg): debug(msg);
def each(f): .[]|f;
def counter:
  reduce .[] as $i ({}; .[$i | @json] += 1)
  | to_entries
  | sort_by(-.value)
  | from_entries
  ;
def fmt:
  def green: "\u001b[32m\(.)\u001b[0m";
  def blue: "\u001b[1;94m\(.)\u001b[0m";
  def bold: "\u001b[1m\(.)\u001b[0m";
  def left($s): if type == "array" then first end |= $s+.;
  def right($s): if type == "array" then last end += $s;
  def gen:
    if type == "string" then
      @json | green
    elif type == "array" then
      (if length > 1 then "," else "" end) as $comma |
      [("["|bold), each(gen | right($comma)), ("]"|bold)]
    elif type == "object" then
      (if length > 1 then "," else "" end) as $comma |
      [("{"|bold), (
        to_entries[]
        | "\(.key|@json|blue): " as $k
        | .value | gen
        | left($k) | right($comma)
      ), ("}"|bold)]
    else @text end
    ;
  def show($indent; $firts_indent):
    (filter($firts_indent) | "  "*$indent),
    if type == "array" then
      first,
      (
        filter(length > 2) | if length == 3 then
          .[1:-1][] | show($indent; false)
        else
          "\n", (.[1:-1][] | show($indent+1; true), "\n"), "  "*$indent
        end
      ),
      last
    else
      .
    end
    ;
  (gen | show(0; true), "\n" | stderr | empty), .
  ;
