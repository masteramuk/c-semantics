/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

extern  __attribute__((__nothrow__, __noreturn__)) void abort(void)  __attribute__((__leaf__)) ;
int g_21  ;
int g_211  ;
int g_261  ;
static void __attribute__((__noclone__))  ( __attribute__((__noinline__)) func_32)(int b ) 
{ 

  {
  if (b) {
    lbl_370: 
    g_21 = 1;
  }
  g_261 = -1;
  while (g_261 > -2) {
    if (g_211 + 1) {
      return;
    } else {
      g_21 = 1;
      goto lbl_370;
    }
    g_261 --;
  }
  return;
}
}
int main(void) 
{ 

  {
  func_32(0);
  if (g_261 != -1) {
    abort();
  }
  return (0);
}
}