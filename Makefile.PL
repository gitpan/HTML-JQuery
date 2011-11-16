use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'HTML-JQuery';
all_from 'lib/HTML/JQuery.pm';

build_requires 'Test::More' => '0.88';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/HTML/JQuery.pm > README")
        and die $!;
}

WriteAll();
