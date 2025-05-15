class DocumentsController < ApplicationController
    def new
      @document = Document.new
    end
  
    def create
      @document = Document.new(document_params)
  
      if @document.save
        # Assuming your file is being uploaded as an attachment (e.g., using ActiveStorage)
        file_path = @document.file.path # Or adjust depending on how you're handling file uploads
        file_content = File.read(file_path)
  
        # Generate summary from file content
        summary = generate_summary(file_content)
  
        # Store summary or render it to the user
        render json: { summary: summary }
      else
        render :new
      end
    end
  
    private
  
    def document_params
      params.require(:document).permit(:file)
    end
  
    def generate_summary(text)
      uri = URI('https://openrouter.ai/api/v1/chat/completions')
      api_key = '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'
      
      # Prepare the request body
      request_body = {
        model: 'gpt-3.5-turbo',
        messages: [{
          role: 'user',
          content: "Please summarize the following document: #{text}"
        }]
      }
  
      # Make the API request to OpenRouter
      response = Net::HTTP.post(uri, request_body.to_json, {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      })
  
      # Parse the response
      json_response = JSON.parse(response.body)
  
      # Extract the summary from the response
      json_response['choices'][0]['message']['content']
    end
  end
  