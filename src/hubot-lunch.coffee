# Description:
#   Help keep track of whats being ordered for lunch
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot lunch I want <food> - adds <food> to the list of items to be ordered
#   hubot lunch remove my order - just removes the users lunch order
#   hubot lunch orders - list all the items in the current lunch order
#   hubot lunch is over - clears out list of items to be ordered
#   hubot lunch help - display help message
#
# Notes:
#   nom nom nom
#
# Author:
#   @poteto
#

##
# Explain how to use the lunch bot
MESSAGE = """
Let's order lunch!!!1 You can say:

`beemo lunch I want the BLT Sandwich` - adds "BLT Sandwich" to the list of items to be ordered
`beemo lunch remove my order` - removes your order
`beemo lunch is over` - cancels all the orders (if you're Jack)
`beemo lunch start` - starts a new lunch order (if you're Jack)
`beemo lunch orders` - lists all orders
`beemo lunch help` - displays this help message
"""

module.exports = (robot) ->
  robot.brain.data.lunch = {}
  ##
  # Define the lunch functions
  lunch =
    get: ->
      Object.keys(robot.brain.data.lunch)

    add: (user, item) ->
      robot.brain.data.lunch[user] = item

    remove: (user) ->
      delete robot.brain.data.lunch[user]

    clear: ->
      robot.brain.data.lunch = {}

    isJack: (user) ->
      user.indexOf('jack') isnt -1

  ##
  # List out all the orders
  robot.respond /lunch orders$/i, (msg) ->
    orders = lunch.get().map (user) -> "#{user}: #{robot.brain.data.lunch[user]}"
    msg.send orders.join("\n") || "No items in the lunch list."

  ##
  # Save what a person wants to the lunch order
  robot.respond /lunch i want (.*)/i, (msg) ->
    item = msg.match[1].trim()
    username = msg.message.user.name
    lunch.add username, item
    msg.send "OK #{username}, added #{item} to your order."

  ##
  # Remove the persons items from the lunch order
  robot.respond /lunch remove my order/i, (msg) ->
    username = msg.message.user.name
    lunch.remove username
    msg.send "OK #{username}, I removed your order."

  ##
  # Cancel the entire order and remove all the items
  robot.respond /lunch is over/i, (msg) ->
    username = msg.message.user.name
    if lunch.isJack(username)
      delete robot.brain.data.lunch
      lunch.clear()
      msg.send "Lunch is over! http://i.imgur.com/DjUFGk5.png"
    else
      msg.send "Sorry #{username}, only Jack can clear lunches."

  robot.respond /lunch start/i, (msg) ->
    username = msg.message.user.name
    if lunch.isJack(username)
      lunch.clear()
      msg.send "OK @everyone, it's time to order lunch!"
      msg.send MESSAGE
    else
      msg.send "Sorry #{username}, only Jack can start a new lunch order."

  ##
  # Display usage details
  robot.respond /lunch help/i, (msg) ->
    msg.send MESSAGE
