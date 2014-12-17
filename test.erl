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

page_info(URL) ->
  inets:start(),
  case httpc:request(URL) of
    {ok,{_,Headers,Body}} ->
      got_page_info(URL,content_length(Headers),Body);
    {error,Reason} ->
      {error,Reason}
  end.

got_page_info(URL, PageSize,Body) ->
  Tree = mochiweb_html:parse(Body),
  Tree.

content_length(Headers) ->
  list_to_integer(proplists:get_value("content-length",Headers,"0")).