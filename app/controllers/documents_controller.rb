class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :download_summary]
  around_action :debug_document_actions, only: [:create, :show]

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if params[:document] && params[:document][:file].present?
      @document.file.attach(params[:document][:file])

      if @document.save
        Rails.logger.info("Document saved with ID: #{@document.id}")
        @document.reload

        if @document.file_attached_and_valid?
          begin
            raw_content = DocumentExtractionService.extract_text(@document.file)

            if raw_content.present?
              summary = generate_summary(raw_content)
              @document.update(content: summary)
            end

            redirect_to @document, notice: "Document was successfully processed."
            return
          rescue => e
            Rails.logger.error("Text extraction error: #{e.message}")
            @document.update(content: "Error extracting content: #{e.message}")
            redirect_to @document, alert: "Document saved but text extraction failed."
            return
          end
        else
          Rails.logger.error("File not properly attached after save")
          @document.update(content: "Error: File attachment issue after save.")
          redirect_to @document, alert: "Document saved but file appears to be invalid."
          return
        end
      else
        Rails.logger.error("Document save failed: #{@document.errors.full_messages.join(', ')}")
      end
    else
      @document.errors.add(:file, "is required")
    end

    render :new, status: :unprocessable_entity
  end

  def show
    Rails.logger.info("DEBUG: Showing document ID #{@document.id}")
    Rails.logger.info("DEBUG: Document content present? #{@document.content.present?}")
  end

  def download_summary
    Rails.logger.info("DEBUG: Downloading summary for document ID #{@document.id}")
    summary = @document.content || "No content available"

    respond_to do |format|
      format.txt do
        send_data summary, filename: "summary-#{@document.id}.txt", type: "text/plain", disposition: "attachment"
      end
      format.docx do
        file_path = generate_docx_file(summary)
        send_file file_path,
                  filename: "summary-#{@document.id}.docx",
                  type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                  disposition: "attachment"
      end
    end
  rescue => e
    Rails.logger.error("DEBUG: Download error: #{e.message}")
    redirect_to @document, alert: "Error generating download: #{e.message}"
  end

  private

  def debug_document_actions
    Rails.logger.info("====== Starting #{params[:action]} action ======")
    yield
    Rails.logger.info("====== Completed #{params[:action]} action ======")
  end

  def set_document
    @document = Document.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("DEBUG: Document not found: #{e.message}")
    redirect_to root_path, alert: "Document not found"
  end

  def document_params
    params.require(:document).permit(:content, :file)
  rescue => e
    Rails.logger.error("DEBUG: Parameter error: #{e.message}")
    {}
  end

  def generate_summary(content)
    api_key = ENV['OPENROUTER_API_KEY']
    return "No content was provided for summarization." if content.blank?
    return "Summary could not be generated - API key is missing." if api_key.blank?

    require 'httparty'

    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{api_key}",
      "HTTP-Referer" => ENV['APPLICATION_HOST'] || "https://yourapplication.com",
      "X-Title" => "Document Summarizer"
    }

    content = content[0...15000] + "...[truncated]" if content.length > 15000

    body = {
      model: "openai/gpt-3.5-turbo",
      messages: [
        { role: "system", content: "You are a helpful assistant that summarizes educational content." },
        { role: "user", content: "Please summarize:\n\n#{content}" }
      ],
      max_tokens: 1000,
      temperature: 0.7
    }.to_json

    begin
      response = HTTParty.post(url, headers: headers, body: body, timeout: 30)

      if response.code == 200
        parsed = response.parsed_response
        parsed.dig("choices", 0, "message", "content") || "Summary generation failed: No content returned."
      else
        "Summary generation failed: API returned status #{response.code}.\n\n#{response.body}"
      end
    rescue => e
      Rails.logger.error("DEBUG: API error: #{e.message}")
      "Summary generation failed: #{e.message}"
    end
  end

  def generate_docx_file(summary)
    require 'docx'

    temp_dir = Rails.root.join("tmp")
    FileUtils.mkdir_p(temp_dir) unless File.directory?(temp_dir)

    file_path = temp_dir.join("summary-#{SecureRandom.hex}.docx")

    begin
      if defined?(Docx)
        doc = Docx::Document.create(file_path.to_s)
        doc.paragraphs.first.text = summary
        doc.save(file_path.to_s)
      else
        File.open(file_path, "wb") { |f| f.write(summary) }
      end

      Rails.logger.info("DEBUG: DOCX file created at #{file_path}")
      file_path
    rescue => e
      Rails.logger.error("DEBUG: DOCX generation error: #{e.message}")
      File.open(file_path, "w") { |f| f.write(summary) }
      file_path
    end
  end
end
