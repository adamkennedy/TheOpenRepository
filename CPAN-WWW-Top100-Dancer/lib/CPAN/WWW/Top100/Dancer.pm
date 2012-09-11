package CPAN::WWW::Top100::Dancer;

=pod

=head1 NAME

CPAN::WWW::Top100::Dancer - CPAN Top100 like website using Dancer

=head1 DESCRIPTION

This is an experimental website implementing a variety of functionality
similar to the original CPAN Top100 website, but based on L<CPANDB> and
implemented using L<Dancer>.

=cut

use 5.008;
use strict;
use warnings;
use Dancer ':syntax';
use CPANDB {
	array => 0,
};

our $VERSION = '0.01';





######################################################################
# General Routes

get '/' => sub {
	template 'index';
};





######################################################################
# Author Routes

get '/author' => sub {
	template 'authors';
};

get '/author/:id' => sub {
	my $this = CPANDB::Author->load( params->{id} );

	template 'author' => {
		this => $this,
		json => to_yaml( { %$this } ),
	};
};





######################################################################
# Module Routes

get '/module' => sub {
	template 'modules';
};

get '/module/:id' => sub {
	my $this = CPANDB::Module->load( params->{id} );

	template 'module' => {
		this => $this,
		json => to_yaml( { %$this } ),
	};
};





######################################################################
# Distribution Routes

get '/distribution' => sub {
	template 'distributions';
};

get '/distribution/:id' => sub {
	my $this = CPANDB::Distribution->load( params->{id} );

	template 'distribution' => {
		this => $this,
		json => to_yaml( { %$this } ),
	};
};

get '/distribution/:id/graph' => sub {
	my $this  = CPANDB::Distribution->load( params->{id} );
	my $graph = $this->dependency_graphviz(
		perl    => '5.008',
		rankdir => 1,
		params,
	)->as_png;

	content_type 'image/png';
	return $graph;
};





######################################################################
# Support Functions

true;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-WWW-Top100-Dancer>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
