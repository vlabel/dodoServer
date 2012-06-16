-module(megaser).

-behaviour(gen_server).
-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
          terminate/2, code_change/3,start/1,stop/0]).

-export([accept_func/1]).
-export([set_func/1]).	
-export([receive_responce/2]).
-define(SERVER, ?MODULE). 
-define(LOGIC_MODULE, tcp_fsm).
				  
-record(state, {
       listener,       %% Listening socket
         module          %% FSM handling module
							           }).


-define(TRANS_STMT, <<"INSERT INTO `trans` ("
			 "  `name`,                                    "
			 "  `imei`,                                    "
             "  `gsm`,                                     "
             "  `time`,                                    "
			 "  `cdma`,                                    "
			 "  `wcdma`,                                   "
			 "  `altitude`,                                "
	 	    "  `longitude`,                                 "
            "  `azimuth`,                                 "
	   	   "  `xM`,                                 "
  	 		 "  `yM`,                                 "
             "  `zM`,                                 "
             "  `xA`,                                 "
             "  `yA`,                                 "
             "  `zA`                                "
			 ") VALUES ("
			 "  ?," % name 
			 "  ?," % imei
			 "  ?," % gsm 
			 " FROM_UNIXTIME(?)," % time
	 	   	"  ?," % cdma
			 "  ?," % wcdma
			 "  ?," % altitude
			 "  ?," % longitude
			 "  ?," % azmuth
             "  ?," % xM
			 "  ?," % yM
			 "  ?," % zM
			 "  ?," % xA
			 "  ?," % yA
			 "  ?" % zA 
		   	")">>
	    ).


									   
			
start([Port]) ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [Port], []),
	emysql:add_pool(mypoolname, 3, "user", "123456", "192.168.0.66", 3306, "dodo", utf8).
	%io:format("Pool connection to mysql (~p).~n", [Re]).
stop() -> gen_server:call(?MODULE, stop).



	
start_link(Port) ->
       gen_server:start_link({local, ?SERVER}, ?MODULE, [Port], []).
											   
init([Port]) ->
     Options = [{packet, raw}, {active, false}, {reuseaddr, true}],
	       case gen_tcp:listen(Port, Options) of
	       {ok, LSocket} ->
         %% Create first accepting process
   spawn_link(?MODULE, accept_func, [LSocket]),
    {ok, #state{listener = LSocket, module   = ?LOGIC_MODULE}};
    {error, Reason} ->
    error_logger:error_msg("Error: ~p~n", [Reason]), {stop, Reason}
    end.
		   
																				   
handle_call(_Request, _From, State) ->
	       Reply = ok,
	       {reply, Reply, State}.
																			   
																		   
handle_cast(_Msg, State) ->
	       {noreply, State}.
																									   
														   
handle_info(_Info, State) ->
		       {noreply, State}.
																									   
terminate(_Reason, #state{listener = LSocket} = _State) ->
				       gen_tcp:close(LSocket),
			       ok.
																										   
code_change(_OldVsn, State, _Extra) ->
				       {ok, State}.
																													   
accept_func(LSocket) ->
 	{ok, Socket} = gen_tcp:accept(LSocket),
  	error_logger:info_msg("Accept connection: ~p.\n", [Socket]),
	{ok,Bin} = receive_responce(Socket,[]),
    accept_func(LSocket).
    %ok = gen_tcp:close(Socket).


receive_responce(Sock,Bs) ->
io:format("Sock (~p)~n", [Sock]),
case gen_tcp:recv(Sock, 0) of
    {ok, B} ->
	io:format("Receiving message of size (~p).~n", [B]),
	Res = mochijson2:decode(B),
	set_func(Res),
	receive_responce(Sock,[Bs,B]);
	{error,Reason} ->
	io:format("Cannot receive (~p)~n", [Reason]),
	{ok,Bs}
	end.

	


set_func(B) ->
	io:format("Get One Package ~p ~n", [B]),
	emysql:prepare(my_stmt, ?TRANS_STMT),
	Rname = 	lists:nth(2, B),
	Rimei =     lists:nth(1, B),
	Rgsm =      lists:nth(3, B),
	Rtime =     lists:nth(4, B),
	Rcdma =     lists:nth(5, B),
	Rwcdma =    lists:nth(6, B),
	Raltitude = lists:nth(7, B),
	Rlongitude =lists:nth(8, B),
	Razimuth =	lists:nth(9, B),
	RxM =		lists:nth(10, B),
	RyM =		lists:nth(11, B),
	RzM =		lists:nth(12, B),
	RxA =		lists:nth(13, B),
	RyA =		lists:nth(14, B),
	RzA =		lists:nth(15, B),

    case	emysql:execute(mypoolname, my_stmt,[Rname,Rimei,Rgsm,Rtime,Rcdma,Rwcdma,Raltitude,Rlongitude,Razimuth,RxM,RyM,RzM,RxA,RyA,RzA]) of
	{ok_packet,1,1,_,_,_,_} ->
		io:format("Transaction added to base ~n");
	{error_packet, _, Code, _, Msg} ->
	io:format("Error! emysql:execute error! ~s ~w  ~n",[Msg,Code])
   end.






	
