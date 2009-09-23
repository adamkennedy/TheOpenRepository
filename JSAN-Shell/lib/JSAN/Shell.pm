package JSAN::Shell;

=pod

=head1 NAME

JSAN::Shell - JavaScript Archive Network Client Shell

=head1 DESCRIPTION

C<JSAN::Shell> provides command handling and dispatch for the L<jsan2>
user application. It interprates these commands and provides the
appropriate instructions to the L<JSAN::Client> and L<JSAN::Transport>
APIs to download and install JSAN modules.

=head2 Why Do A New Shell?

The JavaScript Archive Network, like its predecessor CPAN, is a large
system with quite a number of different parts.

In an effort to have a usable repository up, running and usable as
quickly as possible, some systems (such as the original JSAN shell)
were built with the understanding that they would be replaced by lighter,
more scalable and more comprehensive (but much slower to write)
replacements eventually.

C<JSAN::Shell> represents the rewrite of the end-user JSAN shell
component, with L<JSAN::Client> providing the seperate and more
general programmatic client interface.

=head1 METHODS

=cut

use 5.005;
use strict;
use Params::Util     '_IDENTIFIER',
                     '_INSTANCE';
use Term::ReadLine   ();
use File::HomeDir    ();
use File::ShareDir   ();
use File::UserConfig ();
use Mirror::JSON     ();
use LWP::Online      ();
use JSAN::Transport  ();
use JSAN::Index      ();
use JSAN::Client     ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '2.00_05';
}

# Locate the starting mirror.json
use constant MIRROR_INIT => File::ShareDir::dist_dir(
	'JSAN-Shell'
);





#####################################################################
# Constructor

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my %params = @_;

	# Find a terminal to use
	my $term =  _INSTANCE($params{term}, 'Term::Readline') # Use an explicitly passed terminal...
	         || $Term::ReadLine::Perl::term                # ... or an existing terminal...
	         || Term::ReadLine->new('JSAN Shell');         # ... or create a new one.

	# Create the actual object
	my $self = bless {
		prompt    => 'jsan> ',
		term      => $term,
		client    => undef,          # Create this later
		configdir => File::UserConfig->configdir,
		config    => undef,
		}, $class;

	# Are we online?
	unless ( $self->{config}->{offline} ) {
		$self->_print("Checking for Internet access...");
		unless ( LWP::Online::online('http') ) {
			$self->{config}->{offline} = 1;
		}
	}

	# Shortcut if offline
	if ( $self->{config}->{offline} ) {
		$self->_print("No direct access, offline mode enabled.");
		return $self;
	}

	# Locate the best mirror
	unless ( $self->{config}->{mirror} ) {
		$self->_print("Locating closest JSAN mirror...");
		my $mirror_yaml = Mirror::JSON->read( MIRROR_INIT );
		my @mirrors = $mirror_yaml->mirrors;
		my $mirror  = $mirrors[ int rand scalar @mirrors ];
		$self->{config}->{mirror} = $mirror;
	}

	$self;
}

sub term {
	$_[0]->{term};
}

sub prompt {
	$_[0]->{prompt};
}

# Get or create the JSAN::Client object for the shell
sub client {
	my $self = shift;
	$self->{client} or
	$self->{client} = JSAN::Client->new( %{$self->{config}} );
}

sub prefix {
	$_[0]->{config}->{prefix};
}

sub mirror {
	$_[0]->{config}->{mirror};
}

sub verbose {
	$_[0]->{config}->{verbose};
}

sub offline {
	$_[0]->{config}->{offline};
}





#####################################################################
# JSAN::Shell Main Methods

sub run {
	my $self = shift;
	$self->execute('help motd');
	while (defined(my $cmd_line = $self->term->readline($self->prompt))) {
		$cmd_line = $self->_clean($cmd_line);
		next unless length($cmd_line);
		eval { $self->execute($cmd_line) };
		if ( $@ ) {
			warn "$@\n";
		} else {
			$self->term->addhistory($cmd_line);
		}
	}
}

# Execute a single command
sub execute {
	my ($self, $line) = @_;
	my %options = (
		force  => 0,
		);

	# Split and find the command
	my @words = split / /, $line;
	my $word  = shift(@words);
	my $cmd   = $self->resolve_command($word)
		or return $self->_show("Unknown command '$word'. Type 'help' for a list of commands");

	# Is the command implemented
	my $method = "command_$cmd";
	unless ( $self->can($method) ) {
		return $self->_show("The command '$cmd' is not currently implemented");
	}

	# Hand off to the specific command
	$options{params} = \@words;
	$self->$method( %options );
}





#####################################################################
# General Commands

sub command_quit {
	my $self = shift;
	$self->_show('K TNX BYE!!!');
	exit(0);
}

sub command_help {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};

	# Get the command to show help for
	my $command = $params[0] || 'commands';
	my $method  = "help_$command";

	return $self->can($method)
		? $self->_show($self->$method())
		: $self->_show("No help page for command '$command'");
}





#####################################################################
# Investigation

sub help_a      { shift->help_author }
sub help_author { <<'END_HELP'       }
  jsan> author adamk
  
  Author ID = adamk
      Name:    Adam Kennedy
      Email:   jsan@ali.as
      Website: http://ali.as/

The "author" command is used to to locate an author and information
about them. 

It takes a single argument which should be the full JSAN identifier
for the author.
END_HELP

sub command_author {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = lc _IDENTIFIER($params[0])
		or return $self->_show("Not a valid author identifier");

	# Find the author
	my $author = JSAN::Index::Author->retrieve( login => $name );
	unless ( $author ) {
		return $self->_show("Could not find the author '$name'");
	}

	$self->show_author( $author );
}

sub help_d    { shift->help_dist }
sub help_dist { <<'END_HELP'     }
  jsan> dist JSAN
  
  Distribution   = JSAN
  Latest Release = /dist/c/cw/cwest/JSAN-0.10.tar.gz
      Version:  0.10
      Created:  Tue Jul 26 17:26:35 2005
      Author:   cwest
          Name:    Casey West
          Email:   casey@geeknest.com
          Website:
      Library:  JSAN  0.10
  
  The "dist" command is used to fetch information about a Distribution,
  including the current release package, the author, and what Libraries
  are contained in it.
  
  The dist command takes a single argument which should be the full name
  of the distribution.
  
  In the JSAN, a Distribution represents an overall product/release-series.
  Each distribution will have one or more Release package, which are the
  actual archive files in the repository, and each distribution contains
  one more more Library, which are the actual classes and APIs.
  
  For various reasons, it is occasionally necesary for a Library to move
  from one Distribution to another. For this reason, most of the time
  operations (such as installation) are done at the Library level, and the
  JSAN client will automatically determine which Distribution (and thus
  which Release package) to install.
  
  However, for cases when you do need information about the actual
  Distribution, this command is made available.
END_HELP

sub command_dist {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = $params[0];

	# Find the author
	my $dist = JSAN::Index::Distribution->retrieve( name => $name );
	unless ( $dist ) {
		return $self->_show("Could not find the distribution '$name'");
	}

	$self->show_dist( $dist );
}

sub help_l       { shift->help_library(@_) }
sub help_library { <<'END_HELP'            }
  jsan> library Test.Simple
  
  Library          = Test.Simple
      Version: 0.20
  In Distribution  = Test.Simple
  Latest Release   = /dist/t/th/theory/Test.Simple-0.20.tar.gz
      Version:  0.20
      Created:  Thu Aug 18 04:09:19 2005
      Author:   theory
          Name:    David Wheeler
          Email:   david@justatheory.com
          Website: http://www.justatheory.com/
      Library:  Test.Builder           0.20
      Library:  Test.Harness           0.20
      Library:  Test.Harness.Browser   0.20
      Library:  Test.Harness.Director  0.20
      Library:  Test.More              0.20
      Library:  Test.Simple            0.20
END_HELP

sub command_library {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = $params[0];

	# Find the library
	my $library = JSAN::Index::Library->retrieve( name => $name );
	unless ( $library ) {
		return $self->_show("Could not find the library '$name'");
	}

	$self->show_library( $library );
}

sub command_find {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = $params[0];
	my $search = "%$name%";

	# Do the search
	my @objects = ();
	push @objects, sort JSAN::Index::Author->search_like(       login  => $search );
	push @objects, sort JSAN::Index::Library->search_like(      name   => $search );
	push @objects, sort JSAN::Index::Distribution->search_like( name   => $search );
	push @objects, sort JSAN::Index::Release->search_like(      source => $search );

	# Did we find anything?
	unless ( @objects ) {
		return $self->_show( "No objects found of any type like '$name'" );
	}

	# If we only found one thing, go directly to it
	if ( @objects == 1 ) {
		if ( $objects[0]->isa('JSAN::Index::Author') ) {
			return $self->show_author( $objects[0] );
		} elsif ( $objects[0]->isa('JSAN::Index::Distribution') ) {
			return $self->show_dist( $objects[0] );
		} elsif ( $objects[0]->isa('JSAN::Index::Release') ) {
			return $self->show_release( $objects[0] );
		} else {
			return $self->show_library( $objects[0] );
		}
	}

	# Show all of the objects
	$self->show_list( @objects );
}

sub command_config {
	shift()->show_config;
}

sub command_set {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = shift(@params);
	unless ( @params ) {
		return $self->_show("Did not provide a value to set the option to");
	}

	# Handle the valid options
	if ( _IDENTIFIER($name) ) {
		return $self->command_set_verbose( @params ) if $name eq 'verbose';
		return $self->command_set_offline( @params ) if $name eq 'offline';
		return $self->command_set_mirror( @params )  if $name eq 'mirror';
		return $self->command_set_prefix( @params )  if $name eq 'prefix';
	}

	$self->_show("Invalid or unknown configuration option '$params[0]'");
}

sub command_set_verbose {
	my $self  = shift;
	my $value = shift;
	if ( $value =~ /^(?:y|yes|t|true|1|on)$/i ) {
		$self->{config}->{verbose} = 1;
		$self->_show("Verbose mode is enabled.");
	} elsif ( $value =~ /^(?:n|no|f|false|0|off)$/i ) {
		$self->{config}->{verbose} = '';
		$self->_show("Verbose mode is disabled.");
	} else {
		$self->_show("Unknown verbose mode '$value'. Try 'on' or 'off'");
	}
}

sub command_set_offline {
	my $self  = shift;
	my $value = shift;
	if ( $value =~ /^(?:y|yes|t|true|1|on)$/i ) {
		$self->{config}->{offline} = 1;
		$self->_show("Offline mode is enabled.");
	} elsif ( $value =~ /^(?:n|no|f|false|0|off)$/i ) {
		$self->{config}->{offline} = '';
		$self->_show("Offline mode is disabled.");
	} else {
		$self->_show("Unknown offline mode '$value'. Try 'on' or 'off'");
	}
}

sub command_set_mirror {
	my $self  = shift;
	my $value = shift;

	### FIXME - Once JSAN::URI works, add validation here

	# Change the mirror and reset JSAN::Transport
	$self->{config}->{mirror} = $value;


	$self->_show("mirror changed to '$value'");
}

sub command_set_prefix {
	my $self  = shift;

	# Check the prefix directory
	my $value = glob shift;
	unless ( -d $value ) {
		return $self->_show("The directory '$value' does not exist.");
	}
	unless ( -w $value ) {
		return $self->_show("You do not have write permissions to '$value'.");
	}

	# Change the prefix and flush the client
	$self->{config}->{prefix} = $value;
	$self->{client} = undef;

	$self->_show("prefix changed to '$value'");
}

sub command_pull {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = shift(@params);

	# Find the library they are refering to
	my $library = JSAN::Index::Library->retrieve( name => $name );
	unless ( $library ) {
		return $self->_show("Could not find the library '$name'");
	}

	# Mirror the file to local disk
	my $path = $library->release->mirror;
	$self->_show("Library '$name' downloaded in release file '$path'");
}

sub command_install {
	my $self   = shift;
	my %args   = @_;
	my @params = @{$args{params}};
	my $name   = shift(@params);

	# Find the library they are refering to
	my $library = JSAN::Index::Library->retrieve( name => $name );
	unless ( $library ) {
		return $self->_show("Could not find the library '$name'");
	}

	# Do we have a prefix to install to
	unless ( $self->prefix ) {
		return $self->_show("No install prefix set. Try 'set prefix /install/path'");
	}

	# Get the client object and install the package (and it's dependencies)
	$self->client->install_library($name);
}

sub show_author {
	my $self   = shift;
	my $author = shift;
	$self->_show(
		"Author ID = "  . $author->login,
		"    Name:    " . $author->name,
		"    Email:   " . $author->email,
		"    Website: " . $author->url,
		);
}

sub show_dist {
	my $self      = shift;
	my $dist      = shift;
	my $release   = $dist->latest_release;
	my $author    = $release->author;

	# Get the list of libraries in this release.
	# This only works because we are using the latest release.
	my @libraries =
		sort { $a->name cmp $b->name }
		JSAN::Index::Library->search( release => $release->id );

	# Find the max library name length and create the formatting string
	my $max = 0;
	foreach ( @libraries ) {
		next if length($_->name) <= $max;
		$max = length($_->name);
	}
	my $string = "    Library:  %-${max}s  %s";

	$self->_show(
		"Distribution   = " . $dist->name,
		"Latest Release = " . $release->source,
		"    Version: "     . $release->version,
		"    Created: "     . $release->created_string,
		"    Author:  "     . $author->login,
		"        Name:    " . $author->name,
		"        Email:   " . $author->email,
		"        Website: " . $author->url,
		map {
			sprintf( $string, $_->name, $_->version )
		} @libraries
		);
}

sub show_release {
	my $self    = shift;
	my $release = shift;
	my $dist    = $release->distribution;
	my $author  = $release->author;

	$self->_show(
		"Release    = "      . $release->source,
		"    Distribution:   " . $dist->name,
		"    Version:        " . $release->version,
		"    Created:        " . $release->created_string,
		"    Latest Release: " . ($release->latest ? 'Yes' : 'No'),
		"    Author:         " . $author->login,
		"        Name:    " . $author->name,
		"        Email:   " . $author->email,
		"        Website: " . $author->url,
		);
}

sub show_library {
	my $self    = shift;
	my $library = shift;
	my $release = $library->release;
	my $dist    = $release->distribution;
	my $author  = $release->author;

	# Get the list of libraries in this release.
	# This only works because we are using the latest release.
	my @libraries =
		sort { $a->name cmp $b->name }
		JSAN::Index::Library->search( release => $release->id );

	# Find the max library name length and create the formatting string
	my $max = 0;
	foreach ( @libraries ) {
		next if length($_->name) <= $max;
		$max = length($_->name);
	}
	my $string = "    Library:  %-${max}s  %s";

	$self->_show(
		"Library          = " . $library->name,
		"    Version: " . $library->version,
		"In Distribution  = " . $dist->name,
		"Latest Release   = " . $release->source,
		"    Version: "       . $release->version,
		"    Created: "       . $release->created_string,
		"    Author:  "       . $author->login,
		"        Name:    "   . $author->name,
		"        Email:   "   . $author->email,
		"        Website: "   . $author->url,
		map {
			sprintf( $string, $_->name, $_->version )
		} @libraries,
		);
}

sub show_list {
	my $self = shift;

	# Show each one
	my @output = ();
	foreach my $object ( @_ ) {
		if ( $object->isa('JSAN::Index::Author') ) {
			push @output, sprintf(
				"  Author:       %-10s (\"%s\" <%s>)",
				$object->login,
				$object->name,
				$object->email,
				);

		} elsif ( $object->isa('JSAN::Index::Distribution') ) {
			push @output, sprintf(
				"  Distribution: %s",
				$object->name,
				);

		} elsif ( $object->isa('JSAN::Index::Release') ) {
			push @output, sprintf(
				"  Release:      %s",
				$object->source,
				);

		} elsif ( $object->isa('JSAN::Index::Library') ) {
			push @output, sprintf(
				"  Library:      %s",
				$object->name,
				);
		}
	}

	# Summary
	push @output, "";
	push @output, "  Found "
		. scalar(@_)
		. " matching objects in the index";

	$self->_show( @output );
}
	
sub show_config {
	my $self   = shift;
	$self->_show(
		"    jsan configuration",
		"    ------------------",
		"    verbose: " . ($self->verbose ? 'enabled' : 'disabled'),
		"    offline: " . ($self->offline ? 'enabled' : 'disabled'),
		"    mirror:  " . ($self->mirror || '(none)'),
		"    prefix:  " . ($self->prefix || '(none)'),
		);
}





#####################################################################
# Localisation and Content

# For a given string, find the command for it
my %COMMANDS = (
	'q'            => 'quit',
	'quit'         => 'quit',
	'exit'         => 'quit',
	'h'            => 'help',
	'help'         => 'help',
	'?'            => 'help',
	'a'            => 'author',
	'author'       => 'author',
	'd'            => 'dist',
	'dist'         => 'dist',
	'distribution' => 'dist',
	'l'            => 'library',
	'lib'          => 'library',
	'library'      => 'library',
	'f'            => 'find',
	'find'         => 'find',
	'c'            => 'config',
	'conf'         => 'config',
	'config'       => 'config',
	's'            => 'set',
	'set'          => 'set',
	'p'            => 'pull',
	'pull'         => 'pull',
	'i'            => 'install',
	'install'      => 'install',
	);

sub resolve_command {
	$COMMANDS{$_[1]};
}




sub help_usage { <<"END_HELP" }
Usage: cpan [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_COMMAND ...]

For more details run
        perldoc -F /usr/bin/jsan
END_HELP



sub help_motd { <<"END_HELP" }
jsan shell -- JSAN repository explorer and package installer (v$VERSION)
           -- Copyright 2005 - 2007 Adam Kennedy.
           -- Type 'help' for a summary of available commands.
END_HELP



sub help_commands { <<"END_HELP" }
     ------------------------------------------------------------
   | Display Information                                          |
   | ------------------------------------------------------------ |
   | command     | argument      | description                    |
   | ------------------------------------------------------------ |
   | a,author    | WORD          | about an author                |
   | d,dist      | WORD          | about a distribution           |
   | l,library   | WORD          | about a library                |
   | f,find      | SUBSTRING     | all matches from above         |
   | ------------------------------------------------------------ |
   | Download, Test, Install...                                   |
   | ------------------------------------------------------------ |
   | p,pull      | WORD          | download from the mirror       |
   | i,install   | WORD          | install (implies get)          |
   | r,readme    | WORD          | display the README file        |
   | ------------------------------------------------------------ |
   | Other                                                        |
   | ------------------------------------------------------------ |
   | h,help,?    |               | display this menu              |
   | h,help,?    | COMMAND       | command details                |
   | c,config    |               | show all config options        |
   | s,set       | OPTION, VALUE | set a config option            |
   | q,quit,exit |               | quit the jsan shell            |
     ------------------------------------------------------------
END_HELP





#####################################################################
# Support Methods

# Clean a single command
sub _clean {
	my ($self, $line) = @_;
	$line =~ s/\s+/ /s;
	$line =~ s/^\s+//s;
	$line =~ s/\s+$//s;
	$line;
}

# Print a single line to screen
sub _print {
	my $self = shift;
	while ( @_ ) {
		my $line = shift;
		chomp($line);
		print STDOUT "$line\n";
	}
	1;
}

# Print something with a leading and trailing blank line
sub _show {
	my $self = shift;
	$self->_print( '', @_, '' );
}

1;

=pod

=head1 AUTHORS

Adam Kennedy <F<adam@ali.as>>, L<http://ali.as>

=head1 SEE ALSO

L<jsan2>, L<JSAN::Client>, L<http://openjsan.org>

=head1 COPYRIGHT

Copyright 2005 - 2007 Adam Kennedy.
 
Some parts copyright 2005 Casey West.
  
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
