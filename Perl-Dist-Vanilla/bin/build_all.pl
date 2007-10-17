#!perl
use strict;
use warnings;
use Perl::Dist::Builder;

my $pdb = Perl::Dist::Builder->new( "vanilla.yml" );
$pdb->remove_image;
$pdb->build_all;
