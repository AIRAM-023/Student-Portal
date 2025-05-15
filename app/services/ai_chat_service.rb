require 'faraday'
require 'json'

class AiChatService
  BASE_URL = "https://openrouter.ai/api/v1/chat/completions"
  API_KEY = ENV['OPENROUTER_API_KEY']

  
def self.chat_with_ai(prompt)
  conn = Faraday.new(
    url: "https://openrouter.ai/api/v1/chat/completions",
    headers: {
      'Authorization' => "Bearer #{API_KEY}",
      'Content-Type' => 'application/json'
    }
  )

  response = conn.post do |req|
    req.body = {
      model: "mistral/mistral-7b-instruct",
      messages: [
        { role: "user", content: prompt }
      ]
    }.to_json
  end

  body = JSON.parse(response.body)

  if body["choices"] && body["choices"][0] && body["choices"][0]["message"]
    return body["choices"][0]["message"]["content"].strip
  elsif body["error"]
    return "API Error: #{body["error"]["message"]}"
  else
    return "Error: Unexpected API response structure\n\n#{response.body}"
  end
rescue JSON::ParserError => e
  "Error parsing JSON: #{e.message}"
rescue => e
  "General error: #{e.message}"
end
end



