{   package Catalyst::Controller::SOAP;

    use strict;
    use base qw/Catalyst::Controller/;
    use XML::LibXML;
    use XML::Compile::WSDL11;
    use UNIVERSAL qw(isa);

    use constant NS_SOAP_ENV => "http://schemas.xmlsoap.org/soap/envelope/";

    our $VERSION = '0.5';

    __PACKAGE__->mk_accessors qw(wsdlobj decoders encoders);

    sub _parse_SOAP_attr {
        my ($self, $c, $name, $value) = @_;

        my $wsdlfile = $self->config->{wsdl};
        if ($wsdlfile) {
            if (!$self->wsdlobj) {
                my $schema;
                if (ref $wsdlfile eq 'HASH') {
                    $schema = $wsdlfile->{schema};
                    $wsdlfile = $wsdlfile->{wsdl};
                }

                if (ref $wsdlfile eq 'ARRAY') {
                    my $main = shift @{$wsdlfile};
                    $self->wsdlobj(XML::Compile::WSDL11->new($main));
                    $self->wsdlobj->addWsdl($_) for @{$wsdlfile};
                } else {
                    $self->wsdlobj(XML::Compile::WSDL11->new($wsdlfile));
                }

                if (ref $schema eq 'ARRAY') {
                    $self->wsdlobj->importDefinitions($_) for @{$schema};
                } elsif ($schema) {
                    $self->wsdlobj->importDefinitions($schema)
                }
            }

            my $operation = $self->wsdlobj->operation($name)
              or die 'Every operation should be on the WSDL when using one.';
            my $portop = $operation->portOperation();

            my $input_parts = $self->wsdlobj->find(message => $portop->{input}{message})
              ->{part};
            $_->{compiled} = $self->wsdlobj->schemas->compile(READER => $_->{element})
              for @{$input_parts};

            $self->decoders({}) unless $self->decoders();
            $self->decoders->{$name} = sub {
                my $body = shift;
                my @nodes = grep { UNIVERSAL::isa($_, 'XML::LibXML::Element') } $body->childNodes();
                return
                  {
                   map {
                       my $data = $_->{compiled}->(shift @nodes);
                       $_->{name} => $data;
                   } @{$input_parts}
                  }, @nodes;
            };

            my $output_parts = $self->wsdlobj->find(message => $portop->{output}{message})
              ->{part};
            $_->{compiled} = $self->wsdlobj->schemas->compile(WRITER => $_->{element})
              for @{$output_parts};

            $self->encoders({}) unless $self->encoders();
            $self->encoders->{$name} = sub {
                my ($doc, $data) = @_;
                return
                  [
                   map {
                       $_->{compiled}->($doc, $data->{$_->{name}})
                   } @{$output_parts}
                  ];
            };
        }

        my $actionclass = ($value =~ /^\+/ ? $value :
          'Catalyst::Action::SOAP::'.$value);
        (
         ActionClass => $actionclass,
        )
    }

    # this is implemented as to respond a SOAP message according to
    # what has been sent to $c->stash->{soap}
    sub end : Private {
        my ($self, $c) = (shift, shift);
        my $soap = $c->stash->{soap};

        return $self->NEXT::end($c, @_) unless $soap;

        if (scalar @{$c->error}) {
            $c->stash->{soap}->fault
              ({ code => [ 'env:Sender' ],
                 reason => 'Unexpected Error', detail =>
                 'Unexpected error in the application: '.(join "\n", @{$c->error} ).'!'});
            $c->error(0);
        }

        my $namespace = $soap->namespace || NS_SOAP_ENV;
        my $response = XML::LibXML->createDocument();

        my $envelope = $response->createElementNS
          ($namespace,"Envelope");

        $response->setDocumentElement($envelope);

        # TODO: we don't support header generation in response yet.

        my $body = $response->createElementNS
          ($namespace,"Body");

        $envelope->appendChild($body);

        if ($soap->fault) {
            my $fault = $response->createElementNS
              ($namespace, "Fault");
            $body->appendChild($fault);

            my $code = $response->createElementNS
              ($namespace, "Code");
            $fault->appendChild($code);

            $self->_generate_Fault_Code($response,$code,$soap->fault->{code}, $namespace);

            if ($soap->fault->{reason}) {
                my $reason = $response->createElementNS
                  ($namespace, "Reason");
                $fault->appendChild($reason);
                # TODO: we don't support the xml:lang attribute yet.
                my $text = $response->createElementNS
                  ($namespace, "Text");
                $reason->appendChild($text);
                $text->appendText($soap->fault->{reason});
            }
            if ($soap->fault->{detail}) {
                my $detail = $response->createElementNS
                  ($namespace, "Detail");
                $fault->appendChild($detail);
                # TODO: we don't support the xml:lang attribute yet.
                my $text = $response->createElementNS
                  ($namespace, "Text");
                $detail->appendChild($text);
                $text->appendText($soap->fault->{detail});
            }
        } else {
            # TODO: Generate the body.
            # At this moment, for the sake of getting something ready,
            # let's implement the string return.
            if ($soap->string_return) {
                $body->appendText($soap->string_return);
            } elsif (my $lit = $soap->literal_return) {
                if (ref $lit eq 'XML::LibXML::NodeList') {
                    for ($lit->get_nodelist) {
                        $body->appendChild($_);
                    }
                } else {
                    $body->appendChild($lit);
                }
            } elsif (my $cmp = $soap->compile_return) {
                die 'Tried to use compile_return without WSDL'
                  unless $self->wsdlobj;

                my $arr = $self->encoders->{$soap->operation_name}->($response, $cmp);
                $body->appendChild($_) for @{$arr};
            }
        }

        $c->res->content_type('text/xml');
        $c->res->body($envelope->toString());
    }

    sub _generate_Fault_Code {
        my ($self, $document, $codenode, $codeValue, $namespace) = @_;

        my $value = $document->createElementNS
          ($namespace, "Value");
        if (ref $codeValue eq 'ARRAY') {
            $value->appendText($codeValue->[0]);
            my $subcode = $document->createElementNS
              ($namespace, 'SubCode');
            $codenode->appendChild($value);
            $codenode->appendChild($subcode);
            $self->_generate_Fault_Code($document, $subcode, $codeValue->[1], $namespace);
        } else {
            $value->appendText($codeValue) if $codeValue;
            $codenode->appendChild($value);
        }
    }


};

{   package Catalyst::Controller::SOAP::Helper;

    use base qw(Class::Accessor::Fast);

    __PACKAGE__->mk_accessors(qw{envelope parsed_envelope arguments fault namespace
                                 encoded_return literal_return string_return
                                 compile_return operation_name});


};

1;

__END__

=head1 NAME

Catalyst::Controller::SOAP - Catalyst SOAP Controller

=head1 SYNOPSIS

    package MyApp::Controller::Example;
    use base 'Catalyst::Controller::SOAP';

    # available in "/example" as operation "ping". The arguments are
    # treated as a literal document and passed to the method as a
    # XML::LibXML object
    # Using XML::Compile here will help you reading the message.
    sub ping : SOAP('RPCLiteral') {
        my ( $self, $c, $xml) = @_;
        my $name = $xml->findValue('some xpath expression');
    }

    # avaiable as "/example/world" in document context. The entire body
    # is delivered to the method as a XML::LibXML object.
    # Using XML::Compile here will help you reading the message.
    sub world :Local SOAP('DocumentLiteral')  {
        my ($self, $c, $xml) = @_;
    }

    # avaiable as "/example/get" in HTTP get context.
    # the get attributes will be available as any other
    # get operation in Catalyst.
    sub get :Local SOAP('HTTPGet')  {
        my ($self, $c) = @_;
    }

    # this is the endpoint from where the RPC operations will be
    # dispatched. This code won't be executed at all.
    # See Catalyst::Controller::SOAP::RPC.
    sub index :Local SOAP('RPCEndpoint') {}

=head1 ABSTACT

Implements SOAP serving support in Catalyst.

=head1 DESCRIPTION

SOAP Controller for Catalyst which we tried to make compatible with
the way Catalyst works with URLS.It is important to notice that this
controller declares by default an index operation which will dispatch
the RPC operations under this class.

=head1 ATTRIBUTES

This class implements the SOAP attribute wich is used to do the
mapping of that operation to the apropriate action class. The name of
the class used is formed as Catalyst::Action::SOAP::$value, unless the
parameter of the attribute starts with a '+', which implies complete
namespace.

The implementation of SOAP Action classes helps delivering specific
SOAP scenarios, like HTTP GET, RPC Encoded, RPC Literal or Document
Literal, or even Document RDF or just about any required combination.

See L<Catalyst::Action::SOAP::DocumentLiteral> for an example.

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

=item $c->stash->{soap}->fault({code => $code,reason => $reason, detail => $detail])

Allows you to set fault code and message. Optionally, you may define
the code itself as an arrayref where the first item will be this code
and the second will be the subcode, which recursively may be another
arrayref.

=item $c->stash->{soap}->encoded_return(\@data)

This method will prepare the return value to be a soap encoded data.

  # TODO: At this moment, only Literals are working...

=item $c->stash->{soap}->literal_return($xml_node)

This method will prepare the return value to be a literal XML
document, in this case, you can pass just the node that will be the
root in the return message or a nodelist.

Using XML::Compile will help to elaborate schema based returns.

=item $c->stash->{soap}->string_return($non_xml_text)

In this case, the given text is encoded as CDATA inside the SOAP
message.

=back

=head1 USING WSDL

If you define "wsdl" as a configuration key,
Catalyst::Controller::SOAP will automatically map your operations into
the WSDL operations, in which case you will receive the parsed Perl
structure as returned by XML::Compile according to the type defined in
the WSDL message.

You can define additional wsdl files or even additional schema
files. If $wsdl is an arrayref, the first element is the one passed to
new, and the others will be the argument to subsequent addWsdl calls.
If $wsdl is a hashref, the "wsdl" key will be handled like above and
the "schema" key will be used to importDefinitions. If the content of
the schema key is an arrayref, it will result in several calls to
importDefinition.

Also, when using wsdl, you can also define the response using

=over

=item $c->stash->{soap}->compile_return($perl_structure)

In this case, the given structure will be transformed by XML::Compile,
according to what's described in the WSDL file.

=back

=head1 TODO

No header features are implemented yet.

The SOAP Encoding support is also missing, when that is ready you'll
be able to do something like the code below:

    # available in "/example" as operation "echo"
    # parsing the arguments as soap-encoded.
    sub echo : SOAP('RPCEncoded') {
        my ( $self, $c, @args ) = @_;
    }

=head1 SEE ALSO

L<Catalyst::Action::SOAP>, L<XML::LibXML>, L<XML::Compile>
L<Catalyst::Action::SOAP::DocumentLiteral>,
L<Catalyst::Action::SOAP::RPCLiteral>,
L<Catalyst::Action::SOAP::HTTPGet>, L<XML::Compile::WSDL11>,
L<XML::Compile::Schema>

=head1 AUTHORS

Daniel Ruoso C<daniel.ruoso@verticalone.pt>

=head1 BUG REPORTS

Please submit all bugs regarding C<Catalyst::Controller::SOAP> to
C<bug-catalyst-controller-soap@rt.cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
