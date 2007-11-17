package Template::Plugin::Dumpvar;

=pod

=head1 NAME

Template::Plugin::Dumpvar - Dump template data in the same style as the
debugger

=head1 SYNOPSIS

  [% USE Dumpvar %]
  
  [% Dumpvar.dump(this) %]
  [% Dumpvar.dump_html(theother) %]

=head1 DESCRIPTION

When dumping data in templates, the obvious first choice is to use the
L<Data::Dumper> plugin L<Template::Plugin::Dumper>. But personally, I think
the layout is ugly and hard to read. It's designed to be parsed back in by
perl, not to necesarily be easy on the eye.

The dump style used in the debugger, however, IS designed to be easier on
the eye. The dumpvar.pl script it uses to do this has been cloned for general
use as L<Devel::Dumpvar>. This module is a drop in replacement for
Template::Plugin::Dumper that uses Devel::Dumpvar in place of Data::Dumper.

The only difference is that this module only dumps one scalar, reference, or
object at a time.

=head1 METHODS

=cut

use strict;
use Devel::Dumpvar ();
use base 'Template::Plugin';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor

sub new {
	my $class = ref $_[0] || $_[0];
	bless {
		Dumpvar => Devel::Dumpvar->new( to => 'return' ),
		}, $class;
}

=pod

=head2 dump $something

Dumps a single structure via L<Devel::Dumpvar>. Does not escape for HTML.

=cut

sub dump {
	my $self = shift;
	$self->{Dumpvar}->dump( shift );
}

=pod

=head2 dump_html $something

As above, but also escapes and formats for HTML

=cut

sub dump_html {
	my $self = shift;
	$_ = $self->dump(shift) or return $_;

	# Escape for HTML
	s/&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/\n/<br>\n/g;

	$_;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template%3A%3APlugin%3A%3ADumpvar>

For other issues, or commercial enhancement or support, contact the author..

=head1 AUTHOR

Adam Kennedy (Maintainer), L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Thank you to Phase N Australia (L<http://phase-n.com/>) for permitting the
open sourcing and release of this distribution as a spin-off from a
commercial project.

Copyright (c) 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
