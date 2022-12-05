# frozen_string_literal: true

require 'yaml'

# 1. load in the dictionary
#     - use File::open with 'r'
# 2. select a word between 5 and 12 characters long randomly for the secret word
#     - use File#readlines with chomp: true to get the words array
#     - use Array#select to get the letters that are between 5 and 12 characters long
#     - use Array#sample
#     - assign it to secret_word
#     - use File#close
# 3. display turns left
#     - create turns variable and set it to 5
# 4. allow the player to make a guess of a letter(case insensitive) for each turn
#     - repeat
#     - prompt the player to type in a letter
#     - assign it to guessed_letter
#     - until it is a letter
#     - add it to guessed_letters
#     - reduce the turns by 1
# 5. display correct letters and their position in the word
#     - map secret_word (use Array#map)
#     - any letter that are not in the guessed_letters are replaced with "_"
#     - assign it to correct_letters
# 6. display incorrect letters that have already been chosen
#     - select letters from guessed_letters that are not in the correct_letters (use Array#select)
#     - assign it to incorrect_letters
# 7. repeat from step #4 to #7 until turns becomes 0 or player solves the word
#     - if there is no more turn, the player loses
#         - if turns == 0
#         - print 'You lose.'
#         - end the program
#     - if the player solves the word, the player wins
#         - if the correct_letters and secret_word become the same
#         - print 'You win.'
# 8. let the player to save at the start of any turn
#     - prompt the player to save the game by asking to type 'y' or 'n'
#     - if the player types 'y'
#        - serialize data into yaml file
#        - create output directory if not existed with Dir::exist? and Dir::mkdir
#        - save the file under output folder with File::open using 'w' together with File.puts
#     - else skip to step #4
# 9. let the player to open one of the saved games or start a new game

# module Savable
module Savable
  FILE_DIR = 'output/saved_file.yaml'

  def save(data)
    Dir.mkdir('output') unless Dir.exist?('output')
    File.open(FILE_DIR, 'w') { |file| file.puts data }
  end

  def load_data
    YAML.load_file(FILE_DIR, symbolize_names: true) if File.exist?(FILE_DIR)
  end
end

# module YAMLable
module YAMLable
  def to_yaml
    obj = {}
    instance_variables.map { |var| obj[var.to_s.delete('@')] = instance_variable_get(var) }
    YAML.dump(obj)
  end
end

# module Hangman
module Hangman
  # 1. load in the dictionary and get the words
  DATA_FILE = File.open('dictionary.txt', 'r')
  WORDS = DATA_FILE.readlines(chomp: true)
  DATA_FILE.close

  def self.setup
    game = Game.new
    game.play(WORDS)
  end

  # class Game
  class Game
    include Savable
    include YAMLable

    INITIAL_STATE = {
      secret_word: [],
      correct_letters: [],
      incorrect_letters: [],
      turns: 12,
      guessed_letters: []
    }.freeze

    def initialize
      # if player chooses to load the existing game, load the game. else start with initial state
      state = choose_game == 'load game' ? load_data : INITIAL_STATE
      @secret_word = state[:secret_word]
      @correct_letters = state[:correct_letters]
      @incorrect_letters = state[:incorrect_letters]
      @turns = state[:turns]
      @guessed_letters = state[:guessed_letters]
    end

    # 7. repeat from step #4 to #7 until turns becomes 0 or player solves the word
    def play(words)
      generate_secret_word(words)
      loop do
        store_guessed_letter!(handle_player_guess)
        reduce_turns_by_one
        store_correct_letters!
        store_incorrect_letters!
        display(self)
        return display(@game_over_msg) if game_over?
      end
    end

    # 2. select a word between 5 and 12 characters long randomly for the secret word
    def generate_secret_word(words)
      return unless @secret_word.empty?

      selected_words = words.select { |word| word.length.between?(5, 12) }
      @secret_word = selected_words.sample.split('')
    end

    private

    # 4. allow the player to make a guess of a letter(case insensitive) for each turn
    def handle_player_guess
      guessed_letter = ''
      loop do
        # 8. let the player to save at the start of any turn
        handle_save
        print 'Guess a letter: '
        guessed_letter = gets.chomp.downcase
        return guessed_letter if guessed_letter.length == 1 && guessed_letter.match?(/[a-z]/i)
      end
    end

    def store_guessed_letter!(letter)
      @guessed_letters << letter
    end

    def reduce_turns_by_one
      @turns -= 1
    end

    # 5. display correct letters and their position in the word
    def store_correct_letters!
      @correct_letters = @secret_word.map { |letter| @guessed_letters.any?(letter) ? letter : '_' }
    end

    # 6. display incorrect letters that have already been chosen
    def store_incorrect_letters!
      @incorrect_letters = @guessed_letters.select { |letter| @correct_letters.none?(letter) }
    end

    def game_over?
      if @correct_letters.eql? @secret_word
        @game_over_msg = 'you win'
        true
      elsif @turns.zero?
        @game_over_msg = 'you lose'
        true
      else
        false
      end
    end

    def handle_save
      display('Would you like to save the game? (Enter "y" to save or press "Enter" to skip.) ')
      return unless gets.chomp.downcase == 'y'

      display('Saving game...')
      save(to_yaml)
    end

    # ask the player to start a new game or load the existing game
    def choose_game
      options = { '1' => 'new game', '2' => 'load game' }
      msg = options.map { |k, v| "#{k}. #{v.capitalize}" }.join("\n")
      print "#{msg}\nChoose an option (1 or 2): "
      options[gets.chomp]
    end

    def display(message)
      puts message
    end

    def to_s
      %(
        In Game:
          secret word: #{@secret_word.join}
          turns left: #{@turns}
          guessed letters: #{@guessed_letters.join(' ')}
          correct letters: #{@correct_letters.join(' ')}
          incorrect letters: #{@incorrect_letters.join(' ')}
      )
    end
  end
end

Hangman.setup
