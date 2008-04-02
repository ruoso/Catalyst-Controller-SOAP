package PostApp::Controller::WithWSDL;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} = 't/hello.wsdl';
__PACKAGE__->config->{soap_action_prefix} = 'http://example.com/actions/';

sub Greet : Local SOAP('DocumentLiteral') {
    my ( $self, $c, $args ) = @_;
    my $who = $args->{parameters}{who};
    my $grt = $args->{parameters}{greeting};
    $c->stash->{soap}->compile_return({ details => { greeting => $grt.' '.$who.'!' }});
}

sub doclw : Local ActionClass('SOAP::DocumentLiteralWrapped') { }

1;
