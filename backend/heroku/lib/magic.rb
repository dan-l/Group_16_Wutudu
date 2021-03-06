module Magic
  DATA_VARIABLES = [:distance, :rating, :review_count]
  WEIGHTS = {distance: 0.3, rating: 0.6, review_count: 0.1}
  # DATA_VARIABLES = [:category, :distance, :rating]
  # WEIGHTS = {category: 0.2, distance: 0.3, rating: 0.6}

  class BestLocation
    attr_reader :location, :scores, :data, :categories, :api
    # Params:
    # lat: latitude (Float)
    # long: longitude (Float)
    # cats: categories with decreasing rank (Array)
    #
    # Example:
    # bl = Magic::BestLocation.new(49.283552, -123.119506, ["food", "nightlife", "shopping"])
    def initialize(lat, long, cats, event_date)
      begin
        @event_date = event_date
        @categories = cats
        @sums = {}
        @avgs = {}
        @scores = []
        @api = ThirdPartyAPI::MagicAPI.new(lat, long, cats)
      rescue
        @api = nil
      end
    end

    # Outputs (and saves to @location) the formatted result
    # with the maximum score that is currently open
    #
    # Params:
    # cat: optional category (String)
    #
    # Example:
    # result = bl.find_best_location #Will only produce best location for "food" by default
    # result = bl.find_best_location("nightlife") #Will produce best location for nightlife
    # OR
    # Call bl.location since it stores the result
    def find_best_location(*cat)
      @location = nil
      @best_effort_location = nil
      attempts = 3
      if @api
        cats = (cat.empty? ? @categories.dup : cat.dup)
        until @location || cats.length == 0 || attempts == 0 do
          c = cats.shift
          if @categories.include?(c)
            transform_data(c)
            scores = @scores.dup
            until @location || scores.length == 0 || attempts == 0 do
              max_index = scores.index(scores.max)
              id = @data[:id][max_index]
              name = @data[:name][max_index]
              result = @api.business_summary({
                id: id, name: name, event_date: @event_date
              })
              @best_effort_location = result if @best_effort_location.nil?
              if result[:will_be_open]
                @location = result
              end
              scores.delete_at(max_index)
              attempts -= 1
            end
          end
        end
      end
      @location.nil? ? @best_effort_location : @location
    end

    private

    # Elimnate permanently closed locations
    def eliminate_closed
      @is_closed = @data[:is_closed]
      @data.except!(:is_closed)
      closed_indexes = @is_closed.each_index.select{|i| @is_closed[i]}
      closed_indexes.each do |ci|
        (DATA_VARIABLES | [:id]).each{|v| @data[v].delete_at(ci)}
      end
    end

    # Normalize each sets of data with respect to their means
    def normalize_data
      DATA_VARIABLES.each do |v|
        @sums[v] = @data[v].inject(:+)
        @avgs[v] = @sums[v] / @data[v].length.to_f
        @data[v] = @data[v].map{|d| d / @avgs[v]}
      end
    end

    # Calculate score based on weights
    def calculate_score
      @data[:id].each_index do |i|
        @scores[i] = 0
        distance_key = :distance
        rating_key = :rating
        review_key = :review_count
        # distance score should be weighted more for nearer ones
        distance_score = 1/ @data[distance_key][i]  * WEIGHTS[distance_key]
        rating_score = @data[rating_key][i] * WEIGHTS[rating_key] * @data[review_key][i] ** (1.0/10)
        @scores[i] = distance_score + rating_score
      end
    end

    def transform_data(cat)
      @data = @api.summary[cat].dup
      unless @data.empty?
        eliminate_closed
        normalize_data
        calculate_score
      end
    end
  end
end