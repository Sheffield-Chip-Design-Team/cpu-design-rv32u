// RV32u C test: recursion (deep stack use) and an iterative table.
// expect: result[0]=55 result[1]=610 result[2]=377
volatile int result[3];

int fib(int n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}

int main(void) {
  int table[16];
  table[0] = 0;
  table[1] = 1;
  for (int i = 2; i < 16; i = i + 1) table[i] = table[i - 1] + table[i - 2];
  result[0] = fib(10);
  result[1] = table[15];
  result[2] = table[14];
  return 0;
}
