#!perl -T

use Test::More tests => 9;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';

my $live_url = 'http://www.cpan.org/authors/02STAMP';

# Create a configuration
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/here',
	sub { return [200, ['Content-Type' => 'text/plain'], ['i am here']]; },
);

# Create the UA
my $ua = LWP::UserAgent->new(timeout => 2);

# Install the override
$ua = $conf->install_in_user_agent($ua);

ok !$conf->allow_live_requests,
	'Default allow live requests is false';

{
	my $response = $ua->get($live_url);

	is $response->status_line,
		'404 Not Found (No Live Requests)',
		'Unable to make live request; status line correct';
	is(scalar $response->header('Client-Warning'),
		'Internal response',
		'Unable to make live request; internal response indicated');
	is(scalar $response->header('Client-Response-Source'),
		'Test::Override::UserAgent',
		'Unable to make live request; response source indicated');
}

# Turn on live requests
$conf->allow_live_requests(1);

ok $conf->allow_live_requests,
	'Allow live requests is on';

SKIP: {
	# Test for seeing if we can do live
	my $live = LWP::UserAgent->new(timeout => 2)->get($live_url);

	if ($live->code != 200) {
		skip "Unable to fetch $live_url", 4;
	}

	is $ua->get($live_url)->status_line, $live->status_line,
		'Live request went through';

	# Remove hooks from the UA
	$conf->uninstall_from_user_agent($ua);

	# Make sure uninstall succeeded
	isnt $ua->get('http://localhost/here')->content, 'i am here',
		'Hooks uninstall from user agent';

	{
		# Install in the scope
		my $scope = $conf->install_in_scope;

		is $ua->get($live_url)->status_line, $live->status_line,
			'Live request went through in scope install';

		# Turn off live requests
		$conf->allow_live_requests(0);

		isnt $ua->get($live_url)->status_line, $live->status_line,
			'Live request allow changed without removing scope install';
	}
}
