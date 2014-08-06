#include <unistd.h>
#include "syscall.h"
#include "libc.h"
#include <CAsm.h>

ssize_t write(int fd, const void *buf, size_t count)
{
	casm_start
		mov(r7,"#4")
		swi()
	casm_end
}
