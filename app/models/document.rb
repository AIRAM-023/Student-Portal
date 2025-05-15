# app/models/document.rb
class Document < ApplicationRecord
  has_one_attached :file

  validates :file, presence: true, unless: -> { content.present? }
  validate :acceptable_file_type, if: -> { file.attached? }

  # ✅ Make this method public so the controller can call it
  def file_attached_and_valid?
    file.attached? && file.blob.present? && file.blob.persisted?
  end

  private

  def acceptable_file_type
    return unless file.attached?

    acceptable_types = [
      "application/pdf",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document", # .docx
      "application/msword", # .doc
      "text/plain",
      "text/csv",
      "application/rtf",
      "application/vnd.oasis.opendocument.text",
      "text/markdown",
      "application/octet-stream"
    ]

    detected_type = file.content_type || infer_content_type_from_filename

    unless acceptable_types.include?(detected_type)
      errors.add(:file, "must be a PDF, DOCX, DOC, TXT, or other supported document format")
    end
  end

  def infer_content_type_from_filename
    return nil unless file.attached? && file.filename.present?

    extension = File.extname(file.filename.to_s).downcase
    case extension
    when '.pdf'
      'application/pdf'
    when '.docx'
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when '.doc'
      'application/msword'
    when '.txt'
      'text/plain'
    when '.csv'
      'text/csv'
    when '.rtf'
      'application/rtf'
    when '.odt'
      'application/vnd.oasis.opendocument.text'
    when '.md'
      'text/markdown'
    else
      'application/octet-stream'
    end
  end
end
