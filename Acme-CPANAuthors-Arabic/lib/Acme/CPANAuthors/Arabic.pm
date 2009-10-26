package Acme::CPANAuthors::Arabic;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';


use Acme::CPANAuthors::Register (
	AZAWAWI      => "Ahmad M. Zawawi (azawawi)",
	NKH          => "Nadim Khemir (nkh)",
);

1; # End of Acme::CPANAuthors::Arabic

__END__

=head1 NAME

Acme::CPANAuthors::Arabic - We are the Arabic-speaking CPAN authors

=head1 SYNOPSIS

use Acme::CPANAuthors;

   my $authors  = Acme::CPANAuthors->new("Arabic");

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions("azawawi");
   my $url      = $authors->avatar_url("nkh");
   my $kwalitee = $authors->kwalitee("nkh");
   my $name     = $authors->name("azawawi");
 
=head1 DESCRIPTION

This class provides a hash of Arabic CPAN authors' PAUSE ID and name to 
the C<Acme::CPANAuthors> module.

=head1 MAINTENANCE

If you are a Arabic CPAN author not listed here, please send me your ID/name 
via email or RT so we can always keep this module up to date. If there's a 
mistake and you're listed here but are not Arabic (or just don't want to be 
listed), sorry for the inconvenience: please contact me and I'll remove the 
entry right away.

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-cpanauthors-arabic at 
rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Arabic>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Acme::CPANAuthors::Arabic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-Arabic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-Arabic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-Arabic>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-Arabic/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Ahmad M. Zawawi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.