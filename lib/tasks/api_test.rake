# lib/tasks/api_test.rake
namespace :api do
    desc "Test OpenRouter API connection"
    task test_connection: :environment do
      require 'httparty'
      
      puts "Testing OpenRouter API connection..."
      
      api_key = ENV['OPENROUTER_API_KEY']
      if api_key.blank?
        puts "ERROR: No API key found in ENV['OPENROUTER_API_KEY']"
        puts "Please set your API key in .env file or directly in environment"
        exit 1
      end
      
      puts "API key found: #{api_key[0..5]}...#{api_key[-4..-1]}"
      
      url = "https://openrouter.ai/api/v1/chat/completions"
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{api_key}",
        "HTTP-Referer" => "localhost",
        "X-Title" => "LearnCraft API Test"
      }
      
      body = {
        model: "openai/gpt-3.5-turbo",
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: "Please respond with 'API connection successful' if you can read this message." }
        ],
        max_tokens: 50,
        temperature: 0.7
      }.to_json
      
      begin
        puts "Sending test request to OpenRouter API..."
        response = HTTParty.post(url, headers: headers, body: body, timeout: 30)
        puts "Response status: #{response.code}"
        
        if response.code == 200
          parsed = response.parsed_response
          if parsed && parsed["choices"] && parsed["choices"][0] && parsed["choices"][0]["message"]
            content = parsed["choices"][0]["message"]["content"]
            puts "SUCCESS! API responded with: #{content}"
          else
            puts "ERROR: Unexpected response structure"
            puts parsed.inspect
          end
        else
          puts "ERROR: API returned status #{response.code}"
          puts "Response body: #{response.body}"
        end
      rescue => e
        puts "ERROR: Exception occurred: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
  end
  
  # Run this task with:
  # rails api:test_connection