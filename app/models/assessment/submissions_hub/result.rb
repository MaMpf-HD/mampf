module Assessment
  module SubmissionsHub
    # What one call to the loader hands back: every sheet of the lecture newest
    # first, the exam-admission standing, the sheets that can still be handed in
    # (soonest first), the subset of those sharing the next deadline, the sheet
    # that came back most recently, and what the cards need to offer a team -
    # the invitations the reader has, everybody they could invite, and who has
    # been invited to their own hand-in without joining it yet.
    Result = Struct.new(:sheets, :standing, :open_sheets, :due, :latest_marked,
                        :invites, :possible_partners, :invited, :next_scheduled,
                        keyword_init: true) do
      # The team-ups offered for one sheet, and everybody the reader could invite
      # to it - both read by the card, both fetched once for the whole page.
      def invites_for(assignment)
        invites.fetch(assignment.id, [])
      end

      def invitable_to(submission)
        possible_partners - submission.users.to_a
      end

      def invited_to(submission)
        return [] unless submission

        invited.fetch(submission.id, [])
      end
    end
  end
end
