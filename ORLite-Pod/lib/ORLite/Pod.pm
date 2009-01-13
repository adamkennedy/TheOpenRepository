package ORLite::Pod;

use 5.006;
use strict;
use Carp         ();
use File::Spec   ();
use Params::Util qw{_CLASS};
use ORLite       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless (
		_CLASS($self->from)
		and
		$self->from->can('orlite')
	) {
		die("Did not provide a 'from' ORLite root class to generate from");
	}
	my $to = $self->to;
	unless ( $self->to ) {
		die("Did not provide a 'to' lib directory to write into");
	}
	unless ( -d $self->to ) {
		die("The 'to' lib directory '$to' does not exist");
	}
	unless ( -w $self->to ) {
		die("No permission to write to directory '$to'");
	}

	return $self;
}

sub from {
	$_[0]->{from};
}

sub to {
	$_[0]->{to};
}





#####################################################################
# POD Generation

sub run {
	my $self = shift;
	my $dbh  = $self->from->dbh;

	# Capture the raw schema information
	my $tables = $dbh->selectall_arrayref(
		'select * from sqlite_master where type = ?',
		{ Slice => {} }, 'table',
	);
	foreach my $table ( @$tables ) {
		$table->{columns} = $dbh->selectall_arrayref(
			"pragma table_info('$table->{name}')",
		 	{ Slice => {} },
		);
	}

	# Generate the main additional table level metadata
	my %tindex = map { $_->{name} => $_ } @$tables;
	foreach my $table ( @$tables ) {
		my @columns      = @{ $table->{columns} };
		my @names        = map { $_->{name} } @columns;
		$table->{cindex} = map { $_->{name} => $_ } @columns;

		# Discover the primary key
		$table->{pk}     = List::Util::first { $_->{pk} } @columns;
		$table->{pk}     = $table->{pk}->{name} if $table->{pk};

		# What will be the class for this table
		$table->{class}  = ucfirst lc $table->{name};
		$table->{class}  =~ s/_([a-z])/uc($1)/ge;
		$table->{class}  = "${pkg}::$table->{class}";

		# Generate various SQL fragments
		my $sql = $table->{sql} = { create => $table->{sql} };
		$sql->{cols}     = join ', ', map { '"' . $_ . '"' } @names;
		$sql->{vals}     = join ', ', ('?') x scalar @columns;
		$sql->{select}   = "select $table->{sql}->{cols} from $table->{name}";
		$sql->{count}    = "select count(*) from $table->{name}";
		$sql->{insert}   = join ' ',
			"insert into $table->{name}" .
			"( $table->{sql}->{cols} )"  .
			" values ( $table->{sql}->{vals} )";
	}

	# Generate the foreign key metadata
	foreach my $table ( @$tables ) {
		# Locate the foreign keys
		my %fk     = ();
		my @fk_sql = $table->{sql}->{create} =~ /[(,]\s*(.+?REFERENCES.+?)\s*[,)]/g;

		# Extract the details
		foreach ( @fk_sql ) {
			unless ( /^(\w+).+?REFERENCES\s+(\w+)\s*\(\s*(\w+)/ ) {
				die "Invalid foreign key $_";
			}
			$fk{"$1"} = [ "$2", $tindex{"$2"}, "$3" ];
		}
		foreach ( @{ $table->{columns} } ) {
			$_->{fk} = $fk{$_->{name}};
		}
	}


}

sub write_root {
	my $self   = shift;
	my $tables = shift;

	# Determine the file we're going to be writing to
	my $from = $self->from;
	my $file = File::Spec->catfile( split /::/, $from ) . '.pod'

	# Start writing the file
	local *FILE;
	open( FILE, '>', $file ) or die "open: $!";
	print FILE <<'END_POD';
=head1 NAME

$from - An ORLite-based ORM Database API

=head1 SYNOPSIS

  TO BE COMPLETED

=head1 DESCRIPTION

TO BE COMPLETED

=head1 METHODS

END_POD

	# Add pod for each method that is in the 
}

1;
