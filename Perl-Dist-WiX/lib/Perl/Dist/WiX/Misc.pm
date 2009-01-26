package Perl::Dist::WiX::Misc;

####################################################################
# Perl::Dist::WiX::Misc - Miscellaneous routines for Perl::Dist::WiX. 
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Wix.pm for details.
#
# NOTE: This is a base class with miscellaneous routines.  It is 
# meant to be subclassed, as opposed to creating objects of this 
# class directly.

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak verbose confess       };
use Params::Util qw{ _STRING  _POSINT _NONNEGINT };

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_07';
}

#####################################################################
# Constructor for Misc
#
# Parameters:
#   None used by this class, but puts its parameters into a 
#   blessed hashref for subclasses to use.
#   Checks for non-paired parameters.

sub new {
    my $class = shift;
    
#    if ($#_ % 2 == 0) {    
#        require Data::Dumper;
#        
#        my $dump = Data::Dumper->new([\@_], [qw(*_)]);
#        print $dump->Indent(1)->Dump();
#        
#        confess "uh oh";
#    }
    
    bless { @_ }, $class;
}

#####################################################################
# Main Methods

########################################
# indent($spaces, $string)
# Parameters:
#   $spaces: Number of spaces to indent $string.
#   $string: String to indent.
# Returns:
#   Indented $string.

sub indent {
    my ($self, $num, $string) = @_;
    
    # Check parameters.
    unless ( _STRING($string) ) {
        croak("Missing or invalid string param");
    }
    unless ( defined _NONNEGINT($num) ) {
        croak("Missing or invalid num param");
    }
    
    # Indent string.
    my $spaces = q{ } x $num;
    my $answer = $spaces . $string;
    chomp $answer;
    $answer =~ s{\n        # match a newline and add spaces after it. (i.e. the beginning of the line.)
               }{\n$spaces}gxms;
               
    return $answer;
}

1;
