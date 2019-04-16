use Cro::HTTP::Router;
use Cro::HTTP::Session::Red;
use Red;

model User is table<account> {
    has UInt $!id       is serial;
    has Str  $.name     is column;
    has Str  $.email    is column{ :unique };
}

model Session is table<logged_user> {
    has UInt $.id   is serial;
    has UInt $.uid  is referencing{ User.id };
    has User $.user is relationship{ .uid };
}

sub routes() is export {
    route {
        before Cro::HTTP::Session::Red[Session].new;
        get -> {
            content 'text/html', "<h1> \$session.gist() </h1>";
        }
    }
}
