OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    PRIVATE0  : ORIGIN = 0x1C000000, LENGTH = 0x8000
    PRIVATE1  : ORIGIN = 0x1C008000, LENGTH = 0x8000  	
}

SECTIONS
{
	.text : 
	{
		. = ALIGN(4);
		*(.text) 
	} > PRIVATE1

	.data :
	{
		. = ALIGN(4);
	    *(.data)
	} > PRIVATE0

	.bss :
	{
		. = ALIGN(4);
	    *(.bss)
	} > PRIVATE0
}