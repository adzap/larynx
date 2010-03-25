class Guess < Larynx::Form
	field(:guess, :attempts => 3, :length => 1) do
		prompt :speak => 'Guess a number between 1 and 9.', :interdigit_timeout => 6
		reprompt :speak => 'Have another guess.', :interdigit_timeout => 6

		setup do
			@number = rand(9) + 1
			@guesses = 0
		end

		validate do
			@guesses += 1 if guess.size > 0
			@number == guess.to_i
		end

		invalid do
			if guess.size > 0
				speak "No, it's not #{guess}.", :bargein => false
			end
		end

		success do
			speak "You got it! It was #{guess}. It took you #{@guesses} guesses.", :bargein => false
			hangup
		end

		failure do
			speak "Sorry you didn't guess it. It was #{@number}. Try again soon.", :bargein => false
			hangup
		end
	end
end

Larynx.answer {|call| Guess.run(call) }
