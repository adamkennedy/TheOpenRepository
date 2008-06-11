package Template::Plugin::NakedBody;

=pod

=head1 NAME

Template::Plugin::NakedBody - Strip HTML wrapping to get just the naked body

=head1 SYNOPSIS

  # _included.html
  <html>
  <head>
    <style ...>
  </head>
  <body>
  This is content we need the stylesheet to see properly.
  </body>
  </html>
  
  # mypage.html
  [% USE NakedBody %]
  <html>
  <head>
    <style ...>
  </head>
  <body>
  Some content
  [% INCLUDE _included.html | NakedBody %]
  Some more content
  </body>
  </html>

=head1 DESCRIPTION

The things we do to support designers...

When you are including a big chunk of HTML into a page via an include, you
can have problems editing it in WYSIWYG editors because it won't have the
stylesheets and javascript libs that the main document does.

So for the sake of designers, the best solution is to provide the includes
with full HTML headers, including proper styles and so on. They can do what
they like in Dreamweaver or Editor De Jour. Then when including, we strip
the wrapping off to get just the content.

And that's what this module does. It removes everything to keep only what
is B<inside> the body tags.

=cut
    
use strict;
use base 'Template::Plugin::Filter';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Template::Plugin::Filter Methods

sub init {
	my $self = shift;
	my $name = $self->{_CONFIG}->{name} || 'NakedBody';
	$self->install_filter($name);
	$self;
}

sub coderef {
	\&_filter;
}

sub filter {
	my ($self, $text) = @_;
	_filter( $text );
}

sub _filter {
	my $text = shift;	

	# Strip away everything before the <body> tag
	$text =~ s/\A.*?<body.*?>//is;
	$text =~ s/<\/body>.*?\z//is;

	$text;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-NakedBody>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy , L<http://ali.as/>, cpan@ali.as

=head1 ACKOWLEDGEMENTS

Thank you to Phase N Australia (L<http://phase-n.com/>) for permitting the
open sourcing and release of this distribution as a spin-off from a
commercial project.

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
