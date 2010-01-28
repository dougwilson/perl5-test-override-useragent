package MyUAConfig;

use IO::String;
use Test::Override::UserAgent for => 'configuration';

# Simple URI echo
override_request
	host => 'localhost',
	path => '/echo_uri',
	sub { return [200, [], [shift->uri]]; };

# PSGI filehandle
override_request
	host => 'localhost',
	path => 'fh.psgi',
	sub {
		return [200, [], IO::String->new("some\nwords\n")];
	};

1;
