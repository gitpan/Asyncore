#!/usr/bin/perl -w
    
use strict;
use warnings;

use Asyncore;
use TimeServer;
use TimeChannel;

use Socket (qw(AF_INET AF_INET6 SOCK_STREAM SOCK_RAW SOCK_STREAM));

# TimeServer->create_socket(port, family, type)
my $server = TimeServer->new(35000, AF_INET);

Asyncore::loop();

1;
