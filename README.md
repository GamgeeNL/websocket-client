# WebsocketClient

This is a demonstration of how to use [gun](https://ninenines.eu/docs/en/gun/1.3/guide/) (Erlang) with a GenServer wrapper in Elixir.

Why would you want to do this? I suspect for testing your websocket capable server.

If you don't know why you would want to then this probably isn't for you.

As is it is just pinging echo.websocket.org for demonstration purposes. You'll have to point it somewhere else to do something smarter with it.

## Installation
You need to have [Elixir and Erlang](https://elixir-lang.org/install.html) installed.

### Install dependencies
`mix deps.get`

### Install dependencies and compile
`mix deps.compile`

## Run
Once you have it installed.

`iex -S mix`

You need to open the websocket before attempting to send messages.

`iex> WebsocketClient.Application.open_ws`

Send messages and the replies come back automatically.

`iex> WebsocketClient.Application.send_message("My name is Jonas!")`

`:ok`

`iex> `
`15:23:02.790 [info]  Message received "My name is Jonas!"`

Use set_from if you want to use it remotely...

`iex> WebsocketClient.Application.set_from`

`15:26:41.332 [info]  Sending... "I love you"`

`15:26:41.449 [info]  I love you more!`

I promise this makes sense if you look at the code. :)

That's it! Have fun.