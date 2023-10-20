-module(entry).
-export([new/1]).

new(Value) ->
    spawn_link(fun() -> init(Value) end).

init(Value) ->
    entry(Value, make_ref()).

entry(Value, Time) ->
    receive
        {read, Ref, From} ->
            From ! {Ref, self(), Value, Time}, % self gives the PID
            entry(Value, Time);
        {write, New} ->
            entry(New, make_ref());  %% writes the New value
        {check, Ref, Readtime, From} ->
            if
                Time == Readtime ->   %% If the read time is the same as the previous timestamp, is the same value
                    From ! {Ref, ok}; %% so transaction is ok
                true ->
                    From ! {Ref, abort}
            end,
            entry(Value, Time);
        stop ->
            ok
    end.
