_ = require "underscore"
Backbone = require "backbone"
{AppDispatcher} = require "../dispatchers"
marked = require "marked"
Q = require "q"
ipython = require "../utils/ipython"

AppDispatcher.register (payload) ->
  switch payload.actionType
    when "content:changed"
      stack = new CardStack()
      stack.parse payload.content


class Card extends Backbone.Model
  render: ->
    deferred = Q.defer()
    if @get "isCode"
      ipython.execute @get "raw"
        .then deferred.resolve
    else
      _.defer =>
        deferred.resolve marked @get "raw"
    deferred.promise

class CardStack extends Backbone.Collection
  parse: (raw) ->
    data = []
    previous = false
    for line in raw.split "\n"
      indented = line[0...4] is "    "

      if previous is indented
        data.push line.trim()
        continue

      @add new Card
        raw: (data.join "\n").trim()
        isCode: !indented
      data = [line.trim(), ]
      previous = indented

    @add new Card
      raw: (data.join "\n").trim()
      isCode: indented # TODO ??


module.exports =
  Card: Card
  CardStack: CardStack