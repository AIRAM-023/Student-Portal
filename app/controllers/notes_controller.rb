# app/controllers/notes_controller.rb
class NotesController < ApplicationController
    def summarize
      @note = Note.find(params[:id])
      @note.generate_summary
      if @note.save
        redirect_to @note, notice: "Summary generated successfully!"
      else
        redirect_to @note, alert: "Failed to generate summary."
      end
    end
  end








