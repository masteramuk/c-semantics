extern struct foo x;

void bar(struct foo *x);

struct foo *p = &x;

int main() {
  const struct foo *p2 = &x;
  bar(p);
  return 0;
}
