# Description:
#   Help keep track of whats being ordered for lunch
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Notes:
#   nom nom nom
#
# Author:
#   @poteto
#

##
# Explain how to use the lunch bot
COMMANDS = """
Let's order lunch!!!1 You can say:

`beemo lunch I want <order>` - adds `<order>` to the lunch order
`beemo lunch remove my order` - removes your order
`beemo lunch orders` - lists all orders
`beemo lunch help` - displays this help message
`beemo lunch vote for <item>` - where `<item>` is the choice number or the choice name
`beemo lunch show choices` - shows current choices
`beemo lunch show votes` - shows current votes
"""

JACK_COMMANDS = """
Hi Jack! In addition to the usual commands, you can also tell me:

`beemo lunch is over` - cancels all the orders
`beemo lunch start` - starts a new lunch order
`beemo lunch new vote <item1>, <item2>, <item3>, ...` - starts a vote for where we should eat lunch
`beemo lunch end vote` - ends the vote
"""

module.exports = (robot) ->
  robot.brain.on 'loaded', ->
    robot.brain.data.lunch ||= {}
    robot.brain.data.voting ||= {}

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

    clearVotes: ->
      robot.brain.data.voting = {}

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

  ##
  # Starts a new lunch order and removes all previous items
  robot.respond /lunch start/i, (msg) ->
    username = msg.message.user.name
    if lunch.isJack(username)
      lunch.clear()
      msg.send "OK @everyone, it's time to order lunch!"
      msg.send COMMANDS
    else
      msg.send "Sorry #{username}, only Jack can start a new lunch order."

  ##
  # Display usage details
  robot.respond /lunch help/i, (msg) ->
    username = msg.message.user.name
    if lunch.isJack(username)
      msg.send JACK_COMMANDS
    else
      msg.send COMMANDS

  ##
  # Voting
  robot.respond /lunch new vote (.+)$/i, (msg) ->
    username = msg.message.user.name
    if !lunch.isJack(username)
      return msg.send "Sorry #{username}, only Jack can start a new lunch vote."

    if robot.brain.data.voting.votes?
      msg.send "A vote is already underway"
      sendChoices (msg)
    else
      robot.brain.data.voting.votes = {}
      createChoices msg.match[1]

      msg.send "Vote started"
      sendChoices(msg)

  robot.respond /lunch end vote/i, (msg) ->
    username = msg.message.user.name
    if !lunch.isJack(username)
      return msg.send "Sorry #{username}, only Jack can end the lunch vote."

    if robot.brain.data.voting.votes?
      console.log robot.brain.data.voting.votes

      results = tallyVotes()

      response = "The results are..."
      for choice, index in robot.brain.data.voting.choices
        response += "\n#{choice}: #{results[index]}"

      msg.send response

      lunch.clearVotes()
    else
      msg.send "There is not a vote to end"

  robot.respond /lunch show choices/i, (msg) ->
    sendChoices(msg)

  robot.respond /lunch show votes/i, (msg) ->
    results = tallyVotes()
    sendChoices(msg, results)

  robot.respond /lunch vote (for )?(.+)$/i, (msg) ->
    choice = null

    re = /\d{1,2}$/i
    if re.test(msg.match[2])
      choice = parseInt msg.match[2], 10
    else
      choice = robot.brain.data.voting.choices.indexOf msg.match[2]

    console.log choice

    sender = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name

    if validChoice choice
      robot.brain.data.voting.votes[sender] = choice
      msg.send "#{sender} voted for #{robot.brain.data.voting.choices[choice]}"
    else
      msg.send "#{sender}: That is not a valid choice"

  createChoices = (rawChoices) ->
    robot.brain.data.voting.choices = rawChoices.split(/, /)

  sendChoices = (msg, results = null) ->

    if robot.brain.data.voting.choices?
      response = ""
      for choice, index in robot.brain.data.voting.choices
        response += "#{index}: #{choice}"
        if results?
          response += " -- Total Votes: #{results[index]}"
        response += "\n" unless index == robot.brain.data.voting.choices.length - 1
    else
      msg.send "There is not a vote going on right now"

    msg.send response

  validChoice = (choice) ->
    numChoices = robot.brain.data.voting.choices.length? - 1
    0 <= choice <= numChoices

  tallyVotes = () ->
    results = (0 for choice in robot.brain.data.voting.choices)

    voters = Object.keys robot.brain.data.voting.votes
    for voter in voters
      choice = robot.brain.data.voting.votes[voter]
      results[choice] += 1

    results
