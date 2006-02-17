package Module::AutoPackager;

=pod

=head1 NAME

Module::AutoPackager - Package up a .pm file with zero human interaction

=head1 SYNOPSIS

  my $pkg = Module::AutoPackager->new(
      # Where to get the source code from
      lib    => 'MyModule.pm',
  
      # Optionally set some explicit values
      author => 'Your Name <yourname@yourdomain.com>',
      blah   => 'blah',
      );
  
  # Save the generated package
  $pkg->save('target/directory');
  
  # Install the module
  $pkg->install;

=head1 DESCRIPTION

Far too often, the creators of Perl and the authors of various Perl-related
infrastructure preference the few instead of the many. We assume you can
use the command line, we assume you can find and read detailed technical
documentation. We assume you know as much about Perl as we do.

For any part I may have played, please consider this module my apology.

C<Module::AutoPackager> is a Perl packager and installer I<"for the rest
for us">.

I'd be calling it C<Modules::ForDummies> if it wouldn't be a horriblely
transparent trademark violation :)

The goal of C<Module::AutoPackage> is to take any basic Perl document that
is a legal module, and turn it to a full CPAN-compatible Perl distribution,
optionally go further and install it to the local system.

The basic assumptions are firstly that there is no chance for interaction,
what is generated must as complete and sane as possible, and secondly that
the only information we have is what we get passed in the constructor, with
no chance for it to be edited after the autopackaging.

=head2 How does it work?

In brief, it uses L<PPI> (the Perl Parsing Interface) to read and analyze
your code, utilities like L<Perl::MinimumVersion> and L<CPANPLUS> to work
out the dependencies for your modules, and creates a distribution using
the easy-to-learn L<Module::Install>.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp                 ();
use File::Temp           ();
use PPI                  ();
use PPI::Util            '_Document';;
use Perl::MinimumVersion ();
use Module::Install      ();
use CPANPLUS             ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the params
	
}

1;
