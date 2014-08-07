#include <CAsm.h>

void sync(void)
{
	casm_start
		mov(r7,"#36")
		swi()
	casm_end	
}
