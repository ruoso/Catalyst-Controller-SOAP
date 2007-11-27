use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'PostApp' }
BEGIN { use_ok 'PostApp::Controller::WS' }

ok( request('/ws')->is_success, 'Request should succeed' );


