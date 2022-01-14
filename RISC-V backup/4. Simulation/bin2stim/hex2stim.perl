#!/usr/bin/perl

open (FH, "<test.hex") or die "ooops: $!";
$lcount=0;
while(<FH>) {
	$lcount++;
}
print $lcount;
print "\n";
close(FH);

open(FH, "<test.hex") or die "ooops: $!";
$addr = 0x1C000000;
$loc = 0;
open(MEM, ">stim.txt") or die "ooops: $!";

while(<FH>) {
	chomp;
	if($loc%2==1) {
		$data1 = $_;
		printf MEM "%X_", $addr;
		print MEM $data1;
		print MEM $data2;
		if($loc != %lcount) {print MEM "\n";}
		$addr += 8;
	}
	else {
		$data2 = $_;
	}
	$loc += 1;
}
if($loc %2 == 1) {
	printf MEM "%X_", $addr;
	print MEM $data2;
	print MEM "00000000";
}

print $loc;

close(MEM);
close(FH);

