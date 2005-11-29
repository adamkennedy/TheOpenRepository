package PITA::Report::Distribution;

=pod

=head1 NAME

PITA::Report::Distribution - Data object representing a single distribution

=head1 SYNOPSIS

  # Create a distribution specification
  my $dist = PITA::Report::Distribution->new(
  	distname => 'PITA-Report',
  	filename => '...',
  	md5sum   => '0123456789ABCDEF0123456789ABCDEF',
  	# Optional path within CPAN
  	cpanpath => '...',
  	);

=head1 DESCRIPTION

C<PITA::Report::Distribition> is an object for holding information about
a distribution to be tested. It is created most often as part of the
parsing of a L<PITA::Report> XML file.

It holds the name of the distribition, an MD5 sum used for error checking
purposes, and some paths (private and CPAN).

=head1 METHODS

=cut

use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the object
	$self->_init;

	$self;
}

# Format-check the parameters
sub _init {
	my $self = shift;

	# Arbitrarily apply the normal standard for distributions
	### Might need to change this down the line
	my $distname = $self->{distname};
	unless ( 
		defined $distname and ! ref $distname
		and
		$distname =~ /^[a-z]+(?:\-[a-z]+)+$/is
	) {
		Carp::croak('Invalid distname');
	}

	# Check the filepath
	my $filename = $self->{filename};
	unless (
		defined $filename and ! ref $filename
		and
		length $filename
	) {
		Carp::croak('Invalid filename');
	}

	# Check the md5sum
	my $md5sum = $self->{md5sum};
	unless (
		defined $md5sum and ! ref $md5sum
		and
		$md5sum =~ /^[0-9a-f]{32}$/i
	) {
		Carp::croak('Invalid md5sum');
	}

	# Normalise the md5sum
	$self->{md5sum} = lc $self->{md5sum};

	# Check the cpanpath
	if ( $self->{cpanpath} ) {
		# Check the filepath
		my $cpanpath = $self->{cpanpath};
		unless (
			defined $cpanpath and ! ref $cpanpath
			and
			length $cpanpath
		) {
			Carp::croak('Invalid cpanpath');
		}	
	} else {
		$self->{cpanpath} = '';
	}

	1;
}

=pod

=head2 distname

The C<distname> accessor returns the name of the distribution as a string.

Most often, this would be something like 'Foo-Bar' with a primary focus on
the class Foo::Bar.

=cut

sub distname {
	$_[0]->{distname};
}

=pod

=head2 filename

The C<filename> accessor returns ...

=cut

sub filename {
	$_[0]->{filename};
}

=pod

=head2 md5sum

The C<md5sum> accessor returns the MD5 sum for package. This is only used
as a CRC and isn't assumed to be cryptographically secure.

=cut

sub md5sum {
	$_[0]->{md5sum};
}

=pod

=head2 cpanpath

When testing CPAN distributions, the C<cpanpath> returns the path for
the distribution file within the CPAN.

For non-CPAN distributions, returns false (the null string).

=cut

sub cpanpath {
	$_[0]->{cpanpath};
}

1;


=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Report>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::Report>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
