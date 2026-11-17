// RV32u C test: nested loops, compares and swaps through memory.
// expect: result[0]=-7 result[1]=0 result[2]=31 result[3]=1
volatile int result[4];

int v[10] = {5, 31, -7, 12, 0, 8, -1, 19, 3, 2};

int main(void) {
  for (int i = 0; i < 9; i = i + 1)
    for (int j = 0; j < 9 - i; j = j + 1)
      if (v[j + 1] < v[j]) {
        int t = v[j];
        v[j] = v[j + 1];
        v[j + 1] = t;
      }
  int ok = 1;
  for (int i = 0; i < 9; i = i + 1)
    if (v[i + 1] < v[i]) ok = 0;
  result[0] = v[0];
  result[1] = v[2];
  result[2] = v[9];
  result[3] = ok;
  return 0;
}
