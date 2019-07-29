# WebsocketClient

This is a demonstration of how to use gun (Erlang) with a GenServer wrapper in Elixir.

Why would you want to do this? I suspect for testing your websocket capable server.

## Installation
You need to have [Elixir and Erlang](https://elixir-lang.org/install.html) installed.

### Install dependencies
`mix deps.get`

### Install dependencies and compile
`mix deps.compile`

## Run
Once you have it installed.

`iex -S mix`

`iex> WebsocketClient.Application.open_ws`
`iex> WebsocketClient.Application.send_message("My name is Jonas!")`
`:ok`
`iex> `
`15:23:02.790 [info]  Message received "My name is Jonas!"`

`iex> WebsocketClient.Application.set_from`
`15:26:41.332 [info]  Sending... "I love you"`
`15:26:41.449 [info]  I love you more!`

I promise this makes sense if you look at the code. :)

That's it! Have fun.