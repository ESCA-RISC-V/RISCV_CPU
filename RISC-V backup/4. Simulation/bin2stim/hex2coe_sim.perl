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

$private0 = 'private0.coe';
$private1 = 'private1.coe';
$interleaved0 = 'interleaved0.coe';
$interleaved1 = 'interleaved1.coe';
$interleaved2 = 'interleaved2.coe';
$interleaved3 = 'interleaved3.coe';

$count=0;

open(MEM, ">$private0");
#print MEM "00000000\n";

#$count=1;
while(<FH>) {
	chomp;
	printf MEM "$_\n";
	$count++;
	if($count==8192 | $lcount==$count) {
		last;
	}
}
close(MEM);

open(MEM, ">$private1");

while(<FH>) {
	chomp;
	printf MEM "$_\n";
	$count++;
	if($count==16384 | $lcount==$count) {
		last;
	}
}
close(MEM);

open(MEM1, ">$interleaved0");

open(MEM2, ">$interleaved1");

open(MEM3, ">$interleaved2");

open(MEM4, ">$interleaved3");

while(<FH>) {
	chomp;
	if($count%4==0) {
		printf MEM1 "$_\n";
	}
	elsif($count%4==1) {
		printf MEM2 "$_\n";
	}
	elsif($count%4==2) {
		printf MEM3 "$_\n";
	}
	else {
		printf MEM4 "$_\n";
	}
	$count++;
}

if($count<16385) {
		printf MEM1 "00000000\n";
}
if($count<16386) {
		printf MEM2 "00000000\n";
}
if($count<16387) {
		printf MEM3 "00000000\n";
}
if($count<16388) {
		printf MEM4 "00000000\n";
}

close(MEM1);
close(MEM2);
close(MEM3);
close(MEM4);
close(FH);

