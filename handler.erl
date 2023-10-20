-module(handler).
-export([start/3]).

start(Client, Validator, Store) ->
    spawn_link(fun() -> init(Client, Validator, Store) end). % created for a specifc client and holding the store and the Validator ID

init(Client, Validator, Store) ->
    handler(Client, Validator, Store, [], []).

handler(Client, Validator, Store, Reads, Writes) ->         
    receive
        {read, Ref, N} -> % N is the Entry (a tuple with N, Pid, Value)
            case lists:keyfind(N, 1, Writes) of  %% searches in Writes if the Key 1 of the Nth element corresponds to Ref
                {N, _, Value} -> % returns the Value
                    Client ! {value, Ref, Value}, %%
                    handler(Client, Validator, Store, Reads, Writes);
                false -> % didn't find the Entry in the Writes
                    Entry = store:lookup(N, Store), % Store has Entries PIDs, so look for N in the Store and gets the Entry's PID
                    Entry ! {read, Ref, self()}, % self gives the PID
                    handler(Client, Validator, Store, Reads, Writes)
            end;
        {Ref, Entry, Value, Time} -> % Entry's reply to line 18
            Client ! {value, Ref, Value}, %% forward to the client
            handler(Client, Validator, Store, [ {Entry, Time} | Reads], Writes); % the {Entry, Time} is saved in the Reads
        {write, N, Value} -> % only visible to the local store (store set)
            Entry = store:lookup(N, Store), % Store has Entries PIDs, so look for N in the Store and gets the Entry's PID TODO check
            Added = lists:keystore(N, 1, Writes, {N, Entry, Value}), % store the new {N, Entry, Value} to the Writes in the Nth element
            handler(Client, Validator, Store, Reads, Added);
        {commit, Ref} ->
            Validator ! {validate, Ref, Reads, Writes, Client} %% sends the Reads and Writes to the Validator (to check for conflicts)
        abort ->
            ok
    end.
