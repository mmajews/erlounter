%%%-------------------------------------------------------------------
%%% @author Hubert
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. gru 2014 15:54
%%%-
-module(test).
-author("Hubert").

%% API
-compile(export_all).
-export([printing/4]).
-export([page_info/1]).
-export([got_page_info/3]).
-export([content_length/1]).
-export([spawn_workers/3]).
-export([get_info/2]).
-export([get_url_context/1]).
-export([wait_for_responses/2]).
-export([check/0]).
%declaring record that will hold number of images, css and scripts
-record(state, {page,timer,errors,img,css,script}).
-record(result, {html, script, img}).
check()->
  "LOL".

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
  spawn_workers(URL,img,lists:map(fun  binary_to_list/1,Imgs)),
  spawn_workers(URL,script,lists:map(fun  binary_to_list/1,Scripts)),
  
  %Starts a timer which will send the message Msg to Dest after Time milliseconds.
  TRef = erlang:send_after(3000,self(),timeout),
  State = #state{page=PageSize,
    timer=TRef,
    errors=[],
    img=0,
    css=0,
    script=0},


  %number of elements -> so number of responses we should wait for
  Result = wait_for_responses(State,length(Imgs)  + length(Scripts)),
%%   string:concat(string:concat(string:concat(string:concat(string:concat("Images: ",float_to_list(Result#result.img,[{decimals, 4}]))," Html: "),
%%     float_to_list(Result#result.html,[{decimals, 4}]))," Scripts: "),
%%     float_to_list(Result#result.script,[{decimals, 4}])).

          "Images: " ++ float_to_list(Result#result.img,[{decimals, 4}]) ++
          "kB Html: " ++ float_to_list(Result#result.html,[{decimals, 4}]) ++
          "kB Scripts: " ++ float_to_list(Result#result.script,[{decimals, 4}]) ++ "kB".

  %Result#result.img ++ Result#result.script.

content_length(Headers) ->
  %proplists:get_value(Key,List,Default)
  %returns the length of the content
  list_to_integer(proplists:get_value("content-length",Headers,"0")).

%function that removes dulpicate
rDup(L) ->
  sets:to_list(sets:from_list(L)).

%spawn workers for every URl, who send back info about components -> getinfo
spawn_workers(URLctx,Type,URLs) ->
  Supervisor = self(),
  lists:foreach(fun (Url) -> spawn( fun () ->
                                    Supervisor ! {component, Type,Url,get_info(URLctx,Url)}
                                    end)
              end, URLs).

get_url_context(URL) ->
  {ok,{http,_,Root,_Port,Path,_Query}} = http_uri:parse(URL),
  Ctx = string:sub_string(Path,1, string:rstr(Path,"/")),
  {"http://"++Root,Ctx}. %% gib my url with context

get_info(URlctx,Url) ->
  FullURL = full_url(URlctx,Url),
  case httpc:request(head,{FullURL,[]},[],[]) of
    {ok, {_,Headers,_Body}} ->
      {ok,content_length(Headers)};
    {error,Reason} ->
      {error,Reason}
  end.


%FULL URL FUNCTIONS
%% abs url inside the same server ej: /img/image.png
full_url({Root,_Context},ComponentUrl=[$/|_]) ->
  Root ++ ComponentUrl;
%% full url ej: http://other.com/img.png
full_url({_Root,_Context},ComponentUrl="http://"++_) ->
  ComponentUrl;
% everything else is considerer a relative path.. obviously its wrong (../img)
full_url({Root,Context},ComponentUrl) ->
  Root ++ Context ++ "/" ++ ComponentUrl.

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
 finalize(State,Left) ->
  PageSize =  State#state.page,
  ImgSize =  State#state.img,
  CssSize =  State#state.css, %maybe one day will work
  ScriptSize =  State#state.script,
  Errors =  State#state.errors,
  TRef =  State#state.timer,
  erlang:cancel_timer(TRef),
  printing(PageSize,ImgSize,CssSize,ScriptSize).

printing(PageSize,ImgSize,CssSize,ScriptSize)->
  Result = #result{img = ImgSize/1024,html=PageSize/1024,script = ScriptSize/1024}.
