# encoding: utf-8

# Helper to generate a table defined columnwise, so that
# column headers are defined next to its values.
#
# Example:
#
#     table_by_columns(records) do
#       table_column('Name') { |record| record.name }
#       table_column('Date') { |record| record.date }
#     end
#
# Example:
#
#     table_by_columns(collection) do
#       columns.each do |column| # (*) Note: don't use 'for' here!
#         table_column column_header_for(column) do |record|
#           field_value_for(record, column)
#         end
#       end
#     end
#
# (*) With a 'for column in columns' loop, the 'column' variable
# which is captured by the inner block would have always the last value
# because the inner block is evaluated after the iteration ends.
#
# With the :nested_grouping, column value groups (of rows) don't cross
# boundaries of preceding column groups.
#
module TableListingHelper

  def table_by_columns(records, *cls, &blk)
    raise "Tables cannot be nested" unless @table_listing_columns.nil?
    options = cls.extract_options!
    @table_listing_columns = []
    @table_grouping = nil
    @table_after_row = nil
    @table_group_class = nil
    blk.call
    columns = @table_listing_columns
    @table_listing_columns = nil
    nested_grouping = options[:nested_grouping]
    if columns.present?
      column_grouping = columns.any? { |h, v, options, row_count| row_count }
      content_tag :table, class: cls do
        concat_content_tag :thead do
          concat_content_tag :tr do
            columns.each do |header, value_method, options, row_count|
              thcls = options[:class] || options[:th_class]
              concat_content_tag :th, header, class: Array(thcls).join(' ')
            end
          end
        end
        concat_content_tag :tbody do
          first_group = true
          group_header = nil
          base_nested_max_num = nil
          records = LookAheadIterator.new(records, stop: true) if column_grouping
          records.each do |record|
            if @table_grouping
              group = @table_grouping[record]
              if column_grouping && (group != group_header || first_group)
                # Avoid crossing group headers with rowspan grouping
                base_nested_max_num = 1
                loop do
                  other_record = records.look_ahead(base_nested_max_num)
                  if !other_record || @table_grouping[other_record] != group
                    break
                  end
                  base_nested_max_num += 1
                end
              end
              if group != group_header # || first_group ?
                group_header = group
                concat_content_tag :tr, class: @table_group_class do
                  concat_content_tag :th, group_header, colspan: columns.size
                end
                # TODO: optionally repeat table header (except if this is the first row after the header)
              end
              first_group = false
            end
            concat_content_tag :tr do
              nested_max_num = base_nested_max_num
              columns.each do |column|
                header, value_method, options, num = column
                value = value_method[record]
                tdcls = options[:class] || options[:td_class]
                if num.nil?
                  concat_content_tag :td, value, class: Array(tdcls).join(' ')
                else
                  # grouping column
                  num -= 1
                  if num == 0
                    loop do
                      num += 1
                      other_record = records.look_ahead(num)
                      other_value = other_record && value_method[other_record]
                      break if !other_value || other_value != value
                    end
                    num = [num, nested_max_num].min if nested_max_num
                    concat_content_tag :td, value, rowspan: num, class: Array(tdcls).join(' ')
                  end
                  column[3] = num
                  nested_max_num = [nested_max_num || num, num].min if nested_grouping
                end
              end
            end
            base_nested_max_num -= 1 if base_nested_max_num
            if @table_after_row
              concat capture(record, num_cols: columns.size, &@table_after_row)
            end
          end
        end
      end
    end
  end

  # Passing the option +grouping: true+ to a column
  # causes its rows to be grouped (with colspan).
  def table_column(header, options = {}, &blk)
    raise "table_column out of table_by_columns block" if @table_listing_columns.nil?
    row_count = options[:grouping] ? 1 : nil
    @table_listing_columns << [header, blk, options, row_count]
  end

  # This can be used inside a table listing to define a grouping of rows:
  # a block that receives records must be passed returning its group header
  def table_header_grouping(*cls, &blk)
    raise "table_grouping out of table_by_columns block" if @table_listing_columns.nil?
    @table_group_class = cls*' '
    @table_grouping = blk
  end

  # This can be used to add contents after each row
  #
  #     <%= table_by_columns((1..10)) do %>
  #       <% table_column('Value') { |value| value }
  #          table_column('Double') { |value| value*2 } %>
  #       <% table_after_row do |value, options| %>
  #         <tr><th colspan="<%= options[:num_cols] %>">Triple: <%= value*3 %><th></tr>
  #       <% end %>
  #     <% end %>
  #
  def table_after_row(&blk)
    raise "table_after_row out of table_by_columns block" if @table_listing_columns.nil?
    @table_after_row = blk
  end

end
