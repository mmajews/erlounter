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
-export([spawn_workers/3]).
-export([get_info/2]).
-export([get_url_context/1]).
-export([wait_for_responses/2]).

%declaring record that will hold number of images, css and scripts
-record(state, {page,timer,errors,img,css,script}).



page_info(URL) ->
  inets:start(),
  case httpc:request(URL) of
    {ok,{_,Headers,Body}} ->
      got_page_info(URL,content_length(Headers),Body);
    {error,Reason} ->
      {error,Reason}
  end.



got_page_info(URLpassed, PageSize,Body) ->
  %getting the parsed version of website
  Tree = mochiweb_html:parse(Body),


  %particular files being listed and removing duplicates
  Imgs = rDup(mochiweb_xpath:execute("//img/@src",Tree)),

  %css does not work, do not know why
  %Css = rDup(mochiweb_xpath:execute("//link[@rel=’stylesheet’]/@href",Tree)),

  Scripts = rDup(mochiweb_xpath:execute("//script/@src",Tree)),

  %preapring URL
  URL = get_url_context(URLpassed),

  %Starts a timer which will send the message Msg to Dest after Time milliseconds.
  TRef = erlang:send_after(10000,self(),timeout),
  State = #state{page=PageSize,
    timer=TRef,
    errors=[],
    img=0,
    css=0,
    script=0},

  %number of elements -> so number of responses we should wait for
  wait_for_responses(State,length(Imgs)  + length(Scripts)),

  lists:flatten(io_lib:format("~p", [Tree])).

content_length(Headers) ->
  %proplists:get_value(Key,List,Default)
  %returns the length of the content
  list_to_integer(proplists:get_value("content-length",Headers,"0")).

%function that removes dulpicate
rDup(L) ->
  sets:to_list(sets:from_list(L)).

%spawn workers for every URl, who send back info about components -> getinfo
spawn_workers(URLctx,Type,URLs) ->
  lists:foreach(fun (Url) -> spawn( fun () ->
                                    self() ! {component, Type,Url,get_info(URLctx,Url)}
                                    end)
              end, URLs).

get_url_context(URL) ->
  {http,_,Root,_Port,Path,_Query} = http_uri:parse(URL),
  Ctx = string:sub_string(Path,1, string:rstr(Path,"/")),
  {"http://"++Root,Ctx}. %% gib my url with context

get_info(URlctx,Url) -> [].

%collect infos recieved from wait_for_resposnses and add them to proper field of State
collect_info(State = #state{css=Css},css,_URL,{ok,Info}) ->
         State#state{css = Css + Info};
collect_info(State = #state{img=Img},img,_URL,{ok,Info}) ->
         State#state{img = Img + Info};
collect_info(State = #state{script=Script},script,_URL,{ok,Info}) ->
         State#state{script = Script + Info};
collect_info(State = #state{errors=Errors},_Type,URL,{error,Reason}) ->
         State#state{errors=[{URL,Reason}|Errors]}.

%messages from workers
wait_for_responses(State,0) ->
    finalize(State,0);

wait_for_responses(State,Counter) ->
    receive
      {component,Type,URL,Info} ->
          wait_for_responses(collect_info(State,Type,URL,Info),Counter - 1);
      timeout -> finalize(State,Counter)
    end.

%prepares variables for printing
finalize(State,Left) -> [].