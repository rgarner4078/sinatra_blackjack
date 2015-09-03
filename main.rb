require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'mywebappsecret'

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17

helpers do
	def calculate_total(hand)
		arr = hand.map{|element| element[1]}
		total = 0
		arr.each do |card|
			if card == "ace"
				if total + card.to_i <= BLACKJACK_AMOUNT
					total += 11
				else
					total += 1
				end
			else
				total += card.to_i == 0 ? 10 : card.to_i
			end
		end
		return total
	end
  def card_image(card)
    suit = case card[0]
      when 'H' then "hearts"
      when 'C' then "clubs"
      when 'S' then "spades"
      when 'D' then "diamonds"
    end
    value = card[1]
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
end

before do
  @show_buttons = true
  @not_dealers_turn = true
end

get '/' do
	if session[:player_name]
		redirect '/game'
	else
  	redirect '/new_player'
	end
end

get '/new_player' do
	erb :new_player
end

post'/set_name' do
  if params[:player_name].empty?
    @error = "name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
	# build the deck
	suits = ['H', 'D', 'S', 'C']
	values = ['2','3','4','5','6','7','8','9','10','jack','queen','king','ace']
	session[:deck] = suits.product(values).shuffle!
	# deal cards: player, dealer
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == 21
    @success = "#{session[:player_name]} hit blackjack"
    @show_buttons = false    
  end

  erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) > 21
    @error = "#{session[:player_name]} busted"
    @show_buttons = false
  elsif calculate_total(session[:player_cards]) == 21
    @success = "#{session[:player_name]} hit blackjack"
    @show_buttons = false    
  end
	erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} stays"
  @show_buttons = false
	redirect '/game/dealer'
end

get '/game/dealer' do
  @show_buttons = false
  @not_dealers_turn = false
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    @error = "Dealer hit blackjack"
  elsif dealer_total > BLACKJACK_AMOUNT
    @success = "Dealer busted"
  elsif dealer_total >= DEALER_HIT_MIN
    redirect '/game/compare'
  else
    @show_dealer_hit = true
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_buttons = false
  @not_dealers_turn = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    @error = "#{session[:player_name]} loses"
  elsif player_total > dealer_total
    @success = "#{session[:player_name]} wins"
  else
    @success = "Tie"
  end
  erb :game 
end