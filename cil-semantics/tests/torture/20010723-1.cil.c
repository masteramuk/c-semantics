/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

extern  __attribute__((__nothrow__, __noreturn__)) void abort(void)  __attribute__((__leaf__)) ;
extern  __attribute__((__nothrow__, __noreturn__)) void exit(int __status )  __attribute__((__leaf__)) ;
int test(void) 
{ int biv ;
  int giv ;

  {
  biv = 0;
  giv = 0;
  while (giv != 8) {
    giv = biv * 8;
    biv ++;
  }
  return (giv);
}
}
int main(void) 
{ int tmp ;

  {
  tmp = test();
  if (tmp != 8) {
    abort();
  }
  exit(0);
}
}