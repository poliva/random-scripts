#!/usr/bin/perl

# Declare the subroutine
sub trimwhitespace($);

# Here is how to output the trimmed text
print trimwhitespace($ARGV[0]);

# Remove whitespace from the start and end of the string
sub trimwhitespace($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
