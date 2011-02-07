#!perl -T

use Test::More tests => 3;
use Test::Fatal;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

# Make a new override
my $conf = Test::Override::UserAgent->new;

# Set a simple request to be handled
$conf->override_request(
	url => 'http://localhost/echo_uri',
	sub { return [200, ['Content-Type' => 'text/plain'], [shift->uri]]; },
);
$conf->override_request(
	url => 'http://localhost/jazz_hands',
	sub { return [200, ['Content-Type' => 'text/plain'], ['spladow!']]; },
);
$conf->override_request(
	uri => 'https://localhost/jazz_hands',
	sub { return [200, ['Content-Type' => 'text/plain'], ['SECURE spladow!']]; },
);

# Create a new user agent
my $ua = LWP::UserAgent->new(timeout => 2);

# Install the overrides
$conf->install_in_user_agent($ua);

{
	# Get the echo URI page
	my $response = $ua->get('http://localhost/echo_uri');

	# See if the response body is right
	is($response->content, 'http://localhost/echo_uri', 'Echo page intercepted');
}

{
	# Get the other page
	my $response = $ua->get('http://localhost/jazz_hands');

	# See if the response body is right
	is($response->content, 'spladow!', 'Jazz hands are OK');
}

{
	# Get the other page
	my $response = $ua->get('https://localhost/jazz_hands');

	# See if the response body is right
	is($response->content, 'SECURE spladow!', 'Jazz hands are secured');
}

exit 0;
