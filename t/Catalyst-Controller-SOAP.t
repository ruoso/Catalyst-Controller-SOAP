use Test::More tests => 3;
BEGIN { use_ok('Catalyst::Controller::SOAP') };
use Catalyst::Action::SOAP::DocumentLiteral;
use lib qw(lib t/lib);
use IO::Scalar;
use File::Temp;
use Catalyst::Test 'TestApp';
use Encode;

my $message = <<SOAP;
<Envelope xmlns="http://www.w3.org/2003/05/soap-envelope">
    <Body>World</Body>
</Envelope>
SOAP
my $fh = tmpfile();
print {$fh} $message;
seek $fh, 0, 'SEEK_SET';
my $response = post_soap('/ws/hello',$message);
my $response_content = $response->content;
ok($response_content =~ /Hello World/, 'Document Literal POST!');

$response_content = get('/ws/foo?who=World');
ok($response_content =~ /Hello World/, 'HTTP Get!');

sub post_soap {
    my $uri = shift;
    my $xml_content = shift;
    require HTTP::Request::AsCGI;
    my $request = Catalyst::Utils::request( $uri );
    $request->method('POST');
    $request->content_type('application/soap+xml');
    $request->content_encoding('utf8');
    $request->content(encode_utf8($xml_content));
    my $cgi = HTTP::Request::AsCGI->new( $request, %ENV )->setup;
    $cgi->stdin($fh);
    TestApp->handle_request;
    return $cgi->restore->response;
}
