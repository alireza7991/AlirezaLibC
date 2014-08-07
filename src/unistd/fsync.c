#include <CAsm.h>

int fsync(int fd)
{
	casm_start
		mov(r7,"#118")
		swi()
	casm_end
}
