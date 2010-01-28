#!perl -T

use lib 't/lib';

use Test::More tests => 4;
use Test::Exception 0.03;

use LWP::UserAgent;

BEGIN {
	use_ok('MyUAConfig'); # Our configuration
}

# Is the configuration us?
isa_ok(MyUAConfig->configuration, 'Test::Override::UserAgent', '__PACKAGE__->configure->isa');

# Create a new user agent
my $ua = LWP::UserAgent->new;

# Install the overrides
lives_ok {
	MyUAConfig->configuration->install_in_user_agent($ua);
} 'Install overrides into UA';

# Get the echo URI page
my $response = $ua->get('http://localhost/echo_uri');

# See if the response body is right
is $response->content, 'http://localhost/echo_uri', 'Echo page intercepted';
