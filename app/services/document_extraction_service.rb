class DocumentExtractionService
    def self.extract_text(attachment)
      # Detailed validation of attachment
      validate_attachment(attachment)
      
      # Extract based on content type
      case attachment.content_type
      when "application/pdf"
        extract_from_pdf(attachment)
      when "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        extract_from_docx(attachment)
      when "text/plain"
        extract_from_text(attachment)
      else
        "File type not supported for text extraction: #{attachment.content_type}"
      end
    end
    
    private
    
    def self.validate_attachment(attachment)
      raise ArgumentError, "No attachment provided" unless attachment.present?
      
      # Check attachment has a blob
      unless attachment.blob.present?
        Rails.logger.error("Attachment has no blob")
        raise ActiveStorage::FileNotFoundError, "Blob not found"
      end
      
      # Check blob is persisted
      unless attachment.blob.persisted?
        Rails.logger.error("Blob is not persisted in database")
        raise ActiveStorage::FileNotFoundError, "Blob not properly saved"
      end
      
      # Check service exists
      unless attachment.blob.service.present?
        Rails.logger.error("Blob service is missing")
        raise ActiveStorage::FileNotFoundError, "Storage service not configured"
      end
      
      # Check file exists in storage
      unless attachment.blob.service.exist?(attachment.blob.key)
        Rails.logger.error("File not found in storage at key: #{attachment.blob.key}")
        raise ActiveStorage::FileNotFoundError, "Physical file not found in storage"
      end
      
      Rails.logger.info("Attachment validation passed")
    end
    
    def self.extract_from_pdf(attachment)
      require 'pdf-reader'
      
      text = ""
      download_to_tempfile(attachment, '.pdf') do |temp_file|
        reader = PDF::Reader.new(temp_file.path)
        reader.pages.each do |page|
          text << page.text
        end
      end
      
      text
    rescue => e
      Rails.logger.error("PDF extraction error: #{e.message}")
      "Error extracting PDF content: #{e.message}"
    end
    
    def self.extract_from_docx(attachment)
      require 'docx'
      
      text = ""
      download_to_tempfile(attachment, '.docx') do |temp_file|
        begin
          doc = Docx::Document.open(temp_file.path)
          text = doc.paragraphs.map(&:text).join("\n")
        rescue => e
          Rails.logger.error("DOCX parsing error: #{e.message}")
          # Fallback to basic text extraction
          text = basic_text_extraction(temp_file.path)
        end
      end
      
      text
    rescue => e
      Rails.logger.error("DOCX extraction error: #{e.message}")
      "Error extracting DOCX content: #{e.message}"
    end
    
    def self.extract_from_text(attachment)
      text = ""
      download_to_tempfile(attachment, '.txt') do |temp_file|
        text = File.read(temp_file.path)
      end
      
      text
    rescue => e
      Rails.logger.error("Text extraction error: #{e.message}")
      "Error extracting text content: #{e.message}"
    end
    
    def self.download_to_tempfile(attachment, extension)
      temp_file = Tempfile.new(['document', extension])
      temp_file.binmode
      
      begin
        # Download using the blob's service directly
        attachment.blob.download do |chunk|
          temp_file.write(chunk)
        end
        
        temp_file.flush
        temp_file.rewind
        
        # Verify file was downloaded
        if File.size(temp_file.path) == 0
          raise "Downloaded file is empty"
        end
        
        # Pass the tempfile to the block
        yield(temp_file)
      ensure
        # Clean up
        temp_file.close
        temp_file.unlink if File.exist?(temp_file.path)
      end
    end
    
    def self.basic_text_extraction(file_path)
      # Simple text extraction for when docx gem fails
      content = File.read(file_path)
      
      # Try to extract readable text from binary content
      if content.encoding.name == "ASCII-8BIT"
        content.force_encoding("UTF-8")
        content = content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "�")
      end
      
      # Extract text-like content
      text_chunks = content.scan(/[\p{L}\p{N}\p{P}\p{Z}]{4,}/)
      text_chunks.join(" ")
    end
  end