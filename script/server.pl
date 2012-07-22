#!/usr/bin/perl -w
    
use strict;
use warnings;

use Asyncore;
use TimeServer;
use TimeChannel;

my $server = TimeServer->new(35000);

Asyncore::loop();

1;
