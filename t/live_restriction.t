#!perl -T

use Test::More tests => 4;
use Test::Exception 0.03;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

my $live_url = 'http://www.google.com/';

# Create a configuration
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/here',
	sub { return [200, ['Content-Type' => 'text/plain'], ['i am here']]; },
);

# Create the UA
my $ua = $conf->install_in_user_agent(LWP::UserAgent->new);

ok !$conf->allow_live_requests,
	'Default allow live requests is false';

is $ua->get($live_url)->status_line,
	'404 Not Found (No Live Requests)',
	'Unable to make live request';

# Turn on live requests
$conf->allow_live_requests(1);

ok $conf->allow_live_requests,
	'Allow live requests is on';

SKIP: {
	# Test for seeing if we can do live
	my $live = LWP::UserAgent->new->get($live_url);

	if ($live->code != 200) {
		skip "Unable to fetch $live_url", 1;
	}

	is $ua->get($live_url)->status_line, $live->status_line,
		'Live request with through';
}
