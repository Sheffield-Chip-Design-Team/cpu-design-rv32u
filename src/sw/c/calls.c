// RV32u C test: nested calls, six arguments, a function-pointer table (jalr),
// equality tests (bne/beq) and many live locals across calls.
// expect: result[0]=21 result[1]=12 result[2]=-3 result[3]=1 result[4]=0
volatile int result[5];

int add6(int a, int b, int c, int d, int e, int f) { return a + b + c + d + e + f; }
int twice(int x) { return x + x; }
int sub3(int x) { return x - 3; }
int apply(int (*fn)(int), int x) { return fn(x); }
int same(int a, int b) { return a == b; }

int (*ops[2])(int) = {twice, sub3};

int main(void) {
  int a = 1, b = 2, c = 3, d = 4, e = 5, f = 6;
  result[0] = add6(a, b, c, d, e, f);
  result[1] = apply(ops[0], f);
  result[2] = apply(ops[1], 0);
  result[3] = same(a + e, f);
  result[4] = same(b, c);
  return 0;
}
