var x1 >= 0;
var x2 >= 0;

maximize label:     4*x1 + 5*x2;

s.t.        label1: x1 + 2*x2 <= 40;
s.t.        label2: 4*x1 + 3*x2 <= 120;

solve;

printf "x1: %g\nx2: %g\n", x1, x2;
printf "Result: %g\n", label;

display label;

end;