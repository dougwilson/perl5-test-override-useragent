#!perl -T

use Test::More tests => 4;
use Test::Exception 0.03;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Make a new override
my $conf = new_ok 'Test::Override::UserAgent';

# Set a simple request to be handled
lives_ok {
	$conf->override_request(
		host => 'localhost',
		path => '/echo_uri',
		sub { return [200, ['Content-Type' => 'text/plain'], [shift->uri]]; },
	);
} 'Create an override for http://localhost/echo_uri';

# Create a new user agent
my $ua = LWP::UserAgent->new;

# Install the overrides
lives_ok {
	$conf->install_in_user_agent($ua);
} 'Install overrides into UA';

# Get the echo URI page
my $response = $ua->get('http://localhost/echo_uri');

# See if the response body is right
is $response->content, 'http://localhost/echo_uri', 'Echo page intercepted';
