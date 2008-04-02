package PostApp::Controller::WithWSDL2;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP::RPC';

__PACKAGE__->config->{wsdl} = 't/hello2.wsdl';

sub Greet : SOAP('RPCLiteral') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{who};
    my $grt = $args->{greeting};
    $c->stash->{soap}->compile_return({ greeting => $grt.' '.$who.'!' });
}

1;
