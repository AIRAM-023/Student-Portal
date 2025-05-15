

class AiController < ApplicationController
  include HTTParty
  base_uri 'https://openrouter.ai/api/v1/chat/completions'

  def chat
    # Replace 'YOUR_API_KEY' with the actual OpenRouter API key you obtained
    api_key = 'YOUR_API_KEY' 

    # Set headers for authentication and content type
    headers = {
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json',
      'HTTP-Referer' => 'http://localhost'
    }

    # Prepare the body with the user's message
    body = {
      model: "openai/gpt-3.5-turbo",  # or use other models as per your choice
      messages: [
        { role: "user", content: "Say Hello!" }
      ]
    }.to_json

    # Make the POST request to OpenRouter's API
    response = self.class.post('', body: body, headers: headers)

    if response.success?
      # Parse and display the response content
      @response_message = response.parsed_response["choices"][0]["message"]["content"]
    else
      # Handle error if the request fails
      @response_message = "Error: #{response.message}"
    end
  end
end


