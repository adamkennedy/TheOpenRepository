package Perl::Dist::WiX::BuildPerl;

=pod

=head1 NAME

Perl::Dist::WiX::ReleaseNotes - 4th generation Win32 Perl distribution builder

=head1 VERSION

This document describes Perl::Dist::WiX::ReleaseNotes version 1.100.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
make the distributions.txt and the release notes files.  

=head1 SYNOPSIS

	# This module is not to be used independently.

=head1 INTERFACE

=cut

#<<<
use     5.008001;
use     strict;
use     warnings;
use     vars                  qw( $VERSION                   );
use     English               qw( -no_match_vars             );
use     File::Spec::Functions qw(
	catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use     File::Remove          qw();
use     File::pushd           qw();
use     File::ShareDir        qw();
use     IO::File              qw();
use     Template              qw();
use     Win32                 qw();

use version; $VERSION = version->new('1.100')->numify;

#>>>

sub release_notes_filename {
	my $self = shift;
	my $filename = $self->perl_version_human
		. q{.} . $self->build_number
		. ($self->beta_number ? '.beta' : '')
		. '.html';
	
	return $filename;
}

sub create_release_notes {
	my $self = shift;
	my $dist_list;
	my ( $name, $ver );

	foreach my $dist ( @{ $self->{distributions_installed} } ) {
		( $name, $ver ) = $dist =~ m{(.*)-(?:v?)([0-9\._]*)}msx;
		$dist_list .= "<tr><td>$name</td><td>$ver</td></tr>\n";
	}

	my @time = localtime;
	my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	
	my $dist_txt;
	my $vars = {
		dist      => $self,
		dist_list => $dist_list,
		dist_date => sprintf "%02i %s %4i", $time[2], $months($time[3]), $time[4] + 1900,
	};

	my $tt = Template->new(
		INCLUDE_PATH => [ $self->dist_dir, $self->wix_dist_dir, ],
		ABSOLUTE     => 1,
	  )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => Template->error(),
	  );

	$tt->process( 'release_notes.html.tt', $vars, \$dist_txt )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => $tt->error(),
	  );

	my $dist_file = catfile( $self->output_dir, $self->release_notes_filename );
	my $fh = IO::File->new( $dist_file, 'w' );

	$self->trace_line( 2, "Creating release notes at $dist_file\n" );

	if ( not defined $fh ) {
		PDWiX->throw(
			"Could not open file $dist_file for writing [$!] [$^E]");
	}
	$fh->print($dist_txt);
	$fh->close;
	
	return $dist_file;
}


#####################################################################
# DISTRIBUTIONS.txt

# NOTE: "The object that called it" is supposed to be a Perl::Dist::WiX 
# object.

=head2 create_distribution_list

The C<create_distribution_list> method creates the DISTRIBUTIONS.txt file
that contains the list of distributions that are installed, and adds it to
the .msi.

=cut

sub _add_to_distributions_installed {
	my $self = shift;
	my $dist = shift;
	$self->{distributions_installed} =
	  [ @{ $self->{distributions_installed} }, $dist ];

	return;
}

sub create_distribution_list {
	my $self = shift;
	my $dist_list;
	my ( $name, $ver );

	foreach my $dist ( @{ $self->{distributions_installed} } ) {
		( $name, $ver ) = $dist =~ m{(.*)-(?:v?)([0-9\._]*)}msx;
		$dist_list .= "    $name $ver\n";
	}

	my $dist_txt;
	my $vars = {
		dist      => $self,
		dist_list => $dist_list
	};

	my $tt = Template->new(
		INCLUDE_PATH => [ $self->dist_dir, $self->wix_dist_dir, ],
		ABSOLUTE     => 1,
	  )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => Template->error(),
	  );

	$tt->process( 'DISTRIBUTIONS.txt.tt', $vars, \$dist_txt )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => $tt->error(),
	  );

	my $dist_file = catfile( $self->image_dir, q{DISTRIBUTIONS.txt} );
	my $fh = IO::File->new( $dist_file, 'w' );

	$self->trace_line( 2, "Creating distribution list at $dist_file\n" );

	if ( not defined $fh ) {
		PDWiX->throw(
			"Could not open file $dist_file for writing [$!] [$^E]");
	}
	$fh->print($dist_txt);
	$fh->close;

	$self->add_to_fragment( 'perl', [$dist_file] );

	return;
} ## end sub create_distribution_list

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
