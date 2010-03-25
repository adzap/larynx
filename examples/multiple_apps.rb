class Login < Larynx::Form
  setup do
    @user_id = '1234'
    @pin = '4321'
    @attempts = 0
  end

	field(:enter_id, :attempts => 3, :length => 4) do
		prompt :speak => 'Please enter your 4 digit user ID.', :bargein => true

    success do
      next_field
    end

		failure do
			speak "You have been unable to enter your user ID. Goodbye."
			hangup
		end
	end

	field(:enter_pin, :attempts => 3, :length => 4) do
		prompt :speak => 'Now enter your 4 digit pin.', :bargein => true

    success do
      if valid_credentials?
        speak "Credentials accepted."
        Party.run(call)
      else
        failed_login
      end
    end

    failure do
      speak "You have been unable to enter your pin. Goodbye."
      hangup
    end
  end

  def valid_credentials?
    enter_id == @user_id && enter_pin == @pin
  end

  def failed_login
    @attempts += 1
    if @attempts < 3
      speak "Those credentials are invalid. Try again."
      next_field :enter_id
    else
      speak "You have been able to login. Goodbye."
      hangup
    end
  end
end

class Party < Larynx::Application
  def run
    speak 'Time to party!'
    speak 'But all on your own. Goodbye.'
    hangup
  end
end

Larynx.answer {|call| Login.run(call) }
