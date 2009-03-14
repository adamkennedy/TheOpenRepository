package Env::Constant;

use 5.006001;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.01';

sub import {
  my $class = shift;
  my $matching_keys = shift;
  $matching_keys = eval {qr/$matching_keys/}
    if defined $matching_keys and not ref($matching_keys) eq 'Regexp';
  croak("Invalid regular expression specified: $@")
    if $@;

  my ($calling_pkg) = caller();
  croak("Could not determine caller package")
    if not defined $calling_pkg or $calling_pkg eq '';

  foreach my $envkey (keys %ENV) {
    next if defined $matching_keys and $envkey !~ $matching_keys;
    if ($envkey =~ /\W/) {
      warn "The environment variable '$envkey' contains invalid characters. Must match /\\w/ for exporting";
      next;
    }

    my $varname = "${calling_pkg}::ENV_$envkey";
    my $value = $ENV{$envkey};
    no strict 'refs';
    *$varname = sub () { $value };
  }
}


1;
__END__

=head1 NAME

Env::Constant - Exporting %ENV as constants

=head1 SYNOPSIS

  use Env::Constant qr/^PAR/;
  
  # This will fail at compile time if the $ENV{PAR_PROGNAME}
  # environment variable didn't exist:
  print ENV_PAR_PROGNAME, "\n";
  
  # regular constant sub, works fully qualified, too!
  package Foo;
  print main::ENV_PAR_PROGNAME, "\n"; 

=head1 DESCRIPTION

This module exports a part or all of the environment variables in C<%ENV>
as constants with the C<ENV_> prefix. You can select the 

=head2 EXPORT

All contents of the C<%ENV> hash by default as constants with a C<ENV_> prefix.
You can limit this to a part of C<%ENV> by supplying a regular expression
for matching against the keys.

=head1 CAVEATS

You cannot export environment variables that contain characters that would be
invalid in a Perl subroutine (aka constant) name. Such environment variables
are warned about and then skipped.

=head1 SEE ALSO

C<constant>

C<perlvar>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
