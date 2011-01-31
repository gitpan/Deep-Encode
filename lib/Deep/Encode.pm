package Deep::Encode;
use strict;
use warnings;

require Exporter;
require Encode;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Deep::Encode ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
	all => [ qw( 
		deep_utf8_check
		deep_utf8_off
		deep_utf8_on
		deep_utf8_upgrade
		deep_utf8_downgrade
		deep_utf8_decode
	   	deep_utf8_encode
	   	deep_from_to
		deep_encode
		deep_decode

		deep_str_clone

		deepc_utf8_upgrade
		deepc_utf8_downgrade
		deepc_utf8_decode
	   	deepc_utf8_encode
	   	deepc_from_to
		deepc_encode
		deepc_decode

		) ], 
	 );

our @EXPORT_OK = ( map @$_, map  $EXPORT_TAGS{$_} , 'all' );

our @EXPORT =  ( map @$_, map  $EXPORT_TAGS{$_} , 'all');

our $VERSION = '0.18';

require XSLoader;
XSLoader::load('Deep::Encode', $VERSION);

sub deepc_utf8_upgrade{
	deep_utf8_upgrade( my $val = deep_str_clone( $_[0] ));
	return $val;
}

sub deepc_utf8_downgrade{
	deep_utf8_downgrade( my $val = deep_str_clone( $_[0] ));
	return $val;
}
sub deepc_utf8_decode{
	deep_utf8_decode( my $val = deep_str_clone( $_[0] ));
	return $val;
}

sub deepc_utf8_encode{
	deep_utf8_encode( my $val = deep_str_clone( $_[0] ));
	return $val;
}
sub deepc_decode{
	deep_decode( my $val = deep_str_clone( $_[0] ), $_[1]);
	return $val;
}
sub deepc_encode{
	deep_encode( my $val = deep_str_clone( $_[0] ), $_[1]);
	return $val;
}
sub deepc_from_to{
	deep_from_to( my $val = deep_str_clone( $_[0] ), $_[1], $_[2]);
	return $val;
}
1;
__END__

=head1 NAME

Deep::Encode - Bulk encoding and decoding strings in Perl data

=head1 SYNOPSIS

  use Deep::Encode;

  my $s = [ 1, 2, "string in cp1251 encoding" ];

  deep_from_to( $s, "cp1251", "utf8" ); # convert $s to [ [ 1, 2, "string in utf8 encoding" ]; using Encode::from_to

  deep_utf8_encode( $s ) ; # call utf8::encode on every string in $s
  deep_utf8_decode( $s ) ; # call utf8::decode on every string in $s

  deep_encode( $s, $encoding );  # call Encode::encode for every string scalar in
  deep_decode( $s, $encoding );  # call Encode::decode for every string scalar in 

  if ( deep_utf8_check( $s ) ){
      deep_utf8_decode( $s );
  }
  else {
      croak( "Data not in utf8 encoding" );
  }
    

=head1 DESCRIPTION
1;
__END__

=head1 NAME

Deep::Encode - Bulk encoding and decoding strings in Perl data

=head1 SYNOPSIS

  use Deep::Encode;

  my $s = [ 1, 2, "string in cp1251 encoding" ];

  deep_from_to( $s, "cp1251", "utf8" ); # convert $s to [ [ 1, 2, "string in utf8 encoding" ]; using Encode::from_to

  deep_utf8_encode( $s ) ; # call utf8::encode on every string in $s
  deep_utf8_decode( $s ) ; # call utf8::decode on every string in $s

  deep_encode( $s, $encoding );  # call Encode::encode for every string scalar in
  deep_decode( $s, $encoding );  # call Encode::decode for every string scalar in 

  if ( deep_utf8_check( $s ) ){
      deep_utf8_decode( $s );
  }
  else {
      croak( "Data not in utf8 encoding" );
  }
    

=head1 DESCRIPTION

	This module allow apply Encode::from_to, utf8::decode, utf8::encode and ...  on every string scalar in array or hash recursively

=head2 EXPORT

  deep_from_to( $s, $from, $to )
  deep_utf8_decode( $s )
  deep_utf8_encode( $s )

  deep_encode( $s, $encoding );  # call Encode::encode on every string scalar in
  deep_decode( $s, $encoding );  # call Encode::decode on every string scalar in 
  deep_utf8_off( $s ); # check off utf8 flag. return number applied items.
  deep_utf8_upgrade( $s );   # Make same as Encode::upgrade for all strings in $s. return number applied items.
  deep_utf8_downgrade( $s ); # Make same as Encode::downgrade for all strings in $s. return number applied items.

  deep_utf8_check( $s ); # return true if all string can be properly decode from utf8

=head1 FEATURES
  This module does not handle hash keys, but values it does.

  $encoding may be as string like "utf8", "cp1251" or object returned from &Encode::find_encoding ( It will be little faster than string )

=head1 BUGS && TODO
  For now this module can't handle self referrenced structures. 
  To Public Benchmark.

=head1 SEE ALSO

L<Encode>, L<utf8>, L<Data::Recursive::Encode> (pure perl implementation)

=head1 AUTHOR

A.G. Grishaev, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A.G. Grishaev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
