#!/usr/bin/perl

use strict;
use warnings;
use OpenGL ':all';

my %list  = ();
my %count = ();

sub add {
	my ($long, $short) = @_;
	$count{$short}++;
	$list{$short} ||= [ ];
	push @{$list{$short}}, $long;
}

# Deduplicate the EXPORT_OK list
my %seen = ();
foreach ( @OpenGL::EXPORT_OK ) {
	my $name = $_;
	next if $seen{$name}++;
	if ( $name =~ s/^GLUT_// ) {
		add( $_, $name );
	} elsif ( $name =~ s/^GLU_// ) {
		add( $_, $name );
	} elsif ( $name =~ s/^GLX_// ) {
		add( $_, $name );
	} elsif ( $name =~ s/^GL_// ) {
		add( $_, $name );
	} elsif ( $name =~ s/^glut([^a-z])/$1/ ) {
		add( $_, $name );
	} elsif ( $name =~ s/^glu([^a-z])/$1/ ) {
		add( $_, $name );
	} elsif ( $name =~ s/^glx([^a-z])/$1/ ) {
		add( $_, $name );
	} elsif ( $name =~ s/^glp([^a-z])/$1/ ) {
		add( $_, $name );
	} elsif ( $name =~ s/^gl([^a-z])/$1/ ) {
		add( $_, $name );
	} else {
		add( $_, $_ );
	}
}

print map {
	"$count{$_} x $_ (" . join( ', ',
		map {
			($_ eq uc $_)
				? ("$_ = '" . eval("OpenGL::$_") . "'")
				: ("$_()")
		} @{$list{$_}}
	) . ")\n"
} sort {
	$count{$b} <=> $count{$a}
	or
	$a cmp $b
} grep {
	$count{$_} > 1
} keys %list;
