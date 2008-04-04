package PostApp::Controller::WithWSDL4;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP::RPC';

__PACKAGE__->config->{wsdl} = 't/hello4.wsdl';

sub Greet : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ $grt.' '.$who.'!' });
}

sub Shout : WSDLPort('Greet') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ uc($grt).' '.uc($who).'!' });
}

1;
