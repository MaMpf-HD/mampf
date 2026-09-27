# Every lecture gets the date its hand-ins are deleted on: the latest of its
# sheets' deletion dates, else its term's end plus 15 days, and never later
# than the active term allows. Worked out here in SQL and dates rather than
# through Assignment, Lecture and Term: those change, this runs once and
# must still do the same on a fresh database years on.
class AddSubmissionDeletionDateToLectures < ActiveRecord::Migration[8.0]
  def up
    add_column :lectures, :submission_deletion_date, :date

    execute <<~SQL.squish
      UPDATE lectures
      SET submission_deletion_date = latest.deletion_date
      FROM (SELECT lecture_id, MAX(deletion_date) AS deletion_date
            FROM assignments GROUP BY lecture_id) AS latest
      WHERE latest.lecture_id = lectures.id
    SQL

    active = select_one("SELECT year, season FROM terms WHERE active = TRUE LIMIT 1")
    active_end = active && term_end(active["year"], active["season"])
    fallback = (active_end || (Time.zone.today + 180.days)) + 15.days

    select_rows(<<~SQL.squish).each do |id, term_id, year, season|
      SELECT lectures.id, terms.id, terms.year, terms.season
      FROM lectures LEFT JOIN terms ON terms.id = lectures.term_id
      WHERE lectures.submission_deletion_date IS NULL
    SQL
      date = term_id ? term_end(year, season) + 15.days : fallback
      execute("UPDATE lectures SET submission_deletion_date = #{quote(date)} WHERE id = #{id}")
    end

    cap = active_end ? active_end + 2.weeks + 4.months + 1.day : Time.zone.today + 6.months
    execute(<<~SQL.squish)
      UPDATE lectures SET submission_deletion_date = #{quote(cap)}
      WHERE submission_deletion_date > #{quote(cap)}
    SQL

    change_column_null :lectures, :submission_deletion_date, false
    add_index :lectures, :submission_deletion_date
  end

  def down
    remove_index :lectures, :submission_deletion_date, if_exists: true
    remove_column :lectures, :submission_deletion_date
  end

  private

    # A summer term ends on September 30, any other on March 31 of the next
    # year. A term without a year is broken data and raises.
    def term_end(year, season)
      season == "SS" ? Date.new(year, 9, 30) : Date.new(year + 1, 3, 31)
    end
end
