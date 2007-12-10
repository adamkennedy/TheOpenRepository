package CGI::Capture::TieSTDIN;

# Small class for replacing STDIN with a provided string

sub TIEHANDLE {
	my $class   = shift;
	return bless [
		split /\n/, $_[0],
	], $class;
}

sub READLINE {
	my $self = shift;
	return wantarray ? @$self : shift @$self;
}

sub CLOSE {
	my $self = shift;
	return close $self;
}

1;
