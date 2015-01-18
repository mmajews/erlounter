%%=======================
%% lm_app.erl
%%
%% @version 2
%%=======================
-module(lm_app).
-include("$YAWS_INCLUDES/yaws_api.hrl").
-export([arg_rewrite/1]).

login_pages() ->
  [ "/index.yaws", "/lewismanor.jpg", "/login_post.yaws" ].

arg_rewrite(Arg) ->
  io:fwrite("ARGUMENT REWRITING HIT!~n"),
  Arg.