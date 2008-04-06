package AutoXS::Accessor;

use 5.008;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.03';

BEGIN { require AutoXS; }
use base 'AutoXS';

use B qw( svref_2object );
use B::Utils qw( opgrep op_or );
use Class::XSAccessor;

CHECK {
  warn "Running AutoXS scanner of " . __PACKAGE__ if $AutoXS::Debug;
  require AutoXS::Getter;
  require AutoXS::Setter;

  foreach (keys %{$AutoXS::ScanClasses{"".__PACKAGE__}}) {
    AutoXS::Getter->replace_getters(
      AutoXS::Getter->scan_package_callback($_, \&AutoXS::Getter::scan_getter)
    );
  }

#  foreach my $class (keys %{$AutoXS::ScanClasses{"".__PACKAGE__}}) {
#    AutoXS::Setter->scan_package_setter($class);
#  }
}

1;
__END__

=head1 NAME

AutoXS::Accessor - Identify accessors and replace them with XS

=head1 SYNOPSIS
  
  package MyClass;
  use AutoXS plugins => 'Accessor';
  # same as:
  # use AutoXS plugins => [qw(Getter Setter)];
  
  # or load all installed optimizing plugins
  use AutoXS ':all';
  
  sub new {...}
  sub get_foo { $_[0]->{foo} }
  sub set_foo { $_[0]->{foo}  = $_[1] }
  sub other_stuff {...}
  
  # get_foo and set_foo will be auto-replaced with XS and faster

=head1 DESCRIPTION

This is a wrapper for the L<AutoXS::Getter> and L<AutoXS::Setter> modules which
scan the user package (C<MyClass> above) for accessor methods of certain forms
and replace them with faster XS code.

=head1 RECOGNIZED ACCESSORS

Please see the manuals of L<AutoXS::Getter> and L<AutoXS::Setter> for the
respective lists of recognized accessors.

=head1 SEE ALSO

L<AutoXS>
L<AutoXS::Getter>
L<AutoXS::Setter>

L<Class::XSAccessor>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

