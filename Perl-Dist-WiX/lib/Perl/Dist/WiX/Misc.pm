package Perl::Dist::WiX::Misc;

=pod

=head1 NAME

Perl::Dist::WiX::Misc - Miscellaneous routines for Perl::Dist::WiX.

=head1 DESCRIPTION

This is a base class with miscellaneous routines.  It 
is meant to be subclassed, as opposed to creating objects of this 
class directly.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak verbose confess       };
use Params::Util qw{ _STRING  _POSINT _NONNEGINT };

use vars qw{$VERSION};
BEGIN {
    $VERSION = '0.11_06';
}

=head2 new

The B<new> method creates a new object.

It is meant to be overriden by other classes.  There are no 
parameters handled by this class. 

=cut

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

=head2 indent($spaces, $string)

The B<indent> method indents $string by the number of spaces 
specified in $spaces.

    my $string_out = indent(2, $string_in)

=cut

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

=head1 SUPPORT

No support of any kind is provided for this module

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
