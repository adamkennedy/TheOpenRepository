package Perl::Dist::WiX::Misc;

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak verbose confess       };
use Params::Util qw{ _STRING  _POSINT _NONNEGINT };

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_05';
}

sub new {
    my $class = shift;
    
    if ($#_ % 2 == 0) {    
    require Data::Dumper;
    
    my $dump = Data::Dumper->new([\@_], [qw(*_)]);
    print $dump->Indent(1)->Dump();
    
    confess "uh oh";

    }
    
    bless { @_ }, $class;
}

sub indent {
    my ($self, $num, $string) = @_;
    
    unless ( _STRING($string) ) {
        croak("Missing or invalid string param");
    }
    
    unless ( defined _NONNEGINT($num) ) {
        croak("Missing or invalid num param");
    }
    
    my $spaces = q{ } x $num;
    
    my $answer = $spaces . $string;
    chomp $answer;
    $answer =~ s{\n        # match a newline and add spaces after it. (i.e. the beginning of the line.)
               }{\n$spaces}gxms;
    return $answer;
}

1;