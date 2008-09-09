package Template::Provider::Preload;

=pod

=head1 NAME

Template::Provider::Preload - Preload templates to save memory in forking applications

=head1 DESCRIPTION

Experimental module to load Templates into memory in advance, to reduce
total memory load in heavily forking environments such as Apache.

=cut

use 5.006;
use strict;
use warnings;
use Params::Util       ();
use Template::Provider ();
use File::Find::Rule   ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = 'Template::Provider';
}





#####################################################################
# Bulk Preloading

sub preload {
	my $self  = shift;
	my @paths = $self->find(@_);
	foreach my $path ( @paths ) {
		$self->load($path);
	}
	return 1;
}

sub prefetch {
	my $self  = shift;
	my @paths = $self->find(@_);
	foreach my $path ( @paths ) {
		$self->fetch($path);
	}
	return 1;
}

sub find {
	my $self  = shift;
	my $paths = $self->paths;
	return $self->filter(@_)->relative->in( @$paths );
}

sub filter {
	my $self = shift;
	unless ( @_ ) {
		# Default filter
		return File::Find::Rule->new->name('*.tt')->file;
	}
	if ( Params::Util::_INSTANCE($_[0], 'File::Find::Rule') ) {
		return $_[0];
	}
	if ( defined _STRING($_[0]) ) {
		return File::Find::Rule->new->name($_[0])->file;
	}
	Carp::croak("Invalid filter param");
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Preload>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Template>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
