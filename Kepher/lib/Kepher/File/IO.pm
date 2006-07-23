package KEPHER::File::IO;
$VERSION = '0.14';

use strict;

# read a file into a scintilla buffer, is much faster then open_buffer
sub open_pipe {
	my $file_name  = shift;
	my $edit_panel = KEPHER::App::STC::_get();
	my $err_txt    = \$KEPHER::localisation{'dialog'}{'error'};
	my $input;
	unless ($file_name) {
		KEPHER::Dialog::warning_box( undef,
			"file_read " . $err_txt->{'no_param'}, $err_txt->{'general'} );
	} else {
		unless ( -r $file_name ) {
			KEPHER::Dialog::warning_box( undef,
				$err_txt->{'file_read'} . " " . $file_name, $err_txt->{'file'} );
		} else {
			open my $FILE, "<$file_name"
				or KEPHER::Dialog::warning_box( undef,
				$err_txt->{'file_read'} . " $file_name", $err_txt->{'file'} );
			binmode $FILE;    #binmode(FILE, ":encoding(cp1252)")
			while ( ( read $FILE, $input, 500000 ) > 0 ) {
				$edit_panel->AddText($input);
			}
			return 1;
		}
	}
}

# reading file into buffer variable
sub open_buffer {
	my ($file_name) = (@_);
	my $err_txt = \$KEPHER::localisation{'dialog'}{'error'};
	my ( $buffer, $input );
	unless ($file_name) {
		KEPHER::Dialog::warning_box( undef,
			"file_read " . $err_txt->{'no_param'},
			$err_txt->{'general'} );
	} else {
		unless ( -r $file_name ) {
			KEPHER::Dialog::warning_box( undef,
				$err_txt->{'file_read'} . " " . $file_name, $err_txt->{'file'} );
		} else {
			open my $FILE, "<$file_name"
				or KEPHER::Dialog::warning_box( undef,
				$err_txt->{'file_read'} . " $file_name", $err_txt->{'file'} );
			binmode $FILE;    #binmode(FILE, ":encoding(cp1252)")
			while ( ( read $FILE, $input, 500000 ) > 0 ) { $buffer .= $input }
		}
	}
	return $buffer;
}

# wite into file from buffer variable
sub write_buffer {
	my ( $file_name, $text ) = @_;
	my $err_txt = \$KEPHER::localisation{'dialog'}{'error'};
	# check if there is a name or if file that you overwrite is locked
	unless ($file_name and not(-e $file_name and not -w $file_name) ) {
		KEPHER::Dialog::warning_box( undef,
			"file_write " . $err_txt->{'no_param'}, $err_txt->{'general'} );
	} else {
		open my $FILE, ">$file_name"
			or KEPHER::Dialog::warning_box( undef,
			$err_txt->{'file_write'} . " $file_name", $err_txt->{'file'} );
		binmode $FILE;
		print $FILE $text;
	}
}

1;
