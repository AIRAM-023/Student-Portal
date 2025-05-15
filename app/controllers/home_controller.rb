class HomeController < ApplicationController
  def index; end
  def about_us; end
  def features; end
  def contact_us; end
  def help; end

 
  def ai_summary_test
    # Sample text to generate summary for
    text = "Artificial Intelligence (AI) is intelligence demonstrated by machines, in contrast to the natural intelligence displayed by humans and animals. Leading AI textbooks define the field as the study of 'intelligent agents': any device that perceives its environment and takes actions that maximize its chance of successfully achieving its goals."

    # Calling AI service to generate summary
    @summary = AiService.generate_summary(text)
  end



  def dashboard
    @user = current_user # Or however you're fetching the user

    @learning_progress = { percentage: 60 } # Replace with dynamic logic later

    @upcoming_tasks = [
      { title: "Complete Ruby Quiz", description: "Based on Chapter 18", due_date: "2025-05-05" },
      { title: "Submit Assignment", description: "AI-generated summary task", due_date: "2025-05-08" }
    ]

    @recommendations = [
      { title: "Review Game-Tree Search", description: "Spend 15 minutes on past MCQs." },
      { title: "Practice Greedy Algorithm", description: "Solve at least 2 Codeforces problems." }
    ]

    @recent_activities = [
      { title: "Finished Simulated Annealing Quiz", date: "2025-05-02", details: "Scored 85%" },
      { title: "Generated Study Plan", date: "2025-05-01", details: "AI suggested focus on Genetic Algorithms" }
    ]
  end
end
