# app/services/open_ai_service.rb
class OpenAiService
  include HTTParty
  base_uri 'https://api.openai.com/v1'

  def initialize
    @headers = {
  "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}",
  "Content-Type" => "application/json"
}

  end

  def generate_response(prompt)
    body = {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: prompt }]
    }
  
    response = self.class.post("/chat/completions", headers: @headers, body: body.to_json)
  
    if response.code == 200
      parsed_response = JSON.parse(response.body)
      return parsed_response["choices"][0]["message"]["content"]
    else
      return "Error: #{response.code} - #{response.body}"
    end
  end
end  