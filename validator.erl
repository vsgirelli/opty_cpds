-module(validator).
-export([start/0]).

start() ->
    spawn_link(fun() -> init() end).

init()->
    validator().

validator() ->
    receive
        {validate, Ref, Reads, Writes, Client} ->
            Tag = make_ref(),
            send_read_checks(Reads, Tag),  %%
            N = length(Reads),
            case check_reads(N, Tag) of  %%
                ok ->
                    update(Writes),  %%
                    Client ! {Ref, ok};
                abort ->
                    Client ! {Ref, abort} %% The client sends messages always to the handler, but is the Validator who answers
            end,
            validator();
        stop ->
            ok;
        _Old ->
            validator()
    end.
    
update(Writes) ->
    lists:foreach(fun({_, Entry, Value}) -> 
                  Entry ! {write, Value}, %
                  end, 
                  Writes).

send_read_checks(Reads, Tag) ->
    Self = self(),
    lists:foreach(fun({Entry, Time}) -> 
                  Entry ! {check, Tag, Time, Self}, % 
                  end, 
                  Reads).

check_reads(0, _) ->
    ok;
check_reads(N, Tag) ->
    receive
        {Tag, ok} ->
            check_reads(N-1, Tag);
        {Tag, abort} ->
            abort
    end.
