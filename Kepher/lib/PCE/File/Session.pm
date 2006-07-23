package PCE::File::Session;
$VERSION = '0.11';

use strict;

# extern
sub load {
	my $file_name = PCE::Dialog::get_file_open(
		PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'open_session'},
		$PCE::config{'file'}{'current'}{'session'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'config'}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ PCE::Config::File::load($file_name) };
		if (%temp_config) {
			PCE::File::close_all();
			my $start_node = $PCE::config{'file'}{'current'}{'session'}{'node'};
			my @load_files = @{ PCE::Config::_convert_node_2_AoH(
					\$temp_config{$start_node}{'open'}
			) };
			my $start_file_nr = $temp_config{$start_node}{'current_nr'};
			@load_files = @{ &_forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			PCE::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# how many buffer we currently have and save the last doc?
			my $buffer = $PCE::internal{'document'}{'buffer'};
			PCE::Document::Internal::eval_properties($buffer-1);

			# slecting starting doc
			$start_file_nr = 0
				if (not defined $start_file_nr) or ($start_file_nr < 0 );
			$start_file_nr = $buffer - 1 if $start_file_nr >= $buffer ;

			# activate the starting document & some afterwork
			PCE::Document::Change::to_number($start_file_nr);
			PCE::Document::_set_previous_nr($start_file_nr);
			_remember_directory($file_name);
		} else {
			PCE::Dialog::warning_box(undef, $file_name,
			    $PCE::localisation{'dialog'}{'error'}{'config_parse'});
		}
	}
}

sub add {
	my $file_name = PCE::Dialog::get_file_open(
		PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'add_session'},
		$PCE::config{'file'}{'current'}{'session'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'config'}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ PCE::Config::File::load($file_name) };
		if (%temp_config) {
			my $current_doc_nr = $PCE::document{'current_nr'};
			my $prev_doc_nr    = $PCE::document{'previous_nr'};
			my $start_node
				= $PCE::config{'file'}{'current'}{'session'}{'node'};
			my @load_files = @{ PCE::Config::_convert_node_2_AoH(
					\$temp_config{$start_node}{'open'}
			) };
			@load_files = @{ _forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			PCE::Document::Internal::save_properties($current_doc_nr);
			PCE::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# make file history like before
			PCE::Document::Internal::change_pointer($current_doc_nr);
			PCE::Document::Internal::eval_properties($current_doc_nr);
			_remember_directory($file_name);
		} else {
			PCE::Dialog::warning_box(undef, $file_name,
			    $PCE::localisation{'dialog'}{'error'}{'config_parse'});
		}
	}
}

sub save {
	my $config_file = shift;
	$config_file = $PCE::internal{path}{config}
		. $PCE::config{'file'}{'current'}{'session'}{'file'}
		unless $config_file;
	my $start_node = shift;
	$start_node = $PCE::config{'file'}{'current'}{'session'}{'node'}
		unless $start_node;
	my %temp_config;
	%temp_config = %{ &PCE::Config::File::load($config_file) }
		if ( -r $config_file );
	undef $temp_config{$start_node}{'open'};
	&PCE::Config::_convert_node_2_AoH( \$PCE::document{'open'} );
	@{ $PCE::document{'open'} }
		= @{ _forget_gone_files( \$PCE::document{'open'} ) };
	@{ $temp_config{$start_node}{'open'} } = @{ $PCE::document{'open'} };
	$temp_config{$start_node}{'current_nr'} = $PCE::document{'current_nr'};
	PCE::Config::File::store( $config_file, \%temp_config );
}

sub save_as {
	my $file_name = PCE::Dialog::get_file_save( PCE::App::Window::_get(),
		$PCE::localisation{'dialog'}{'file'}{'save_session'},
		$PCE::config{'file'}{'current'}{'session'}{'directory'},
		$PCE::internal{'file'}{'filterstring'}{'config'}
	);
	if ( length($file_name) > 0 ) {
		&save( $file_name, "files" );
		_remember_directory($file_name);
	}
}

sub import_scite {
	my $win = PCE::App::Window::_get();
	my $file_name = PCE::Dialog::get_file_open( $win,
		$PCE::localisation{'dialog'}{'file'}{'open_session'},
		$PCE::internal{'path'}{'config'},
		$PCE::internal{'file'}{'filterstring'}{'scite'}
	);
	if ( -r $file_name ) {
		if ( open my $FILE, "<$file_name" ) {
			my @load_files;
			my ( $start_file_nr, $file_nr );
			while (<$FILE>) {
				m/<pos=(-?)(\d+)> (.+)/;
				if ( -e $3 ) {
					$start_file_nr = $file_nr if $1;
					$load_files[$file_nr]{'cursorpos'} = $2;
					$load_files[$file_nr++]{'path'}    = $3;
				}
			}
			if (@load_files) {
				&PCE::File::close_all;
				for (@load_files) {
					PCE::Document::Internal::add( ${$_}{'path'} );
					PCE::Edit::_goto_pos( ${$_}{'cursorpos'} );
				}
				PCE::Document::Change::to_number($start_file_nr);
				$PCE::document{'previous_nr'} = $start_file_nr;
			} else {
				PCE::Dialog::warning_box( $win, $file_name,
					$PCE::localisation{'dialog'}{'error'}{'config_parse'} );
			}
		} else {
			my $err_msg = $PCE::localisation{'dialog'}{'error'};
			PCE::Dialog::warning_box 
				($win, $err_msg->{file_read}." $file_name", $err_msg->{file});
		}
	}
}

sub export_scite {
	my $win = PCE::App::Window::_get();
	my $file_name = PCE::Dialog::get_file_save( $win,
		$PCE::localisation{'dialog'}{'file'}{'save_session'},
		$PCE::internal{'path'}{'config'},
		$PCE::internal{'file'}{'filterstring'}{'scite'}
	);
	if ( length($file_name) > 0 ) {
		if ( open my $FILE, ">$file_name" ) {
			my ( $current, $output ) = ( $PCE::document{'current_nr'}, );
			for ( 0 .. PCE::Document::_get_last_nr() ) {
				my %file = %{ $PCE::document{'open'}[$_] };
				if ( -e $file{'path'} ) {
					$output .= "<pos=";
					$output .= "-" if $_ == $current;
					$output .= "$file{cursorpos}> $file{path}\n";
				}
			}
			print $FILE $output;
		} else {
			my $err_msg = $PCE::localisation{'dialog'}{'error'};
			PCE::Dialog::warning_box
				($win, $err_msg->{file_write}." $file_name", $err_msg->{file} );
		}
	}
}

# default session handling
sub store {
	my $config = $PCE::config{'file'}{'current'}{'session'};
	save( $PCE::internal{path}{config} . $config->{'file'} )
		if $config->{'save'} eq 'extern';
}

sub restore {
	my $config = $PCE::config{'file'}{'current'}{'session'};
	my $intern = $PCE::internal{'document'};
	my @load_files;
	my $start_file_nr = $PCE::document{'current_nr'};
	$start_file_nr ||= 0;
	$PCE::document{'current_nr'} = 0;
	$PCE::internal{'document'}{'changed'}= 0;
	$PCE::internal{'document'}{'loaded'} = 0;

	# detect wich files to load
	if ( $config->{'save'} eq 'not' ) { }
	elsif ( $config->{'save'} eq 'intern' ) {
		@load_files = @{ PCE::Config::_convert_node_2_AoH( \$PCE::document{open} ) };
	} elsif ( $config->{'save'} eq 'extern' ) {
		my $file_name = $PCE::internal{path}{config} . $config->{'file'};
		my $start_node  = $config->{'node'};
		my %temp_config = %{ PCE::Config::File::load($file_name) };
		@load_files = @{
			PCE::Config::_convert_node_2_AoH( \$temp_config{$start_node}{'open'} )
		};
		$start_file_nr = $temp_config{$start_node}{'current_nr'};
	}

	# afterwork
	undef $PCE::document{'open'};
	@load_files = @{ &_forget_gone_files( \@load_files ) };

	# open remembered files with all properties
	if ( $load_files[0]{'path'} ) {
		PCE::Document::Internal::restore(\%{$load_files[$_]}) for 0..$#load_files;
	}
	# or make an emty edit panel if no doc remembered
	else { PCE::Document::Internal::reset() }




	# detect with which file to start
	$start_file_nr = 0 if ( !$start_file_nr or $start_file_nr < 0 );
	$start_file_nr = $intern->{'loaded'}-1 if 
		$start_file_nr >= $intern->{'loaded'} and $intern->{'loaded'};

	PCE::Edit::Bookmark::restore_all();
	PCE::App::EditPanel::Margin::reset_line_number_width();
	PCE::Document::Internal::eval_properties($#load_files);
	PCE::Document::Change::to_number($start_file_nr);
	PCE::Document::_set_previous_nr($start_file_nr);
}

sub delete {
	delete $PCE::document{'open'}
		if $PCE::config{'file'}{'current'}{'session'}{'save'} eq 'not' 
		or $PCE::config{'file'}{'current'}{'session'}{'save'} eq 'extern';
}

# intern
sub _forget_gone_files {
	my @true_files = ();
	my $node       = shift;
	$node = $$node if ref $node eq 'REF' and ref $$node eq 'ARRAY';
	if ( ref $node eq 'ARRAY' ) {
		my @files = @{$node};
		for ( 0 .. $#files ) {
			if ( defined $files[$_]{'path'} and -e $files[$_]{'path'} ) {
				my %file_properties = %{ $files[$_] };
				push( @true_files, \%file_properties );
			}
		}
	}
	return \@true_files;
}

sub _remember_directory {
	my ( $filename, $dir, @dirs ) = shift;
	if ( length($filename) > 0 ) {
		@dirs = split( /\\/, $filename ) if ( $filename =~ /\\/ );
		@dirs = split( /\//, $filename ) if ( $filename =~ /\// );
		$dir .= "$dirs[$_]/" for 0 .. $#dirs - 1;
		$PCE::config{'file'}{'current'}{'session'}{'directory'} = $dir if $dir;
	}

}

1;