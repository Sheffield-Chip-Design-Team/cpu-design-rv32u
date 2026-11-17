// RV32u C test: int arrays, indexing (slli is legalized), sums, max and a reversal.
// expect: result[0]=36 result[1]=-4 result[2]=40 result[3]=1
volatile int result[4];

int data[8] = {7, -4, 12, 1, -9, 40, -3, -8};

int sum(int *a, int n) {
  int s = 0;
  for (int i = 0; i < n; i = i + 1) s = s + a[i];
  return s;
}

int max(int *a, int n) {
  int m = a[0];
  for (int i = 1; i < n; i = i + 1)
    if (m < a[i]) m = a[i];
  return m;
}

int main(void) {
  result[0] = sum(data, 8);
  for (int i = 0; i < 4; i = i + 1) {
    int t = data[i];
    data[i] = data[7 - i];
    data[7 - i] = t;
  }
  result[1] = data[6];
  result[2] = max(data, 8);
  result[3] = data[4];
  return 0;
}
