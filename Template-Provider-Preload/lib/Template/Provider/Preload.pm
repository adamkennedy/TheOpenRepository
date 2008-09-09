package Template::Provider::Preload;

=pod

=head1 NAME

Template::Provider::Preload - Preload templates to save memory when forking

=head1 SYNOPSIS

  # Create the provider
  my $provider = Template::Provider::Preload->new(
      STAT_TTL     => 31536000, # 1 year (possibly too short)
      INCLUDE_PATH => 'my/templates',
      COMPILE_DIR  => 'my/cache',
  );
  
  # Precompile all of the templates into the cache
  $provider->precompile('*.*');
  
  # Preload the .html files into memory now
  $provider->prefetch('*.html');
  
  # Create the Template with the (cache-bloated) provider
  my $template = Template->new(
      LOAD_TEMPLATES => [ $provider ],
  );

=head1 DESCRIPTION

One of the nicer things that the Template Toolkit modules do in the default
L<Template::Provider> is provide several different caching features.

The first mechanism is to cache the result of the slow and expensive
compilation phase, storing the Perl version of the template in a specific
cache directory. This mechanism is disabled by default, and enabled with
the COMPILE_DIR parameter.

The second is that the compiled templates will be cached in memory the
first time they are used, based on template path. By default, this is
enabled and permitted to grow to infinite size. It can be limited or
disabled via the CACHE_SIZE param.

The default cache strategy works just fine in a single-process application,
and in fact in many cases are a reasonably optimum caching strategy.

However, the default cache strategy can perform horribly in several
situations relating to large-scale and high-demand applications.

B<Template::Provider::Preload> can be used to set caching strategies that
are more appropriate for various types of heavily forking applications,
such as large clustered high-traffic mod_perl systems.

While Template::Provider::Preload is useful in other high-forking
scenarios, we use the (dominant) example of a forking Apache application
in all of the following examples. You should be able to exchange all uses
of terms like "Apache child" with your equivalent interchangably.

=head2 High-Security Use Case

In some very high security environments, the web user will not have the
right to create any files whatsoever, including temporary files.

This prevents the use of the compilation cache, and the template update
checks in the provider greatly complicate the possibility of building
the cache in advance offsite.

By allowing all templates to be compiled to memory in advance, you can
use templates at their full speed without the penalty of parsing and
compiling every template once per Apache child process.

Most of the following cases also assume a well-control static production
environment, where the template content will not change (and a web server
restart is done each time a new version of the application is deployed).

=head2 Large Template Use Case

Under the default cache strategy (with a compilation directory enabled)
the first Apache child that uses each template will compile and cache
the template. Each Apache child that uses the templates will then need
to separately load the compiled templates into memory.

With web servers having 20 or 50 or 100 child processes each, templates
that expand into 10 meg of memory overhead for a single process (which can
be quite possible with large templates) can easily expand into a gigabyte
of memory that contributes nothing other than to eat into your object
or disk caches.

With large numbers of large templates on high-core serves with many many
child processes, you can even put yourself in the situation of needing
to requisition additional web front ends due to memory contraints,
rather than CPU constraints.

=head2 Networked-Storage Cluster Use Case

In cluster environments where all front-end servers will use a common
back-end network-attached storage server, reducing the number of disk
interations (both reads and stats) is important to reduce (or if possible
eliminate entirely) traffic to the critical storage server.

This serves a triple purpose of reducing the size and cost of network
and storage equipment, allowing additional front-end growth without
requiring upgrades to network and storage, and eliminating potentially
high-latency network requests.

By compiling and loading all templates in advance, in combination with
a very high STAT_TTL setting to disable update checking, you can create
an environment in which the individual Apache children will not need
issue network filesystem requests at all for their templates.

=head1 METHODS

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

=pod

=head2 precompile

  # Load all .tt templates
  $provider->precompile;
  
  # Load all .html and .eml templates
  $provider->precompile('*.html', '*.eml');
  
  # Precompile all templates inside a SVN checkout
  use File::Find::Rule;
  use File::Find::Rule::VCS;
  $provider->precompile(
      File::Find::Rule->ignore_svn->file->readable->ascii
  );

The C<precompile> method is used to specify that a set of template
files should be immediately compiled and cached.

The compilation will be done via the public but undocumented
L<Template::Provider> method C<load>, so the compilation will be done
via the normal caching mechanism. If existing compiled versions exist and
there is no newer template file, then the compiled version will not be
rebuilt.

Selection of the files to compile is done via a L<File::Find::Rule> search
across all C<INCLUDE_PATH> directories. If the same file exists within more
than one C<INCLUDE_PATH> directory, only the first one will be compiled.



=cut

sub precompile {
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
		return File::Find::Rule->name('*.tt')->file;
	}
	if ( Params::Util::_INSTANCE($_[0], 'File::Find::Rule') ) {
		return $_[0];
	}
	my @names = grep { defined Params::Util::_STRING($_) } @_;
	if ( @names ) {
		return File::Find::Rule->name(@names)->file;
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
