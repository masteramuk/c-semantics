// kcc-assert-error(00007)
int main(void){
	int* p = 0;
	{
		int x;
		p = &x;
	}
	p;
	return 0;
}
