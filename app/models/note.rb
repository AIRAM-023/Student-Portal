# app/models/note.rb
class Note < ApplicationRecord
    def generate_summary
      return if content.blank?
      
      openai = OpenaiService.new
      self.summary = openai.generate_summary(content)
    end
  end