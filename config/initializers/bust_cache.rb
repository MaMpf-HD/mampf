# This is used to prevent problems described in
# https://ninjasandrobots.com/rails-caching-a-problem-with-etags-and-a-solution
# see also https://brandonhilkert.com/blog/understanding-the-rails-cache-id-environment-variable/
# Upon deployment, Rails cache gets busted
ENV["RAILS_CACHE_ID"] = Time.now.to_s
