-module(handler).
-export([start/3]).

start(Client, Validator, Store) ->
    spawn_link(fun() -> init(Client, Validator, Store) end). % created for a specifc client and holding the store and the Validator ID

init(Client, Validator, Store) ->
    handler(Client, Validator, Store, [], []).

handler(Client, Validator, Store, Reads, Writes) ->         
    receive
        {read, Ref, N} -> % N is the Entry (a tuple with N, Pid, Value)
            case lists:keyfind(N, 1, Writes) of  %% searches in Writes if the Key of the Nth element corresponds to Ref
                {N, _, Value} -> % returns e Value
                    Client ! {value, Ref, Value}, %%
                    handler(Client, Validator, Store, Reads, Writes);
                false -> % didn't find the Entry in the Writes
                    Entry = store:lookup(N, Store), % Store has Entries PIDs, so look for N in the Store and gets the Entry's PID
                    Entry ! {read, Ref, self()} % self gives the PID
                    handler(Client, Validator, Store, Reads, Writes)
            end;
        {Ref, Entry, Value, Time} -> % Entry's reply to line 18
            %% TODO: ADD SOME CODE HERE AND COMPLETE NEXT LINE forward to the client
            handler(Client, Validator, Store, [...|Reads], Writes);
        {write, N, Value} -> % only visible to the local store (store set)
            %% TODO: ADD SOME CODE HERE AND COMPLETE NEXT LINE
            Added = lists:keystore(N, 1, ..., {N, ..., ...}),
            handler(Client, Validator, Store, Reads, Added);
        {commit, Ref} ->
            %% TODO: ADD SOME CODE
        abort ->
            ok
    end.
