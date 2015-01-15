%%%-------------------------------------------------------------------
%%% @author Hubert
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. gru 2014 15:54
%%%-------------------------------------------------------------------
-module(test).
-author("Hubert").

%% API
-export([page_info/1]).
-export([got_page_info/3]).
-export([content_length/1]).
-export([]).
-export([]).
page_info(URL) ->
  inets:start(),
  case httpc:request(URL) of
    {ok,{_,Headers,Body}} ->
      got_page_info(URL,content_length(Headers),Body);
    {error,Reason} ->
      {error,Reason}
  end.

got_page_info(URL, PageSize,Body) ->
  %getting the parsed version of website
  Tree = mochiweb_html:parse(Body),

  %particular files being listed and removing duplicates


  lists:flatten(io_lib:format("~p", [Tree])).


content_length(Headers) ->
  %proplists:get_value(Key,List,Default)
  %returns the length of the content
  list_to_integer(proplists:get_value("content-length",Headers,"0")).

%function that removes dulpicate
rDup(L) ->
  sets:to_list(sets:from_list(L)).