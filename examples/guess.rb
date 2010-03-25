class Guess < Larynx::Application
	def run
		@number = rand(9) + 1
    @guess = ''
		@guesses = 0
		get_guess
	end

	def get_guess
		if @guesses < 3
			speak(guess_prompt) {
				@guesses += 1
			}
		else
			speak "Sorry you didn't guess it. It was #{@number}. Try again soon.", :bargein => false
			hangup
		end
	end

	def check_guess
		if @guess.to_i == @number
			speak "You got it! It was #{@guess}. It took you #{@guesses} guesses.", :bargein => false
			speak "Thanks for playing."
			hangup
		else
			speak "No it's not #{@guess}."
			get_guess
		end
	end

  def guess_prompt
    @guesses == 0 ? 'Guess a number between 1 and 9.' : 'Have another guess.'
  end

	def dtmf_received(input)
		@guess = input
		check_guess
	end
end

Larynx.answer {|call| Guess.run(call) }
