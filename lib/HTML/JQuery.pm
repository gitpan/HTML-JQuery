package HTML::JQuery;

our $VERSION = '0.18';

=head1 NAME

HTML::JQuery - JQuery for Perl programmers

=head1 DESCRIPTION

HTML::JQuery acts as a bridge between Perl and JQuery/Javascript. It enables 
Perl programmers to do as much Javascript as they can using Perl.
You can create modals, key sequences and even build javascript functions using 
Perl subroutines. The aim is simple: More Perl, less Javascript.

=head1 SYNOPSIS

Inject Javascript/JQuery into your web apps using Perl.

    my $j = HTML::JQuery->new;
    
    # build a javascript function that injects pure javascript,
    # HTML::JQuery generated javascript, or both.
    $j->function(init => sub {
        $j->alert('Your document has loaded!');
    });

In the above example, when myFuncName() is called an alert box will open, then the modal
We can call it using an event handler.. yeah, we can do this with Perl, too.

    $j->onClick({ class => 'button', event => $j->callFunc('myFuncName') });

So if we add a link, like
    <a class="button" href="#">Click Me to activate myFuncName</a>
It will run our newly created function.
=cut

sub new {
    return bless $self = {
        jQuery => [],
        ks     => 0,
    }, __PACKAGE__;
}

sub import {
    my ($class, @args) = @_;
    
    for (@args) {
        __PACKAGE__->load_tooltip_css if $_ eq ':tooltip';
    }
}

sub load_tooltip_css {
    my $self = shift;

    my $tt = q{
        \$('<div id="tooltip" style="display: none"></div>')
        .appendTo('body').css('text-decoration', 'italic');
        \$('#tooltip').css('background-color', '#CFECEC');
        \$('#tooltip').css('opacity', '0.6');
        \$('#tooltip').css('filter', 'alpha(opacity=60)');
        \$('#tooltip').css('border', '1px solid black');
    };    
 
    push @{$self->{jQuery}}, $tt;
}

=head1 METHODS

=head2 html

Returns the complete JQuery/Javascript code that the module generates for you.
It also includes the .ready() feature so you don't need to worry about that either.
It checks to see if init() is a function, and if so, runs it.
=cut

sub html {
    my $self = shift;

    my $html = "";
    for(@{$self->{html}}) {
        $html .= $_ . "\n";
    }

    my $str = q{
        <script type="text/javascript">
        // start jQuery block
        $(document).ready(function() \{
            // does init function exist? if so, run it
            if (typeof init == 'function') \{ init(); \}
    };
    for(@{$self->{jQuery}}) {
        $str .= $_ . "\n";
    }
    $str .= "}); // end jQuery block\n";
    $str .= "</script>\n";

    return $html . "\n\n" . $str;
}

=head2 css

Change the CSS for a particular element.
    
    $j->css({ class => 'backgroundDiv', color => 'red' });

As of 0.14, the css method now supports multiple attributes.
No need to do anything special, HTML::JQuery will create the JS object for you.

    $j->css({
        id              => 'someDiv',
        'font-weight'   => 'bold',
        color           => '#0000FF',
        width           => '+=200',
    });

=cut

sub css {
    my ($self, $args) = @_;

    my ($id, $class, $element, $attr, $val);

    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($id) { delete $args->{id}; $element = "\$('#$id')"; }
    elsif ($class) { delete $args->{class}; $element = "\$('.$class')"; }

    my @attr_obj = ();
    for (keys %$args) {
        push @attr_obj, "'$_' : '$args->{$_}',"; 
        $attr = $_;
    }

    my $css;
    if (@attr_obj > 1) {
        my $str = join ' ', @attr_obj;
        $css = "$element.css({ $str });";
    }
    else { $css = "$element.css('$attr', '$args->{$attr}');"; }
    
    return $css;
}

=head2 fadeOut

Make an element hide, but with a nice fade effect.

    $j->fadeOut({id => 'hideThisDiv'});

=cut

sub fadeOut {
    my ($self, $args) = @_;

    my ($id, $class);

    if (ref $args eq 'HASH') {
        for (keys %$args) {
            $id = $args->{$_} if ($_ eq 'id');
            $class = $args->{$_} if ($_ eq 'class');
        }
    }
    else { $element = $args; }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    return "$element.fadeOut();";
}

=head2 slideToggle

Easily create a slide out panel with this method. It's similar to 
show with speed set to slow, but will automatically retract if you 
click on it when it's already unhidden and vice-versa.

    $j->onClick({
        class => 'thisDiv',
        event => $j->slideToggle($j->this),
    }); 

=cut

sub slideToggle {
    my ($self, $args) = @_;
    
    my ($class, $id);

    if (ref $args eq 'HASH') {
        for (keys %$args) {
            $id = $args->{$_} if ($_ eq 'id');
            $class = $args->{$_} if ($_ eq 'class');
        }
    }
    else { $element = $args; }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    return "$element.slideToggle();";
}

=head2 hover

Make stuff happen when hovering over an element.

    $j->hover({ class => 'MyElement', event => $j->alert('Annoying hover box!') });

Or you can make stuff happen when you hover over the element, then leave it.

    $j->hover({
        id      => 'button',
        event   => $j->css({ id => 'button-text', 'font-weight' => 'bold' }),
    },
        event => $j->css({ id => 'button-text', 'font-weight' => 'normal' }),
    });

=cut

sub hover {
    my ($self, $args, $args2) = @_;

    my ($id, $class, $element, $event, $event2);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $event = $args->{$_} if ($_ eq 'event');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($event) {
        if (ref $event eq 'CODE') {
            $event = $args->{event}->();
        }
    }
    
    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; } 

    my $hover = qq{
        $element.hover(function() \{
            $event
        \}
    };

    if (exists $args2->{event}) {
        if (ref $event2->{event} eq 'CODE') {
            $event2 = $args2->{event}->();
        }
        else { $event2 = $args2->{event}; }
        
        $hover .= ",function() { $event2 });";
    }
    else {
        $hover .= ");";
    }

    push @{$self->{jQuery}}, $hover;
}
=head2 modal

Generates a simple modal window. The returned string is $('#modal_name').dialog('open');
This method needs to be fixed as it's a bit picky with the title. The title is used 
as the modals id.

    $j->modal({
        title   => 'My Modal Title',
        message => 'The content of my modal',
        slide   => 1, # gives it a cool "slide" effect when it opens
    });

If you omit the buttons options, a default button of "OK" will be present which will simply 
close the current modal dialog. We can define them quite easy in Perl using a single string, 
or in an anonymous sub.

    $j->modal({
        autoOpen    => 1,
        title       => 'My Modal Title',
        message     => 'This modal pops up when the page is loaded',
        buttons     => {
            OK      => sub {
                my $data = $j->alert('You pressed OK');
                $data .= $j->this('modal', 'close');
                return $data;
            },
            Cancel  => $j->this('modal', 'close'),
        },
    });

=cut

sub modal {
    my ($self, $args) = @_;

    my ($active_on_click, $message, $title, $uri, $slide, $autoOpen, $buttons);
    for (keys %$args) {
        $title = $args->{$_} if ($_ eq 'title');
        $active_on_click = $args->{$_} if ($_ eq 'onClick');
        $message = $args->{$_} if ($_ eq 'message');
        $uri = $args->{$_} if ($_ eq 'get');
        $slide = $args->{$_} if ($_ eq 'slide');
        $autoOpen = $args->{$_} if ($_ eq 'autoOpen');
        $buttons = $args->{$_} if ($_ eq 'buttons');
    }
    
    my $b = "";
    if ($buttons) {
        for (keys %$buttons) {
            my $button = $_;
            my $data = $buttons->{$button};
           
            if (ref $data eq 'CODE') {
                $data = $data->();
            } 
            $b .= qq{
                $button: function() \{
                    $data
                \},
            };      
        }
    }
    else {
        $b = 'OK: function() { $(this).dialog("close"); }';
    }

    $autoOpen = $autoOpen ? 'true' : 'false';
    $message =~ s/\n//g;
    $message =~ s/'/\\'/g;
    $message =~ s/\$/\\\$/g;
    $slide = $slide ? "show: 'slide'," : "show: null,";
    my $mtitle = $title;
    $mtitle =~ s/ /_/g;
    my $bmodal = qq{
        var div = '<div id="modal_$mtitle" title="$title">$message</div>';
        \$(div)
        .appendTo('body')
        .dialog(\{
            autoOpen: $autoOpen,
            modal: true,
            width: 425,
            height: 275,
            $slide
            buttons: \{
                $b
            \}
        \});
    };

    if ($uri) {
        $bmodal .= qq{
            \$.get(
                 "$uri",
                  function(data) \{
                    \$('#modal_$mtitle').html(data);
                  \}
             );
        };
    }

    if ($active_on_click) {
        my $e = $active_on_click;
        $bmodal .= qq{
            \$('$e').click(function() \{
                \$('#modal_$mtitle').dialog('open');
            \});
        };
    }
    
    push(@{$self->{jQuery}}, $bmodal);
    return "\$('#modal_$mtitle').dialog('open');" if $autoOpen eq 'false';
}

=head2 alert

A basic Javascript alert box.

    $j->function(init => sub {
        $j->alert('Your document has loaded!');
    });

=cut

sub alert {
    my ($self, $txt) = @_;

    $txt =~ s/"/\\"/g;
    return "alert(\"$txt\");";
}

=head2 this

JQuery's $(this) syntax. It refers to the current element.

    $j->this('modal', 'open'); # returns $(this).dialog('open'); in jQuery
    $j->this('height'); # returns $(this).height(); in jQuery

=cut

sub this {
    my ($self, $what, $do) = @_;

    if (! $what) {
        return "\$(this)";
    }
    else {
        $what = 'dialog' if $what eq 'modal';
        
        if (! $do) { return "\$(this).$what();"; }
        else { return "\$(this).$what('$do');"; }
    }
}

=head2 keystrokes

This method uses the jquery.keystrokes plugin. The syntax is extremely easy to use 
and works exactly as expected.
Easily create events based on key presses.

    $j->keystrokes({
        keys        => [qw/ctrl+alt c/],
        success     => $j->callFunc('callme'),
    });

The above code will run whatever is set in success once ctrl+alt then m is pressed.
If you need to use arrow keys, try this.

    $j->keystrokes({
        keys        => ['arrow left', 'arrow down', 'arrow right', 'a', 'c'],
        success     => 'alert("Ryu says: Hadouken!");',
    });
=cut

sub keystrokes {
    my ($self, $args, $ret) = @_;

    my ($handler, $success, $keys);
    
    for(keys %$args) {
        $handler = $args->{$_} if ($_ eq 'handler');
        $keys = $args->{$_} if ($_ eq 'keys');
        $success = $args->{$_} if ($_ eq 'success');
    }

    $handler = $handler ? $handler : '*';
    $self->{ks}++;
    my $ks = $self->{ks};
    my $bkeys = "";
    for (@$keys) { $bkeys .= "'$_', "; }
    my $key = qq{
        \$('$handler').bind('keystrokes.$ks', \{
            keys: [ $bkeys ] \},
            function(event) \{
                $success
            \}
        );
    };
    
    push(@{$self->{jQuery}}, $key) unless $ret;
    return $key if $ret;        
}

=head2 ajax

Sends a GET/POST request to a page via AJAX and adds the data to 
the specified element.

    $j->onClick({
        class => 'button',
        event => $j->ajax('ajax/search', { id => 'ajaxDiv', method => 'get', search => 'content' })
    });

=cut

sub ajax {
    my ($self, $uri, $args) = @_;

    my ($id, $class, $element, $attr, $val, $method);

    $attr = "";
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $element = $args->{$_} if ($_ eq 'selector');
        $method = $args->{$_} if ($_ eq 'method');
    }

    if ($id) { delete $args->{id}; $element = "\$('#$id')"; }
    elsif ($class) { delete $args->{class}; $element = "\$('.$class')"; }
    
    if ($method) { delete $args->{method}; $method = lc $method; }

    for (keys %$args) {
        $attr .= "'$_' : '$args->{$_}', ";
    }

    my $ajax;
    if ($element) {
        $ajax = qq{
            \$.$method(
                "$uri",
                \{ $attr \},
                function(data) \{
                    $element.html(data);
                \}
            );
        };
    }
    else {
        $ajax = qq{
            \$.$method(
                "$uri",
                \{ $attr \},
                function(data) \{
                    return data;
                \}
            );
        };
    }
    
    return $ajax;
}

=head2 callFunc

Calls a Javascript function so you can use it in other events, ie: onClick
It also checks to make sure it's a valid function, and if not returns false

    $j->callFunc(funcName);

=cut

sub callFunc {
    my ($shit, $func) = @_;

    return qq{
        if (typeof $func == 'function') \{ $func(); \} else \{ return false; \}
    };
}

=head2 onClick

Create an onClick event. You decide what element the event is 
for by setting id => or class =>
For example, if you use class => 'button' then the event handler will be $('.button') 
or $('#button') for id => 'button'. The other argument is event. Once the onClick is 
triggered, the value in event will be run.

    $j->function(clickMe => sub {
        qq { alert("I have been clicked.. arghhhh"); }
    });
    
    $j->onClick({ id => 'button', event => $j->callFunc('clickMe') });

=cut

sub onClick {
    my ($self, $args) = @_;

    my ($id, $class, $event, $element);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $event = $args->{$_} if ($_ eq 'event');
    }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    my $click = qq{
        $element.click(function() \{
            $event
       \});
    };

    push(@{$self->{jQuery}}, $click);
}

=head2 innerHtml

Adds the value of html to the specified class or id element. Similar to 
jQuery's $('element').html();
I really need to add an append also.

    # an empty div in the HTML
    <div id="mydiv"></div>

    # then from Perl
    $j->innerHtml({ id => 'mydiv', html => 'Oh wow! There is text in here now'});
=cut

sub innerHtml {
    my ($self, $args) = @_;

    my ($id, $class, $html, $element);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $html = $args->{$_} if ($_ eq 'html');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    $html =~ s/'/\\'/g;
    my $inner = qq{
        $element.html('$html');
    };

    #push(@{$self->{jQuery}}, $inner);
    return $inner;
}

=head2 show

Show a hidden element. ie: a div with display set to 'none'

    # HTML
    # <div id="myDiv" style="display:none">This is my hidden text</div>

    # Perl
    $j->show({ id => 'myDiv', speed => 'slow' });

    # This causes the content of myDiv to scroll down slowly, making it visible

=cut

sub show {
    my ($self, $args) = @_;

    my ($id, $class, $element, $speed);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $speed = $args->{$_} if ($_ eq 'speed');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    my $show;
    if ($speed) { $show = "$element.show('$speed');"; }
    else { $show = "$element.show();"; }

    return $show;
}

=head2 hide

The exact opposite of 'show'.

    $j->hide({ class => 'someBlock', speed => 'slow' });

=cut

sub hide {
    my ($self, $args) = @_;

    my ($id, $class, $element, $speed);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $speed = $args->{$_} if ($_ eq 'speed');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    my $hide;
    if ($speed) { $hide = "$element.hide('$speed');"; }
    else { $hide = "$element.hide();"; }

    return $hide;
}

=head2 showHide

This method incorporates the show and hide methods. If the given element is 
hidden, it will show it, and if it is visible (display:none), it will hide it. 
You can give it a speed too if you like.

    $j->onClick({
        class => 'button',
        event => $j->showHide({
            id      => 'myDiv',
            speed   => 'fast',
        }),
    });

=cut

sub showHide {
    my ($self, $args) = @_;

    my ($id, $class, $element, $speed);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $speed = $args->{$_} if ($_ eq 'speed');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    my $hs;
    if ($speed) {
        $hs = qq{
            var e = $element;
            if (e.is(':visible')) \{
                e.hide('$speed');
            \}
            else \{
                e.show('$speed');
            \}
        };
    }
    else {
        $hs = qq{
            var e = $element;
            if (e.is(':visible')) \{
                e.hide();
            \}
            else \{
                e.show();
            \}
        };
    }
    
    return $hs;
}

=head2 function

Builds a standard Javascript function. If you call it 'init' then 
that function will be run automatically once the document has loaded.

    $j->function(init => sub {
        qq{ alert('Your document has loaded'); }
    });

Javascript functions can be called with $j->callFunc(funcName)
=cut

sub function {
    my ($self, %args) = @_;
    my $f;
    for(keys %args) {
        my $inf = $args{$_}->();
        $f = qq{
            function $_() {
                $inf
            }
        };
    }
    push(@{$self->{jQuery}}, $f);
}

=head2 tooltip

Sets an element with the tooltip attribute. Once this is done the tooltip will be whatever 
is in the tags "title".
    
    # HTML
    <a id ="mylink" href="#" title="A link to nowhere">My Link</a>

    # Perl
    $j->tooltip({id => 'mylink'});
=cut

sub tooltip {
    my ($self, $args) = @_;

    my ($id, $class, $element);
    for (keys %$args) {
        $id = $args->{$_} if ($_ eq 'id');
        $class = $args->{$_} if ($_ eq 'class');
        $element = $args->{$_} if ($_ eq 'selector');
    }

    if ($id) { $element = "\$('#$id')"; }
    elsif ($class) { $element = "\$('.$class')"; }

    my $tooltip = "$element.tooltip();";
    push(@{$self->{jQuery}}, $tooltip);
}

=head1 BUGS

Please e-mail bradh@cpan.org

=head1 AUTHOR

Brad Haywood <bradh@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

1;

