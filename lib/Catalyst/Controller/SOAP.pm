{ package Catalyst::Controller::SOAP;

    use strict;
    use base qw/Catalyst::Controller/;

    our $VERSION = '0.0.1';

    sub _parse_SOAP_Attr {
        my ($self, $c, $name, $value) = @_;
        my $actionclass = $value =~ /^+/ ? $value :
          'SOAP::'.$value;
        (
         ActionClass => $actionclass,
        )
    }

    # this is implemented as to respond a SOAP message according to
    # what has been sent to $c->stash->{soap}
    sub End : Private {
        my ($self, $c) = (shift, shift);
        return $self->NEXT::End($c, @_) unless $c->stash->{soap};
        
    }

};

{ package Catalyst::Controller::SOAP::Helper;

  use base qw(Class::Accessor::Fast);

  __PACKAGE__->mk_accessors(qw{envelope parsed_envelope arguments error
                               encoded_return literal_return
                               literal_string_return string_return});

};

1;

__END__

=head1 NAME

Catalyst::Controller::SOAP -- Catalyst SOAP Controller

=head1 SYNOPSIS

    package MyApp::Controller::Example;
    use base 'Catalyst::Controller::SOAP';

    # available in "/example" as operation "echo"
    # parsing the arguments as soap-encoded.
    sub echo : SOAP('RPCEncoded') {
        my ( $self, $c, @args ) = @_;
    }

    # available in "/example" as operation "ping". The arguments are
    # treated as a literal document and passed to the method as a
    # XML::LibXML object
    sub ping : SOAP('RPCLiteral') {
        my ( $self, $c, $xml) = @_;
        my $name = $xml->findValue('some xpath expression');
    }

    # avaiable as "/example/world" in document context. The entire body
    # is delivered to the method as a XML::LibXML object.
    sub world : SOAP('DocLiteral') {
        my ($self, $c, $doc) = @_;
    }

    # this is the endpoint from where the RPC operations will be
    # dispatched. This code won't be executed at all.
    sub index : SOAP('RPCEndpoint') {}

=head1 DESCRIPTION

SOAP Controller for Catalyst which we tried to make compatible with
the way Catalyst works with URLS.

It is important to notice that this controller declares by default an
index operation which will dispatch the RPC operations under this
class.

=back

=head1 ATTRIBUTES

This class implements the SOAP attribute wich is used to do the
mapping of that operation to the apropriate action class. The name of
the class used is formed as Catalyst::Action::SOAP::$value, unless the
parameter of the attribute starts with a '+', which implies complete
namespace.

The implementation of SOAP Action classes helps delivering specific
SOAP scenarios, like HTTP GET, RPC Encoded, RPC Literal or Document
Literal, or even Document RDF or just about any required combination.

See L<Catalyst::Action::SOAP::DocLiteral> for an example.

=head1 ACCESSORS

Once you tagged one of the methods, you'll have an $c->stash->{soap}
accessor which will return an C<Catalyst::Controller::SOAP::Helper>
object. It's important to notice that this is achieved by the fact
that all the SOAP Action classes are subclasses of
Catalyst::Action::SOAP, which implements most of that.

You can query this object as follows:

=over 4

=item $c->stash->{soap}->envelope()

The original SOAP envelope as string.

=item $c->stash->{soap}->parsed_envelope()

The parsed envelope as an XML::LibXML object.

=item $c->stash->{soap}->arguments()

The arguments of a RPC call.

=item $c->stash->{soap}->error($c,[$code,$message])

Allows you to set fault code and message

=item $c->stash->{soap}->encoded_return(\@data)

This method will prepare the return value to be a soap encoded data.

=item $c->stash->{soap}->literal_return($xml_node)

This method will prepare the return value to be a literal XML
document, in this case, you can pass just the node that will be the
root in the return message.

=item $c->stash->{soap}->literal_string_return($xml_text)

In this case, the argument is used literally inside the message. It is
supposed to already contain all namespace definitions in it.

=item $c->stash->{soap}->string_return($non_xml_text)

In this case, the given text is encoded as CDATA inside the SOAP
message.

=back

=head1 TODO

At this moment, this is a very early release. So almost everything is
still to be done. The only thing done right now is getting the body
from the message and dispatching the correct method.

=head1 SEE ALSO

L<Catalyst::Action::SOAP>, L<XML::LibXML>,
L<Catalyst::Action::SOAP::DocLiteral>,
L<Catalyst::Action::SOAP::RPCEncoded>,
L<Catalyst::Action::SOAP::HTTPGet>

=head1 AUTHORS

Daniel Ruoso C<daniel.ruoso@verticalone.pt>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
