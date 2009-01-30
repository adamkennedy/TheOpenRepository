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
#
# $Rev$ $Date$ $Author$
# $URL$

use 5.006;
use strict;
use warnings;
use Carp                  qw( croak                       );
use Params::Util          qw( _STRING  _POSINT _NONNEGINT );
use File::Spec::Functions qw( splitpath splitdir          );

use vars qw( $VERSION );
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

########################################
# trace_line($text)
# Parameters:
#   $tracelevel: Level of trace to print at.
#   $text: Text to print if trace flag is >= $tracelevel.
# Returns:
#   Indented $string.

sub trace_line {
    my ($self, $tracelevel, $text, $no_display) = @_;

    # Check parameters and object state.
    unless ( defined _NONNEGINT($tracelevel) ) {
        croak("Missing or invalid tracelevel");
    }
    unless ( defined _NONNEGINT($self->{trace}) ) {
        croak("Inconsistent trace state in $self");
    }
    unless ( defined _STRING($text) ) {
        croak("Missing or invalid text");
    }
    
    my $test_trace = 0;
    my $tracelevel_status = $self->{trace};
    if ($tracelevel_status >= 100) {
        $tracelevel_status -= 100;
        $test_trace = 1;
        require Test::More;
    }
    
    $no_display = 0 unless defined $no_display;
        
    if ($tracelevel_status >= $tracelevel) {
        my $start = q{};
    
        if (not $no_display) {
            if ($tracelevel_status > 1) {
                $start = "[$tracelevel] ";
            }
            if (($tracelevel > 2) or ($tracelevel_status > 4)) {
                my (undef, $filespec, $line, undef, undef, undef, undef, undef, undef, undef) = caller(0);
                my (undef, $path, $file) = splitpath($filespec);
                my @dirs = splitdir($path);
                pop @dirs if ((not defined $dirs[-1]) or ($dirs[-1] eq q{}));
                $file = $dirs[-1] . '\\' . $file if ((defined $dirs[-2]) and ($dirs[-2] eq 'WiX')); 
                $start .= "[$file $line] ";
            }
            $text =~ s{\n}              # Replace a newline that isn't at the end-of-string
                      {\n$start}gmsx;   # with a newline and the start string.
            $text =~ s{\n\Q$start\E\z}{\n}gms; # Replace the newline and start string at the end with just the newline. 
        }
        if ($test_trace) {
            Test::More::diag("$start$text");
        } elsif ($tracelevel == 0) {
            print STDERR "$start$text";
        } else {
            print "$start$text";
        }
    }
    
    return $self;
}

1;
