package CGI::Install::Demo;

=pod

=head1 NAME

CGI::Install::Demo - Demonstration CGI application for CGI::Install

=head2 DESCRIPTION

This is a trivial web applicaion designed to demonstrate the use of
L<CGI::Install> and related utilities.

Once installed, it provide some basic functionality to fill out a
form, and then echo the resulting values back to the browser.

=cut

sub new {
	my $class = shift;

	# Create the object
	my $self  = bless {
		cgi => CGI->new,
		}, $class;

	return $self;
}

sub cgi {
	$_[0]->{cgi};
}


sub print {
	my $self = shift;
	CORE::print STDOUT @_;
}

BEGIN {
	my @functions = qw{
		header start_html end_html
		p
	};
	foreach ( @functions ) {
		eval "sub print_$_ {\n\tmy \$self = shift;\n\t\$self->print( \$self->cgi->$_(\@_) );\n}\n";
		$@ and die "Failed to create method for CGI::$_";
	}
}

sub run {
	my $self = shift;
	print 
	$self->cgi->param('text')
		? $self->view_form
		: $self->view_result;
}

sub view_form {
	my $self = shift;
	$self->cgi_header;
	$self->start_html("CGI::Install::Demo $VERSION");
	$self->
1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Install-Demo>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<CGI::Install>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
