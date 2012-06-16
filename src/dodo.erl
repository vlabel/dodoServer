-module(dodo).


-export([start/0]).

start() ->
    crypto:start(),
    application:start(emysql),
    megaser:start([3456]).		




	
