# app/controllers/ai_controller.rb
class AiController < ApplicationController
  def ask
    prompt = params[:prompt]
    response = OpenrouterService.ask_ai(prompt)
    render json: { response: response }
  end
end
