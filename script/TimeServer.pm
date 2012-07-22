package TimeServer;

#==============================================================================
#
#         FILE:  TimeServer.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  28/06/12 00:53:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use Asyncore;
use TimeChannel;
use base qw( Asyncore::Dispatcher );

use Data::Dumper;

sub init {
    my($self, $port) = @_;

    $self->SUPER::init();

    if (not $port) {
        $port = 37;
    }

    $self->{_port} = $port;
    #self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
    $self->create_socket($port); # pass also family and type?
    $self->listen(5);
}

sub handle_accept {
    my $self = shift;
    
    my $channel = $self->{_socket}->accept();
    my $timechannel = TimeChannel->new($channel);
}

1;

__END__
