package PostApp::Controller::WS;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

sub hello : Local SOAP('DocumentLiteral') {
    my ( $self, $c, $body ) = @_;
    my $who = $body->textContent();
    $c->stash->{soap}->string_return('Hello '.$who.'!');
}

1;
