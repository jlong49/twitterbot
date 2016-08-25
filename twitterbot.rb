require 'twitter'
require 'marky_markov'

markov = MarkyMarkov::TemporaryDictionary.new

# All of the imformation below comes from twitter's
# API. You'll obviously need to enable write

client = Twitter::REST::Client.new do |config|
	config.consumer_key        = "YOU CONSUMER KEY"
	config.consumer_secret     = "YOUR CONSUMER SECRET"
	config.access_token        = "YOUR ACCESS TOKEN"
	config.access_token_secret = "YOUR ACCESS TOKEN SECRET" 
end
pwd = Dir.pwd

def syllableCount(word)
	word.downcase!
	return 1 if word.length <= 3
	word.sub!(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, '')
	word.sub!(/^y/, '')
	return word.scan(/[aeiouy]{1,2}/).size
end

def haikuGen(tweetout)
	haiku = ""
	total = 0
	check = 0
	tweetout.split(" ").each do |word|
		haiku << "#{word} "
		total += syllableCount(word)
		if total == 7
			haiku << "\n"
			check += 1
		end
		if total == 12
			check += 1;
			haiku << "\n"
		end
		if total == 19 && check == 2
			haiku << "\n"
			return haiku
		end
	end
	return 0
end

def collect_with_max_id(collection=[], max_id=nil, &block)
	response = yield(max_id)
	collection += response
	response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
end

def client.get_all_tweets(user)
	collect_with_max_id do |max_id|
		options = {count: 200, include_rts: false}
		options[:max_id] = max_id unless max_id.nil?
		user_timeline(user, options)
	end
end
user = "USERNAME TO BUILD DICTIONARY"

client.get_all_tweets(user).each do |tweet|
	# Removing any mentions of other people or links 
	markov.parse_string tweet.text.gsub /(http.*?( |$))|(@.*?( |$))/, ''
end

if(ARGV[0] != '-h')
	tweetout = markov.generate_1_sentences
	while tweetout.length > 140
		tweetout = markov.generate_1_sentences
	end
end
if(ARGV[0] == '-h')
	tweetout = haikuGen(markov.generate_1_sentences)
	while tweetout == 0 || tweetout.length > 140
		tweetout = haikuGen(markov.generate_1_sentences)
	end
end

puts("#{tweetout} \n'y' to post this, anything else to not")
answer = STDIN.gets.chomp
if answer != "y"
	exit
end
client.update("#{tweetout}")

puts "Posted!"

markov.clear!
		
exit

