%% -*- erlang-indent-level: 4; indent-tabs-mode: nil; fill-column: 80 -*-
%%% Copyright 2012 Erlware, LLC. All Rights Reserved.
%%%
%%% This file is provided to you under the Apache License,
%%% Version 2.0 (the "License"); you may not use this file
%%% except in compliance with the License.  You may obtain
%%% a copy of the License at
%%%
%%%   http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing,
%%% software distributed under the License is distributed on an
%%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%%% KIND, either express or implied.  See the License for the
%%% specific language governing permissions and limitations
%%% under the License.
%%%---------------------------------------------------------------------------
%%% @author Jordan Wilberding <jwilberding@gmail.com>
%%% @copyright (C) 2013 Erlware, LLC.
%%%
%%% @doc 
%%%  An Erlang API for Ogone
%%% @end

-module(eogone).

-export([new_params/0,
         new_params/3,
         new_params/4,
         charge/1,
         charge/5]).

-include("eogone.hrl").

-define(DEFAULT_URL, <<"https://secure.ogone.com/ncol/prod/orderdirect.asp">>).
-define(DEFAULT_PSP_ID, <<"CHANGE_ME">>).
-define(DEFAULT_USER_ID, <<"CHANGE_ME">>).
-define(DEFAULT_PSWD, <<"CHANGE_ME">>).

%%%===================================================================
%%% New record functions
%%%===================================================================

-spec new_params() -> record(ogone_params).
new_params() ->
    {ok, URL} = with_default(application:get_env(eogone, url), ?DEFAULT_URL),
    {ok, PSPID} = with_default(application:get_env(eogone, login), ?DEFAULT_PSP_ID),
    {ok, UserID} = with_default(application:get_env(eogone, tran_key), ?DEFAULT_USER_ID),
    {ok, PSWD} = with_default(application:get_env(eogone, pswd), ?DEFAULT_PSWD),
    #ogone_params{url=URL, psp_id=PSPID, user_id=UserID, pswd=PSWD}.

-spec new_params(binary(), binary(), binary()) -> record(ogone_params).
new_params(PSPID, UserID, PSWD) ->
    {ok, URL} = with_default(application:get_env(eogone, url), ?DEFAULT_URL),
    #ogone_params{url=URL, psp_id=PSPID, user_id=UserID, pswd=PSWD}.

-spec new_params(binary(), binary(), binary(), binary()) -> record(ogone_params).
new_params(URL, PSPID, UserID, PSWD) ->
    #ogone_params{url=URL, psp_id=PSPID, user_id=UserID, pswd=PSWD}.

-spec new_result(binary()) -> record(ogone_result).
new_result(Result) ->
    {{xmlElement,ncresponse,ncresponse,[],
      {xmlNamespace,[],[]},
      [],1,
      [{xmlAttribute,'ORDERID',[],[],[],[{ncresponse,1}],1,[],OrderID,false},
       {xmlAttribute,'PAYID',[],[],[],[{ncresponse,1}],2,[],PayID,false},
       {xmlAttribute,'NCSTATUS',[],[],[],[{ncresponse,1}],3,[],NCStatus,false},
       {xmlAttribute,'NCERROR',[],[],[],[{ncresponse,1}],4,[],NCError,false},
       {xmlAttribute,'ACCEPTANCE',[],[],[],[{ncresponse,1}],5,[],Acceptance,false},
       {xmlAttribute,'STATUS',[],[],[],[{ncresponse,1}],6,[],Status,false},
       {xmlAttribute,'AMOUNT',[],[],[],[{ncresponse,1}],7,[],Amount,false},
       {xmlAttribute,'CURRENCY',[],[],[],[{ncresponse,1}],8,[],Currency,false},
       {xmlAttribute,'PM',[],[],[],[{ncresponse,1}],9,[],PM,false},
       {xmlAttribute,'BRAND',[],[],[],[{ncresponse,1}],10,[],Brand,false},
       {xmlAttribute,'NCERRORPLUS',[],[],[],[{ncresponse,1}],11,[],NCErrorPlus,false}],
      [{xmlText,[{ncresponse,1}],1,[],"\n",text}],
      [],_Path,undeclared},
     []} = xmerl_scan:string(binary_to_list(Result)),
    #ogone_result{order_id=list_to_binary(OrderID), pay_id=list_to_binary(PayID), nc_status=list_to_binary(NCStatus), nc_error=list_to_binary(NCError), acceptance=list_to_binary(Acceptance), status=list_to_binary(Status), amount=list_to_binary(Amount), currency=list_to_binary(Currency), pm=list_to_binary(PM), brand=list_to_binary(Brand), nc_error_plus=list_to_binary(NCErrorPlus)}.


%%%===================================================================
%%% Charge functions
%%%===================================================================

-spec charge(record(ogone_params)) -> record(ogone_result).
charge(#ogone_params{url=URL, order_id=OrderID, psp_id=PSPID, user_id=UserID, pswd=PSWD, card_num=CardNum, exp_date=ExpDate, card_code=CardCode, amount=Amount}) ->
    Method = post,
    Headers = [],
    Payload = << <<"PSPID=">>/binary, PSPID/binary, <<"&ORDERID=">>/binary, OrderID/binary, <<"&USERID=">>/binary, UserID/binary, <<"&PSWD=">>/binary, PSWD/binary, <<"&AMOUNT=">>/binary, Amount/binary, <<"&CURRENCY=EUR&CARDNO=">>/binary, CardNum/binary, <<"&ED=">>/binary, ExpDate/binary, <<"&CVC=">>/binary, CardCode/binary, <<"&OPERATION=RES">>/binary >>,
    Options = [],
    {ok, _StatusCode, _RespHeaders, Client} = hackney:request(Method, URL, Headers, Payload, Options),
    {ok, Body, _Client1} = hackney:body(Client),
    new_result(Body).
    %%new_result(binary:split(Body, [<<"|">>], [global])).

-spec charge(binary(), binary(), binary(), binary(), binary()) -> record(ogone_result).
charge(OrderID, CardNum, ExpDate, CardCode, Amount) ->
    AuthParams = new_params(),
    AuthParams2 = AuthParams#ogone_params{order_id=OrderID, card_num=CardNum, exp_date=ExpDate, card_code=CardCode, amount=Amount},
    charge(AuthParams2).


%%%===================================================================
%%% Local helper functions
%%%===================================================================

-spec with_default(any(), any()) -> any().
with_default(X, Y) ->
    case X of
        undefined ->
            {ok, Y};
        _ ->
            X
    end.
