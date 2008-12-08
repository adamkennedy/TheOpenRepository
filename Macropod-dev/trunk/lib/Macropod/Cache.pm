package Macropod::Cache;

use Data::Dumper;
use DBI;
use Carp qw( cluck confess );

=pod

=head1 NAME

Macropod::Cache

=cut

sub new {
	my ($class,%args) = @_;
	my $dbh;
	my %self;
	if ( exists $args{dbfile} ) {
		$dbh = DBI->connect( 'dbi:SQLite:' . delete $args{dbfile} ,
			'' , '' , 
			(exists $args{dbargs}) 
				? delete $args{dbargs} 
				: {RaiseError=>1,AutoCommit=>0}	
		) or confess $DBI::errstr;
		$dbh->{HandleError} = sub { confess(shift) };
		
		$self{dbh} = $dbh;
	}
 	else {
		confess "dbfile not passed";
	}

	return bless \%self, ref $class || $class;

}
sub store {
	my ($self,$doc) = @_;
	my $signature = $doc->signature;
	if ( $self->get( signature => $signature ) ) {
		warn "Already stored $signature";
		return;
	}
	my $sth = $self->{dbh}->prepare_cached(
		q|insert into podcache VALUES(?,?,?,?)|
	);
	eval {
		$sth->execute( $doc->title, $doc->source , $doc->signature, $doc->yaml );
	};
	
	if ( $@ ) {
		warn "Store  of '$name' failed with '$@'";
		$self->{dbh}->rollback;
		$sth->finish;
		return;
	}
	$sth->finish;
	return $self->{dbh}->commit;
	
}

sub get {
	my ($self,$field,$name) = @_;
	my $sth = $self->{dbh}->prepare_cached(
		qq|select * from podcache where $field = ?|
	); # FIXME Bramble - yuk

	my $rc = $sth->execute( $name );
	if ( $rc ) {
		my %results;
		my $twice_total = 
			%results =  
				%{ $sth->fetchall_hashref('signature') };
						
		#warn __PACKAGE__ . " fetched $twice_total " ; 
		return unless $twice_total;
		
		while ( my $result = $sth->fetchrow_hashref ) {
			$results{$result->{signature}} = $result;
		}
		$sth->finish;
		return \%results;
	}
	else { 
		# SQL failed under us. 
		$sth->finish;
		cluck "select doc failed '$rc' $DBI::errstr ";
		return
	}
}

sub _bootstrap {
	my ($class,$file) = @_;
	warn "Bootstrapping Macropod cache at $file";
#	confess "Cannot write to $file" unless -w $file;
	my $dbh = DBI->connect( 'dbi:SQLite:' . $file )
		or confess $DBI::errstr;
	my $sql;
	{
		local $/ ; $sql = <DATA>;
		#warn $sql;
	}
	my @sql = split /;\s*/ , $sql;
	foreach my $statement ( @sql ) {
		$dbh->do( $statement ) or warn $DBI::errstr;
	}
	$dbh->commit;
	$dbh->disconnect;
	undef $dbh;
	my $cache = $class->new( dbfile=>$file );
#	$cache->store( 'Macropod::Test' , '__FILE__' , '1' , "=pod\n\nhead1 Macropod\n\n=cut\n" );
#	my $result = $cache->get( name => 'Macropod::Test' );
#	return $result->{1};

}

sub DESTROY {
	my ($self) = @_;
	if (ref $self->{dbh}) {
		#cluck "DESTROYING db handle";
		#$self->{dbh}->rollback;
		$self->{dbh}->disconnect;
	}
	
}

1;

__DATA__
drop table if exists podcache;

create table podcache (
	name ,
	file ,
	signature ,
	data ,
	UNIQUE( signature )

);

drop index if exists idx_podcache;
create index idx_podcache on podcache (name,file);



