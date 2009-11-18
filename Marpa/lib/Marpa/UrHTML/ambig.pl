#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use lib 'lib';
use Fatal qw(open close);

use Carp;
use Data::Dumper;
use English qw( -no_match_vars );
use Fatal qw(open);
use Storable;

use Marpa::UrHTML;

binmode STDIN, ':utf8';

my $document;
{
    local $RS = undef;
    $document = <STDIN>;
};

my $p = Marpa::UrHTML->new( { } );
local $ENV{SHOW_AMBIGUITY} = 1;
my $value = $p->parse( \$document );

__END__
