package WebService::ReviewBoard;

use strict;
use warnings;

use JSON::Syck;
use Data::Dumper;
use Log::Log4perl qw(:easy);
use HTTP::Request::Common;
use HTTP::Request::Common 'DELETE';
use LWP::UserAgent;
use version; our $VERSION = qv('0.1.1');

sub new {
	my $proto = shift;
	my $url   = shift || LOGDIE "usage: " . __PACKAGE__ . "->new( 'http://demo.review-board.org' );";

	if ( $url !~ m#^https?://# ) {
		WARN "url you specified ($url) looks invalid.  Must start with http://";
        WARN "prefixing with http:// for you";
        $url = "http://$url";
	}

	my $class = ref $proto || $proto;
	my $self = { review_board_url => $url, };

	return bless $self, $class;
}

sub get_review_board_url { return shift->{review_board_url}; }

sub api_post {
	my $self = shift;
	$self->api_call( shift, 'POST', @_ );
}

sub api_get {
	my $self = shift;
	$self->api_call( shift, 'GET', @_ );
}

sub api_put {
	my $self = shift;
	$self->api_call( shift, 'PUT', @_ );
}

sub api_delete {
	my $self = shift;
	$self->api_call( shift, 'DELETE', @_ );
}

sub api_call {
	my $self    = shift;
	my $path    = shift or LOGDIE "No url path to api_post";
	my $method  = shift or LOGDIE "no method (POST or GET)";
	my @options = @_;

	my $ua = $self->get_ua();

	my $url = $self->get_review_board_url() . $path;
	my $request;
	if ( $method eq "POST" ) {
		$request = POST( $url, @options );
	}
	elsif ( $method eq "GET" ) {
		$request = GET( $url, @options );
	}
	elsif ( $method eq "PUT" ) {
		$request = PUT( $url, @options );
	}
	elsif ($method eq "DELETE" ) {
		$request = DELETE( $url, @options);
	}
	else {
		LOGDIE "Unknown method $method.  Valid methods are GET, POST, PUT, or DELETE";
	}

	DEBUG "Doing request:\n" . $request->as_string();
	my $response = $ua->request($request);
	DEBUG "Got response:\n" . $response->as_string();

	my $json;
	if ( $response->is_success ) {
		$json = JSON::Syck::Load( $response->decoded_content() );
	}
	else {
		LOGDIE "Error fetching $path: " . $response->status_line . "\n";
	}

	# check if there was an error
	if ( $json->{err} && $json->{err}->{msg} ) {
		LOGDIE "Error from $url: " . $json->{err}->{msg};
	}

	return $json;
}

# you can overload this method if you want to use a different useragent
sub get_ua {
	my $self = shift or LOGCROAK "you must call get_ua as a method";

	if ( !$self->{ua} ) {
		$self->{ua} = LWP::UserAgent->new( cookie_jar => {}, );
	}

	return $self->{ua};

}

1;

__END__

=head1 NAME

WebService::ReviewBoard - Perl library to talk to a review board installation thru web services.

=head1 SYNOPSIS

    use WebService::ReviewBoard;

    # pass in the name of the reviewboard url to the constructor
    my $rb = WebService::ReviewBoard->new( 'http://demo.review-board.org/' );
    $rb->login( 'username', 'password' );

=head1 DESCRIPTION

This is an alpha release of C<< WebService::ReviewBoard >>.  The interface may change at any time and there
are many parts of the API that are not implemented.  You've been warned!

Patches welcome!

=head1 INTERFACE 

=over 

=item C<< get_review_board_url >>

=item C<< login >>

=item C<< get_ua >>

Returns an LWP::UserAgent object.  You can override this method in a subclass if
you need to use a different LWP::UserAgent.

=item C<< api_post >>

Do the HTTP POST to the reviewboard API.

=item C<< api_get >>

Same as api_post, but do it with an HTTP GET

=item C<< my $json = $rb->api_call( $path, $method, @options ) >>

api_post and api_get use this internally

=back

=head1 DIAGNOSTICS

=over

=item C<< "Unknown method %s.  Valid methods are GET or POST" >>

=item C<< "you must pass WebService::ReviewBoard->new a username" >>

=item C<< "you must pass WebService::ReviewBoard->new a password" >>

=item C<< "No url path to api_post" >>

=item C<< "Error fetching %s: %s" >>

=item C<< "you must call %s as a method" >>

=item C<< "get_review_board_url(): url you passed to new() ($url) looks invalid" >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

    version
    YAML::Syck
    Data::Dumper
    Bundle::LWP
    Log::Log4Perl

There are also a bunch of Test::* modules that you need if you want all the tests to pass:

    Test::More
    Test::Pod
    Test::Exception
    Test::Pod::Coverage
    Test::Perl::Critic

=head1 INCOMPATIBILITIES

None reported.

=head1 SOURCE CODE REPOSITORY 

This source lives at http://github.com/jaybuff/perl_WebService_ReviewBoard/ 

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-reviewboard@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Jay Buffington  C<< <jaybuffington@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Jay Buffington C<< <jaybuffington@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
