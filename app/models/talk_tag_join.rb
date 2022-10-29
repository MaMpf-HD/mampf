class TalkTagJoin < ApplicationRecord
  belongs_to :talk
  belongs_to :tag
end
