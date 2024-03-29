# Copyright (c) 2008 Yahoo! Inc. All rights reserved. The copyrights to
# the contents of this file are licensed under the Perl Artistic License
# (ver. 15 Aug 1997).
###########################################
package String::Glob::Permute;
###########################################

use strict;
use warnings;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(string_glob_permute);
our $VERSION   = "0.01";

###########################################
sub string_glob_permute {
###########################################
    my( $string_glob ) = @_;

    my @stringlist;
    my @patterns = ($string_glob);

    while (@patterns) {

	my $h = shift(@patterns);

	if ($h =~ /^(.*?)\[([^\]]+)\]([^,{[]*)(,(.*))?$/) {
	    my($pre,$post) = ($1,$3);

	    my @r = split(/,/,$2);

	    for (@r) {

		if (/^(!?)(\d+)(-(\d+))?$/) {
		    my $lo = $2;
		    my $hi = $3 ? $4 : $lo;
                    my $fmt = "%d";

                      # Expand [09-11] to ("09", "10", "11") instead of
                      # ("9", "10", "11").
                    if (length($lo) == length($hi) && length($lo) > 1) {
                        $fmt = "%0" . length($lo) . "d";
                    }

		    for (my $n = $lo; $n <= $hi; $n++) {
			my $hn = $pre . sprintf($fmt, $n) . $post;

			if ($1) {
			    @stringlist = grep { $_ ne $hn } @stringlist;
			    @patterns = grep { $_ ne $hn } @patterns;
			} else {
			    push(@patterns,$hn);
			}
		    }
		} else {
		    warn("Unrecognized host pattern: $h");
                    return undef;
		}
	    }

	    if ($4) {
		push(@patterns,$5);
	    }

	} elsif ($h =~ /^(.*?)\{([^\}]+)\}([^,[{]*)(,(.*))?$/) {

	    my($pre,$post) = ($1,$3);
	    my @r = split(/,/,$2);

	    for (@r) {
		push(@patterns,$pre.$_.$post);
	    }

	    if ($4) {
		push(@patterns,$5);
	    }
	} else {
	    my @h = split(/,/,$h);
	    push(@stringlist,@h);
	}
    }
    return @stringlist;
}

1;

__END__

=head1 NAME

String::Glob::Permute - Expand {foo,bar,baz}[2-4] style string globs

=head1 SYNOPSIS

    use String::Glob::Permute qw( string_glob_permute );

    my $pattern = "host{foo,bar,baz}[2-4]";

    for my $host (string_glob_permute( $pattern )) {
        print "$host\n";
    }

      # hostfoo2
      # hostbar2
      # hostbaz2
      # hostfoo3
      # hostbar3
      # hostbaz3
      # hostfoo4
      # hostbar4
      # hostbaz4

=head1 DESCRIPTION

The C<string_glob_permute()> function provided by this module expands 
glob-like notations in text strings and returns all possible permutations.

For example, to run a script on hosts host1, host2, and host3, you might
write 

    @hosts = string_glob_permute( "host[1-3]" );

and get a list of hosts back: ("host1", "host2", "host3").

Ranges with gaps are also supported, just separate the blocks by
commas:

    @hosts = string_glob_permute( "host[1-3,5,9]" );

will return ("host1", "host2", "host3", "host5", "host9").

And, finally, using curly brackets and comma-separated lists of strings,
as in

    @hosts = string_glob_permute( "host{dev,stag,prod}" );

you'll get permutations with each of the alternatives back:
("hostdev", "hoststag", "hostprod") back.

All of the above can be combined, so 

    my @hosts = string_glob_permute( "host{dev,stag}[3-4]" );

will result in the permutation
("hostdev3", "hoststag3", "hostdev4", "hoststag4").

The patterns allow numerical ranges only [1-3], no string ranges like 
[a-z]. Pattern must not contain blanks.

The function returns a list of string permutations on success and
C<undef> in case of an error. A warning is also issued if the pattern
cannot be recognized.

=head2 Zero padding

An expression like

    @hosts = string_glob_permute( "host[8-9,10]" );
      # ("host8", "host9", "host10")

will expand to ("host8", "host9", "host10"), featuring no zero-padding to
create equal-length entries. If you want ("host08", "host09", "host10"),
instead, pad all integers in the range expression accordingly:

    @hosts = string_glob_permute( "host[08-09,10]" );
      # ("host08", "host09", "host10")

=head2 Note on Perl's internal Glob Permutations

Note that there's a little-known feature within Perl itself that does 
something similar, for example

    print "$_\n" for < foo{bar,baz} >;

will print 

    foobar
    foobaz

if there is no file in the current directory that matches that pattern.
String::Glob::Permute, on the other hand, expands irrespective of matching
files, by simply always returning all possible permutations. It's also
worth noting that Perl's internal Glob Permutation does not support
String::Glob::Permute's [m,n] or [m-n] syntax.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Yahoo! Inc. All rights reserved. The copyrights to
the contents of this file are licensed under the Perl Artistic License
(ver. 15 Aug 1997).

=head1 AUTHOR

Algorithm, Code: Rick Reed, Ryan Hamilton, Greg Olszewski. 
Module: 2008, Mike Schilli <cpan@perlmeister.com>
