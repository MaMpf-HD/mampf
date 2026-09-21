class AddTranscriptDataToMedia < ActiveRecord::Migration[8.0]
  def change
    add_column :media, :transcript_data, :text
    add_column :media, :transcription_status, :integer, default: 0, null: false
    add_column :media, :transcription_attempts, :integer, default: 0, null: false
    add_column :media, :transcription_requested_at, :datetime
    add_column :media, :transcription_error, :text

    add_index :media, [:transcription_status, :transcription_requested_at],
              where: "transcription_status IN (0, 1, 3) AND video_data IS NOT NULL",
              name: "index_media_on_pending_transcriptions"
  end
end
