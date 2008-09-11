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

B<THIS MODULE IS CONSIDERED EXPERIMENTAL>

B<FUTURE CHANGES MAY RESULT IN CRITICAL API CHANGES>

B<YOU HAVE BEEN WARNED!>

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

While B<Template::Provider::Preload> is useful in other high-forking
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

Memory spent on loading templates once means enormous memory savings
across the collective children.

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
use Class::Adapter::Builder
	NEW      => 'Template::Provider',
	ISA      => 'Template::Provider',
	AUTOLOAD => 1;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Bulk Preloading

=pod

=head2 prefetch

  # Load all .tt templates into memory
  $provider->prefetch;
  
  # Load all .html and .eml templates into memory
  $provider->prefetch('*.html', '*.eml');
  
  # Load all templates inside a SVN checkout into memory
  use File::Find::Rule;
  use File::Find::Rule::VCS;
  $provider->prefetch(
      File::Find::Rule->ignore_svn->file->readable->ascii
  );

The C<prefetch> method is used to specify that a set of template
files should be immediately compiled (with the compiled templates
cached if possible) and then the compiled templates are loaded into
memory.

When used in combination with a very long C<STAT_TTL> parameter (longer than
the longest possible time between Apache restarts) the C<prefetch> method
creates a caching strategy where the templates will never be looked at once
the call to C<prefetch> has completed.

The compilation will be done via the public but undocumented
L<Template::Provider> method C<load>, so the compilation will be done
via the normal caching mechanism. If existing compiled versions exist and
there is no newer template file, then the compiled version will not be
rebuilt.

Selection of the files to compile is done via a L<File::Find::Rule> search
across all C<INCLUDE_PATH> directories. If the same file exists within more
than one C<INCLUDE_PATH> directory, only the first one will be compiled.

In the canonical usage, the C<prefetch> method takes a single parameter,
which should be a L<File::Find::Rule> object. The method will call C<file>
and C<relative> on the filter you pass in, so you should consider the
C<prefetch> method to be destructive to the filter.

As a convenience, if the method is passed a series of strings, a new
rule object will be created and the strings will be used to specific the
required files to compile via a call to the C<name> method.

As a further convenience, if the method is passed no params, a default
filter will be created for all files ending in .tt.

Returns true on success, or throws an exception (dies) on error.

=cut

sub prefetch {
	my $self   = shift;
	my $object = $self->_OBJECT_;
	my @paths  = $self->_find(@_);
	foreach my $path ( @paths ) {
		$object->fetch($path);
	}
	return 1;
}

sub _find {
	my $self  = shift;
	my $paths = $self->paths;
	my %seen  = ();
	return grep { not $seen{$_}++ } $self->_filter(@_)->relative->file->in( @$paths );
}

sub _filter {
	my $self = shift;
	unless ( @_ ) {
		# Default filter
		return File::Find::Rule->name('*.tt')->file;
	}
	if ( Params::Util::_INSTANCE($_[0], 'File::Find::Rule') ) {
		return $_[0];
	}
	my @names = grep { defined Params::Util::_STRING($_) } @_;
	if ( @names == @_ ) {
		return File::Find::Rule->name(@names)->file;
	}
	Carp::croak("Invalid filter param");
}

1;

=pod

=head1 TO DO

Have the C<prefetch> method prime the cache in a manner that does not
require the use of the C<STAT_TTL> param at all.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Provider-Preload>

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
