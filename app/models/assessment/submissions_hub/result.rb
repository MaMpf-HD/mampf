module Assessment
  module SubmissionsHub
    # What one call to the loader hands back. Two of these point opposite ways:
    # `invitations` are the ones the reader has been sent, `invited_users` the
    # people they have invited to their own hand-in.
    Result = Struct.new(:sheets, :standing, :open_sheets, :due, :latest_marked,
                        :invitations, :possible_partners, :invited_users, :next_scheduled,
                        keyword_init: true) do
      def invitations_for(assignment)
        invitations.fetch(assignment.id, [])
      end

      def invitable_partners(submission)
        possible_partners - submission.users.to_a
      end

      def invited_users_for(submission)
        return [] unless submission

        invited_users.fetch(submission.id, [])
      end
    end
  end
end
