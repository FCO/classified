use Cro::HTTP::Router;
use Cro::HTTP::Session::Red;
use Red;

model UserSession { ... }

model User is table<account> {
    has UInt            $!id       is serial;
    has Str             $.name     is column;
    has Str             $.email    is column{ :unique };
    has Str             $.password is column;
    has UserSession     @.sessions is relationship{ .uid }

    method check-password($password) {
        $password eq $!password
    }
}

model UserSession is table<logged_user> does Cro::HTTP::Auth {
    has Str  $.id         is id;
    has UInt $.uid        is referencing{ User.id };
    has User $.user       is relationship{ .uid } is rw;
}

sub routes() is export {
    route {
        before Cro::HTTP::Session::Red[UserSession].new: cookie-name => 'MY_SESSION_COOKIE_NAME';
        get -> UserSession $session {
            content 'text/html', "<h1> Logged User: $session.user.name() </h1>";
        }

        get -> 'login' {
            content 'text/html', q:to/HTML/;
                <form method="POST" action="/login">
                    <div>
                        Username: <input type="text" name="email" />
                    </div>
                    <div>
                        Password: <input type="password" name="password" />
                    </div>
                    <input type="submit" value="Log In" />
                </form>
            HTML
        }

        post -> UserSession $session, 'login' {
            request-body -> (Str() :$email, Str() :$password, *%) {
                my $user = User.^load: :$email;
                if $user.?check-password: $password {
                    $session.user = $user;
                    $session.^save;
                    redirect '/', :see-other;
                }
                else {
                    content 'text/html', "Bad username/password";
                }
            }
        }
    }
}
