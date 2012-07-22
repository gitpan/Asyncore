package Asyncore;
{
  $Asyncore::VERSION = '0.01';
}

#==============================================================================
#
#         FILE:  Asyncore.pm
#
#  DESCRIPTION:  porting in Perl of asyncore.py (python 2.7) 
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  0.01
#      CREATED:  26/06/12 20:27:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use IO::Select;

our $socket_map;

if (not $socket_map) {
    $socket_map = {}
}

sub _read {
    my $obj = shift;
    
    eval {
        $obj->handle_read_event();
    };
    if ($@) {
        $obj->handle_error($@);      
    }
}

sub _write {
    my $obj = shift;
    
    eval {
        $obj->handle_write_event();
    };
    if ($@) {
        $obj->handle_error($@);      
    }
}

sub _exception {
    my $obj = shift;
    
    eval {
        $obj->handle_expt_event();
    };
    if ($@) {
        $obj->handle_error($@);
    }
}

sub poll {
    my($timeout, $map) = @_;
    
    if (not $map) {
        $map = $socket_map;
    }
    
    if ($map) {
        my $r = new IO::Select;
        my $w = new IO::Select;
        my $e = new IO::Select;
        foreach my $fd (keys %{ $map }) {
            my $obj = $map->{$fd};
            my $is_r = $obj->readable();
            my $is_w = $obj->writable();
            
            if ($is_r) {
                $r->add($obj->{_socket});
            }
            if ($is_w and not $obj->{_accepting}) {
                $w->add($obj->{_socket});

            }
            if ($is_r or $is_w) {
                $e->add($obj->{_socket});
            }
        }
        if (not @$r and not @$w and not @$e) {
            sleep($timeout);
            return
        }
        
        #printf "polling ...\n";
        
        my($rr, $rw, $he);
        eval {
            # rr, wr: ready for reading/writing. he: has exception
            ($rr, $rw, $he) = IO::Select->select($r, $w, $e, $timeout);
        };
        if ($@) {
            die "error in select(r, w, e): " . $@;
        }
        
        foreach my $fd (@$rr) {
            my $obj = $map->{$fd->fileno()};
            if (not $obj) {
                next;
            }
            _read($obj);
        }
        
        foreach my $fd (@$rw) {
            my $obj = $map->{$fd->fileno()};
            if (not $obj) {
                next;
            }
            _write($obj);
        }
        
        foreach my $fd (@$he) {
            my $obj = $map->{$fd->fileno()};
            if (not $obj) {
                next;
            }
            _exception($obj);
        }
    }
}

sub loop {
    my($timeout, $use_poll, $map, $count) = @_;
    
    if (not $timeout) {
        $timeout = 30;
    }

    if (not $map) {
        $map = $socket_map;
    }

    #if ($use_poll and hasattr(select, 'poll') {
        #$poll_fun = $poll2
    #}
    #else {
        #$poll_fun = $poll
    #}

    if (not $count) {
        while ($map) {
            #$poll_fun($timeout, $map)
            poll($timeout, $map)
        }
    }
    else {
        while (($map) and ($count > 0)) {
            #$poll_fun($timeout, $map);
            $count--;
        }
    }
}



package Asyncore::Dispatcher;

#==============================================================================
#
#         FILE:  Asyncore.pm
#      PACKAGE:  Asyncore::Dispatcher
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Sebastiano Piccoli), <sebastiano.piccoli@gmail.com>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  26/06/12 20:27:28 CEST
#     REVISION:  ---
#==============================================================================

use strict;
use warnings;

use IO::Socket::INET;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self->init(@_);
}

sub init {
    my($self, $sock, $map) = @_;

    if (not $map) {
        $self->{_map} = $socket_map;
    }
    else {
        $self->{_map} = $map; 
    }

    $self->{_fileno} = 0;

    if ($sock) {
        # Set to nonblocking just to make sure for cases where we 
        # get a socket from a blocking source (how?)
        #$sock->setblocking(0)
        $self->set_socket($sock, $map);
        $self->{_connected} = 1;
        
        eval {
            $self->{_addr} = $sock->peername(); 
        };
        if ($@) {    
            # Handle the case where we got an unconnected socket
            $self->{_connected} = 0;
            # Handle the case where the socket is broken in some unknown way,
            # alert the user and remove it from the map (to prevent polling
            # of broken sockets)
            #$self->del_channel($map);
        }
    }
    else {
        $self->{_socket} = 0;
    }
}

sub create_socket {
    my($self, $port, $family, $type) = @_;

    # family, type 
    # AF_INET, SOCK_STREAM
    my $sock = IO::Socket::INET->new(LocalAddr => '',
                                     LocalPort => $port,
                                     Blocking => 0);
    $self->set_socket($sock);

}

sub set_socket {
    my($self, $sock, $map) = @_;

    $self->{_socket} = $sock;
    $self->{_fileno} = $sock->fileno();
    $self->add_channel($map);
}

sub readable {
    my $self = shift;
    
    return 1;
}

sub writable {
    my $self = shift;
    
    return 1;
}

sub add_channel {
    my($self, $map) = @_;

    if (not $map) {
        $map = $self->{_map}
    }

    $map->{$self->{_fileno}} = $self;
}

sub remove_channel {
    my($self, $map) = @_;

    if (not $map) {
        $map = $self->{_map}
    }
    
    my $fd = $self->{_fileno};
    foreach my $mfd (keys %{ $map }) {
        if ($mfd == $fd) {
            delete $map->{$mfd};
        }
    }
    
    $self->{_fileno} = undef;
}

sub bind {
    my($self, $port) = @_;

    return $self->{_socket}->bind($port);
}

sub listen {
    my($self, $num) = @_;

    $self->{_accepting} = 1;
    # if os == nt then n max = 5
    return $self->{_socket}->listen($num); 
}

sub accept {
    my $self = shift;
     
    eval {
        $self->{_socket}->accept();
    };
    if ($@) {
        warn "Error in sub accept";
    }
    
    # ...
    return 1; # $channel??
}

sub send {
    my($self, $data) = @_;
    
    my $result;
    eval {
        $result = $self->{_socket}->send($data);
    };
    #if ($@) {
    #    
    #}

    return $result;
}

sub close {
    my $self = shift;
    
    $self->{_connected} = 0;
    $self->{_accepting} = 0;
    $self->{_connecting} = 0;
    $self->{_socket}->close();
}

sub handle_close {
    my $self = shift;
    
    $self->close();
}

sub handle_read_event {
    my $self = shift;
    
    if ($self->{_accepting}) {
        $self->handle_accept();
    }
    elsif (not $self->{_connected}) {
        if ($self->{_connecting}) {
            $self->handle_connect_event();
        }
        $self->handle_read();
    }
    else {
        $self->handle_read();
    }
}

sub handle_connect_event {
    my $self = shift;
    
    #todo
}

sub handle_write_event {
    my $self = shift;
    
    if ($self->{_accepting}) {
        return
    }
    
    if (not $self->{_connected}) {
        if ($self->{_connecting}) {
            $self->handle_connect_event();
        }
    }
    $self->handle_write();
}

sub handle_expt_event {
    my $self = shift;
    
    my $err = $self->{_socket}->getsockopt();
    if ($err != 0) {
        $self->handle_close();
    }
    else {
        $self->handle_expt();
    }
}

sub handle_error {
    my($self, $error) = @_;
    
    warn $error;
    
    $self->handle_close();
}

sub handle_expt {
    # overrided
}

sub handle_read {
    # overrided
}

sub handle_write {
    # overrided
}

sub handle_connect {
    # overrided
}

sub handle_accept {
    # overrided
}


1;

__END__