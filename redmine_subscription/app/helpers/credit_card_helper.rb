# CreditCardHelper
#
# Helper for Credit Card

module CreditCardHelper
  # XOR two strings
  def xor_strings(str_one, str_two)
    s1 = str_one.unpack("c*")
    s2 = str_two.unpack("c*")

    s2 *= 2 while s2.length < s1.length

    s1.zip(s2).collect{|c1,c2| c1^c2}.pack("c*")
  end

  # Decode value
  def decode_value(data_value)
    salt = 'BGuxLWQtKweKEMVz';
    length_string = data_value.length
    @settings = SettingSubscription.find(:first)
    seq = @settings.keypass
    gamma = ""

    while gamma.length < length_string
      seq = Digest::SHA1.hexdigest(seq + gamma + salt).to_a.pack("H*")
      gamma += seq[0, 8]
    end

    data_value = Base64.decode64(data_value)
    data_value = xor_strings(data_value, gamma)

    decoded_string = data_value[1, data_value.length].to_s.strip
    error_decode = xor_strings(data_value[0, 1], Digest::SHA1.hexdigest(decoded_string).to_a.pack("H*").to_s[0, 1])[0]

    error_decode = false if error_decode == 0

    if error_decode
      ""
    else
      decoded_string
    end
  end

  # Encode value
  def encode_value(data_value)
    salt = 'BGuxLWQtKweKEMVz';
    encode_string = Digest::SHA1.hexdigest(data_value).to_a.pack("H*")[0, 1] + data_value
    length_string = encode_string.length
    @settings = SettingSubscription.find(:first)
    seq = @settings.keypass
    gamma = ""

    while gamma.length < length_string
      seq = Digest::SHA1.hexdigest(seq + gamma + salt).to_a.pack("H*")
      gamma += seq[0, 8]
    end

    Base64.encode64(xor_strings(encode_string, gamma))
  end

  # Get a user message by response_code
  def get_user_message(response_code, response_reason_code)
    if response_code == 3 && response_reason_code == 8
      "The credit card has expired."
    elsif response_code == 2 && response_reason_code == 317
      "The credit card has expired."
    else
      "The credit card has been declined."
    end
  end
end