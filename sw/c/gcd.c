// RV32u C test: while (a != b) with subtraction only (no %, which RV32u lacks).
// expect: result[0]=21 result[1]=1 result[2]=12
volatile int result[3];

int gcd(int a, int b) {
  while (a != b) {
    if (a < b) b = b - a;
    else a = a - b;
  }
  return a;
}

int main(void) {
  result[0] = gcd(1071, 462);
  result[1] = gcd(17, 5);
  result[2] = gcd(36, 48);
  return 0;
}
